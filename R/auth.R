# Authentication and technician account helpers
authenticate_user <- function(email, password) {
  with_db({
    rows <- dbGetQuery(con, "
      select 'admin'::text as role, id, name, email,
             null::text as phone, false as must_change_password, password_hash,
             true as active
      from admins where lower(email) = lower($1)
      union all
      select 'technician', id, name, email, phone, must_change_password, password_hash,
             coalesce(active, true) as active
      from technicians where lower(email) = lower($1)
      limit 2
    ", params = list(email))

    if (nrow(rows) == 0) return(NULL)

    for (i in seq_len(nrow(rows))) {
      row <- rows[i, ]
      if (is.na(row$password_hash) || !nzchar(row$password_hash)) next
      if (!bcrypt::checkpw(password, row$password_hash)) next

      if (identical(row$role, "technician") && !isTRUE(row$active)) {
        return(list(deactivated = TRUE))
      }

      return(list(
        role = row$role,
        id = row$id,
        name = row$name,
        email = row$email,
        phone = if (identical(row$role, "technician")) row$phone else NULL,
        must_change_password = if (identical(row$role, "technician")) isTRUE(row$must_change_password) else FALSE,
        active = isTRUE(row$active)
      ))
    }

    NULL
  })
}

record_technician_login <- function(technician_id) {
  tryCatch(
    with_db(
      dbExecute(con, "update technicians set last_login = now() where id = $1", params = list(technician_id))
    ),
    error = function(e) invisible(NULL)
  )
}

defer_technician_login <- function(technician_id) {
  runner <- function() record_technician_login(technician_id)
  if (requireNamespace("later", quietly = TRUE)) {
    later::later(runner, delay = 0)
  } else {
    runner()
  }
}

verify_technician_password <- function(technician_id, password) {
  with_db({
    row <- dbGetQuery(con, "select password_hash from technicians where id = $1", params = list(technician_id))
    if (nrow(row) == 0) return(FALSE)
    bcrypt::checkpw(password, row$password_hash[1])
  })
}

update_technician_password <- function(technician_id, new_password) {
  with_db({
    hash <- bcrypt::hashpw(new_password)
    dbExecute(con, "update technicians set password_hash = $1 where id = $2", params = list(hash, technician_id))
  })
}

update_technician_profile <- function(technician_id, email, phone) {
  with_db(
    dbExecute(
      con,
      "update technicians set email = $1, phone = $2 where id = $3",
      params = list(email, phone, technician_id)
    )
  )
}

load_technician_tickets <- function(technician_email) {
  with_db(
    dbGetQuery(
      con,
      "select * from tickets where lower(technician_email) = lower($1) order by created_at desc",
      params = list(technician_email)
    )
  )
}

set_new_technician_password <- function(technician_id, new_password) {
  with_db({
    hash <- bcrypt::hashpw(new_password)
    dbExecute(
      con,
      "update technicians set password_hash = $1, must_change_password = false where id = $2",
      params = list(hash, technician_id)
    )
  })
}
