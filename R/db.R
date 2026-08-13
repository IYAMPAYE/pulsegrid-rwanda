# Supabase (Postgres) connection pool and ticket queries
# SETUP: SUPABASE_DB_PASSWORD in .Renviron (see app.r header)

DB_HOST     <- "aws-1-eu-west-1.pooler.supabase.com"
DB_PORT     <- 5432
DB_NAME     <- "postgres"
DB_USER     <- "postgres.cjybmjsaqlhxfiytsjuj"
DB_PASSWORD <- Sys.getenv("SUPABASE_DB_PASSWORD")

USE_DB_POOL <- requireNamespace("pool", quietly = TRUE)
if (USE_DB_POOL) {
  suppressPackageStartupMessages(library(pool))
}
db_pool <- NULL

db_connect_args <- function() {
  list(
    drv      = RPostgres::Postgres(),
    host     = DB_HOST,
    port     = DB_PORT,
    dbname   = DB_NAME,
    user     = DB_USER,
    password = DB_PASSWORD,
    sslmode  = "require"
  )
}

init_db_pool <- function() {
  if (!USE_DB_POOL || !nzchar(DB_PASSWORD)) return(invisible(NULL))
  if (!is.null(db_pool) && pool::dbIsValid(db_pool)) return(invisible(db_pool))

  db_pool <<- do.call(
    pool::dbPool,
    c(db_connect_args(), list(minSize = 2, maxSize = 8))
  )
  invisible(db_pool)
}

close_db_pool <- function() {
  if (!is.null(db_pool)) {
    tryCatch(pool::poolClose(db_pool), error = function(e) NULL)
    db_pool <<- NULL
  }
}

checkout_db <- function() {
  if (USE_DB_POOL) {
    init_db_pool()
    if (!is.null(db_pool)) return(pool::poolCheckout(db_pool))
  }
  do.call(DBI::dbConnect, db_connect_args())
}

release_db <- function(con) {
  if (USE_DB_POOL && !is.null(db_pool)) {
    pool::poolReturn(con)
  } else if (DBI::dbIsValid(con)) {
    DBI::dbDisconnect(con)
  }
}

with_db <- function(expr) {
  con <- checkout_db()
  on.exit(release_db(con), add = TRUE)
  eval(substitute(expr), envir = list(con = con), enclos = parent.frame())
}

warm_db_pool <- function() {
  if (!nzchar(DB_PASSWORD)) return(invisible(NULL))
  tryCatch(
    with_db({
      dbGetQuery(con, "SELECT 1 AS ok")
      invisible(NULL)
    }),
    error = function(e) invisible(NULL)
  )
  invisible(NULL)
}

schedule_db_warm <- function() {
  if (requireNamespace("later", quietly = TRUE)) {
    later::later(warm_db_pool, delay = 0)
  } else {
    warm_db_pool()
  }
  invisible(NULL)
}

if (USE_DB_POOL) {
  shiny::onStop(close_db_pool)
}

load_tickets <- function() {
  with_db({
    data <- dbGetQuery(con, "select * from tickets order by created_at desc")
    data %>%
      mutate(
        urgency    = factor(urgency, levels = c("Low", "Medium", "High")),
        created_at = as.Date(created_at)
      )
  })
}

load_technicians <- function() {
  with_db({
    rows <- tryCatch(
      dbGetQuery(
        con,
        "select t.id, t.name, t.email, t.phone, t.last_login, t.must_change_password,
                t.assigned_region, t.active,
                tr.region as routing_region
         from technicians t
         left join technician_regions tr on tr.technician_id = t.id
         order by t.name, tr.region"
      ),
      error = function(e) {
        message("load_technicians fallback: ", conditionMessage(e))
        dbGetQuery(
          con,
          "select id, name, email, phone, last_login, must_change_password
           from technicians
           order by name"
        )
      }
    )
    if (!"assigned_region" %in% names(rows)) rows$assigned_region <- NA_character_
    if (!"active" %in% names(rows)) rows$active <- TRUE
    if (!"routing_region" %in% names(rows)) rows$routing_region <- NA_character_
    rows
  })
}

load_active_technicians <- function() {
  with_db(
    dbGetQuery(
      con,
      "select t.id, t.name, t.email, t.phone, t.assigned_region, tr.region as routing_region
       from technicians t
       left join technician_regions tr on tr.technician_id = t.id
       where t.active = true
       order by t.name"
    )
  )
}

normalize_region_key <- function(region) {
  tools::toTitleCase(tolower(trimws(as.character(region))))
}

sync_technician_region <- function(con, technician_id, region) {
  region <- normalize_region_key(region)
  DBI::dbExecute(con, "delete from technician_regions where region = $1", params = list(region))
  DBI::dbExecute(con, "delete from technician_regions where technician_id = $1", params = list(technician_id))
  DBI::dbExecute(
    con,
    "insert into technician_regions (technician_id, region) values ($1, $2)",
    params = list(technician_id, region)
  )
  DBI::dbExecute(
    con,
    "update technicians set assigned_region = $1 where id = $2",
    params = list(region, technician_id)
  )
}

create_technician <- function(name, email, phone, region, password) {
  name <- trimws(as.character(name))
  email <- trimws(as.character(email))
  phone <- trimws(as.character(phone))
  region <- normalize_region_key(region)
  if (!nzchar(name) || !nzchar(email) || !nzchar(password)) {
    stop("Name, email, and password are required.")
  }

  with_db({
    existing <- DBI::dbGetQuery(
      con,
      "select id from technicians where lower(email) = lower($1)",
      params = list(email)
    )
    if (nrow(existing) > 0) stop("A technician with this email already exists.")

    hash <- bcrypt::hashpw(password)
    row <- DBI::dbGetQuery(
      con,
      "insert into technicians (name, email, phone, password_hash, must_change_password, assigned_region, active)
       values ($1, $2, nullif($3, ''), $4, true, $5, true)
       returning id",
      params = list(name, email, phone, hash, region)
    )
    tid <- row$id[[1]]
    sync_technician_region(con, tid, region)
    tid
  })
}

update_technician_admin <- function(id, name, email, phone, region, active) {
  name <- trimws(as.character(name))
  email <- trimws(as.character(email))
  phone <- trimws(as.character(phone))
  region <- normalize_region_key(region)
  if (!nzchar(name) || !nzchar(email)) stop("Name and email are required.")

  with_db({
    old <- DBI::dbGetQuery(con, "select email from technicians where id = $1", params = list(id))
    if (nrow(old) == 0) stop("Technician not found.")
    old_email <- old$email[[1]]

    dup <- DBI::dbGetQuery(
      con,
      "select id from technicians where lower(email) = lower($1) and id <> $2",
      params = list(email, id)
    )
    if (nrow(dup) > 0) stop("Another technician already uses this email.")

    DBI::dbExecute(
      con,
      "update technicians
       set name = $1, email = $2, phone = nullif($3, ''), assigned_region = $4, active = $5
       where id = $6",
      params = list(name, email, phone, region, isTRUE(active), id)
    )
    sync_technician_region(con, id, region)

    if (!identical(tolower(old_email), tolower(email))) {
      DBI::dbExecute(
        con,
        "update tickets set technician_email = $1, technician = $2 where lower(technician_email) = lower($3)",
        params = list(email, name, old_email)
      )
    } else {
      DBI::dbExecute(
        con,
        "update tickets set technician = $1 where lower(technician_email) = lower($2)",
        params = list(name, email)
      )
    }
  })
}

admin_reset_technician_password <- function(id, password) {
  if (!nzchar(password)) stop("Password is required.")
  with_db({
    hash <- bcrypt::hashpw(password)
    DBI::dbExecute(
      con,
      "update technicians set password_hash = $1, must_change_password = true where id = $2",
      params = list(hash, id)
    )
  })
}

set_technician_active <- function(id, active) {
  with_db(
    DBI::dbExecute(
      con,
      "update technicians set active = $1 where id = $2",
      params = list(isTRUE(active), id)
    )
  )
}

technician_is_active <- function(technician_id) {
  with_db({
    row <- DBI::dbGetQuery(
      con,
      "select coalesce(active, true) as active from technicians where id = $1",
      params = list(technician_id)
    )
    if (nrow(row) == 0) return(FALSE)
    isTRUE(row$active[[1]])
  })
}

reassign_ticket <- function(ticket_id, technician_name, technician_email) {
  with_db(
    DBI::dbExecute(
      con,
      "update tickets set technician = $1, technician_email = $2 where ticket_id = $3",
      params = list(technician_name, technician_email, as.character(ticket_id))
    )
  )
}
