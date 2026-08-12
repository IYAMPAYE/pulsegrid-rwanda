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
    c(db_connect_args(), list(minSize = 1, maxSize = 5))
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
    with_db(dbGetQuery(con, "SELECT 1 AS ok")),
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
