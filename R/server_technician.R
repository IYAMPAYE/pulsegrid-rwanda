# Technician dashboard server logic

init_technician_server <- function(input, output, session, auth) {
  technician_tickets <- reactivePoll(
    intervalMillis = 30000,
    session        = session,
    checkFunc      = function() Sys.time(),
    valueFunc      = function() {
      req(auth$role == "technician")
      tryCatch(
        load_technician_tickets(auth$email),
        error = function(e) {
          showNotification(paste("Could not load your tickets:", conditionMessage(e)), type = "error")
          data.frame()
        }
      )
    }
  )

  output$tech_status_donut <- renderEcharts4r({
    req(auth$role == "technician")
    data <- technician_tickets()
    req(nrow(data) > 0)

    data %>%
      count(status) %>%
      e_charts(status) %>%
      e_pie(n, radius = c("50%", "70%")) %>%
      e_tooltip(trigger = "item")
  })

  output$tech_recent_activity <- renderUI({
    req(auth$role == "technician")
    data <- technician_tickets()

    if (nrow(data) == 0) {
      return(tags$p("No tickets assigned to you yet.", style = "color:#64748b;"))
    }

    recent <- head(data, 5)

    tagList(lapply(seq_len(nrow(recent)), function(i) {
      row <- recent[i, ]
      badge_color <- switch(row$status,
                            "new" = "#f59e0b", "New" = "#f59e0b",
                            "In Progress" = "#3b82f6",
                            "Resolved" = "#22c55e",
                            "#94a3b8"
      )
      tags$div(style = "padding: 10px 0; border-bottom: 1px solid #e2e8f0;",
               tags$div(style = paste0("display:inline-block; width:8px; height:8px; border-radius:50%; background:", badge_color, "; margin-right:8px;")),
               tags$strong(paste0("#", row$ticket_id)), " — ", row$region,
               tags$br(),
               tags$span(style = "color:#64748b; font-size: 12px;", paste(row$status, "•", row$urgency, "•", row$time_window))
      )
    }))
  })

  output$notif_badge <- renderText({
    req(auth$role == "technician")
    data <- technician_tickets()
    if (nrow(data) == 0) return(" 0")
    n_new <- sum(data$status %in% c("new", "New"))
    paste0(" ", n_new)
  })

  observeEvent(input$notif_bell, {
    req(auth$role == "technician")
    data <- technician_tickets()
    new_tickets <- data[data$status %in% c("new", "New"), , drop = FALSE]

    body <- if (nrow(new_tickets) == 0) {
      tags$p("No new tickets right now.")
    } else {
      tagList(lapply(seq_len(nrow(new_tickets)), function(i) {
        row <- new_tickets[i, ]
        tags$div(style = "padding: 8px 0; border-bottom: 1px solid #e2e8f0;",
                 tags$strong(paste0("#", row$ticket_id)), " — ", row$region, " (", row$urgency, ")"
        )
      }))
    }

    showModal(modalDialog(title = "New tickets", body, easyClose = TRUE))
  })

  observeEvent(input$save_profile_btn, {
    req(auth$role == "technician")
    tryCatch({
      update_technician_profile(auth$id, trimws(input$profile_email), trimws(input$profile_phone))
      auth$email <- trimws(input$profile_email)
      auth$phone <- trimws(input$profile_phone)
      output$profile_save_message <- renderUI(tags$p(style = "color:#16a34a;", "Saved."))
    }, error = function(e) {
      output$profile_save_message <- renderUI(tags$p(style = "color:#b91c1c;", paste("Could not save:", conditionMessage(e))))
    })
  })

  observeEvent(input$save_password_btn, {
    req(auth$role == "technician")

    if (!verify_technician_password(auth$id, input$current_password)) {
      output$password_save_message <- renderUI(tags$p(style = "color:#b91c1c;", "Current password is incorrect."))
      return()
    }
    if (nchar(input$profile_new_password) < 6) {
      output$password_save_message <- renderUI(tags$p(style = "color:#b91c1c;", "New password must be at least 6 characters."))
      return()
    }
    if (input$profile_new_password != input$profile_confirm_password) {
      output$password_save_message <- renderUI(tags$p(style = "color:#b91c1c;", "New passwords don't match."))
      return()
    }

    tryCatch({
      update_technician_password(auth$id, input$profile_new_password)
      output$password_save_message <- renderUI(tags$p(style = "color:#16a34a;", "Password updated."))
    }, error = function(e) {
      output$password_save_message <- renderUI(tags$p(style = "color:#b91c1c;", paste("Could not update password:", conditionMessage(e))))
    })
  })
}
