# Main Shiny server — wires auth, admin, and technician modules

server <- function(input, output, session) {
  session$onFlushed(function() schedule_db_warm(), once = TRUE)

  auth <- reactiveValues(
    logged_in = FALSE,
    role = NULL,
    id = NULL,
    name = NULL,
    email = NULL,
    phone = NULL,
    must_change_password = FALSE
  )

  init_auth_server(input, output, session, auth)
  init_admin_server(input, output, session, auth)
  init_technician_server(input, output, session, auth)
}
