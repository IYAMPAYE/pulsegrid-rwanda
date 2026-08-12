# Auth server: login, logout, routing

init_auth_server <- function(input, output, session, auth) {
  login_error <- reactiveVal(NULL)
  change_password_error <- reactiveVal(NULL)
  login_busy <- reactiveVal(FALSE)

  notify_login_result <- function(success, error = NULL) {
    session$sendCustomMessage("loginComplete", list(
      success = success,
      error = error
    ))
  }

  observeEvent(input$login_btn, {
    if (login_busy()) return()
    login_busy(TRUE)
    on.exit(login_busy(FALSE), add = TRUE)

    email <- trimws(input$login_email)
    password <- input$login_password

    if (!nzchar(email) || !nzchar(password)) {
      err <- "Please enter your email and password."
      login_error(err)
      notify_login_result(FALSE, err)
      return()
    }

    result <- tryCatch(
      authenticate_user(email, password),
      error = function(e) {
        err <- paste("Connection error:", conditionMessage(e))
        login_error(err)
        notify_login_result(FALSE, err)
        NULL
      }
    )

    if (is.null(result)) {
      if (is.null(login_error())) {
        err <- "Invalid email or password."
        login_error(err)
        notify_login_result(FALSE, err)
      }
      return()
    }

    login_error(NULL)
    notify_login_result(TRUE)
    removeModal()
    auth$logged_in <- TRUE
    auth$role <- result$role
    auth$id <- result$id
    auth$name <- result$name
    auth$email <- result$email
    auth$phone <- result$phone
    auth$must_change_password <- isTRUE(result$must_change_password)
    if (identical(result$role, "technician")) {
      defer_technician_login(result$id)
    }
  })

  observeEvent(input$change_password_btn, {
    new_pw <- input$new_password
    confirm_pw <- input$confirm_password

    if (nchar(new_pw) < 6) {
      change_password_error("Password must be at least 6 characters.")
      return()
    }
    if (new_pw != confirm_pw) {
      change_password_error("Passwords don't match.")
      return()
    }

    tryCatch({
      set_new_technician_password(auth$id, new_pw)
      change_password_error(NULL)
      auth$must_change_password <- FALSE
    }, error = function(e) {
      change_password_error(paste("Could not update password:", conditionMessage(e)))
    })
  })

  show_login_modal <- function() {
    login_error(NULL)
    schedule_db_warm()
    showModal(modalDialog(
      title = NULL,
      easyClose = TRUE,
      footer = NULL,
      tags$div(class = "landing-auth-card", style = "padding: 20px 10px; border-radius: 12px;",
        tags$div(class = "auth-card-header",
          tags$h3("Operational Login"),
          tags$p("Sign in with your REG operational credentials")
        ),
        tags$div(class = "form-group-custom",
          tags$label("Email Address"),
          tags$div(class = "input-with-icon",
            bs_icon("envelope-fill"),
            textInput("login_email", label = NULL, placeholder = "name@reg.rw")
          )
        ),
        tags$div(class = "form-group-custom",
          tags$label("Password"),
          tags$div(class = "input-with-icon",
            bs_icon("lock-fill"),
            passwordInput("login_password", label = NULL, placeholder = "••••••••")
          )
        ),
        tags$button(
          id = "login_btn", type = "button",
          class = "btn btn-submit-custom action-button",
          tags$span(class = "auth-btn-spinner auth-spinner", style = "display: none;"),
          tags$span(class = "auth-btn-label", bs_icon("box-arrow-in-right"), " Sign In to Portal")
        ),
        tags$div(id = "login-feedback", class = "login-feedback", `aria-live` = "polite")
      )
    ))
  }

  observeEvent(input$nav_login_btn, { show_login_modal() })
  observeEvent(input$hero_login_btn, { show_login_modal() })
  observeEvent(input$cta_login_btn, { show_login_modal() })

  observeEvent(input$logout_btn, {
    auth$logged_in <- FALSE
    auth$role <- NULL
    auth$id <- NULL
    auth$name <- NULL
    auth$email <- NULL
    auth$phone <- NULL
    auth$must_change_password <- FALSE
    login_error(NULL)
  })

  output$page <- renderUI({
    if (!auth$logged_in) {
      reg_landing_ui()
    } else if (auth$role == "technician" && auth$must_change_password) {
      change_password_ui(change_password_error())
    } else if (auth$role == "admin") {
      admin_dashboard_ui(auth$name)
    } else if (auth$role == "technician") {
      technician_dashboard_ui(list(id = auth$id, name = auth$name, email = auth$email, phone = auth$phone))
    }
  })
}
