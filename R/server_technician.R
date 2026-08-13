# Technician dashboard server logic

is_new_status <- function(status) {
  tolower(trimws(as.character(status))) == "new"
}

is_open_status <- function(status) {
  s <- tolower(trimws(as.character(status)))
  s %in% c("new", "in progress")
}

is_progress_status <- function(status) {
  tolower(trimws(as.character(status))) == "in progress"
}

status_badge_class <- function(status) {
  s <- tolower(trimws(as.character(status)))
  switch(s,
    "new" = "tech-badge-new",
    "in progress" = "tech-badge-progress",
    "resolved" = "tech-badge-resolved",
    "tech-badge-default"
  )
}

urgency_badge_class <- function(urgency) {
  u <- tolower(trimws(as.character(urgency)))
  switch(u,
    "low" = "tech-badge-low",
    "medium" = "tech-badge-medium",
    "high" = "tech-badge-high",
    "tech-badge-default"
  )
}

init_technician_server <- function(input, output, session, auth) {
  tech_ticket_refresh <- reactiveVal(0)

  technician_session_ok <- reactivePoll(
    intervalMillis = 15000,
    session = session,
    checkFunc = function() {
      if (!isTRUE(auth$logged_in) || is.null(auth$role) || auth$role != "technician") {
        return("idle")
      }
      paste0(Sys.time(), "-", auth$id)
    },
    valueFunc = function() {
      tryCatch(
        technician_is_active(auth$id),
        error = function(e) TRUE
      )
    }
  )

  observeEvent(technician_session_ok(), {
    req(auth$logged_in, auth$role == "technician")
    if (!isTRUE(technician_session_ok())) {
      auth$logged_in <- FALSE
      auth$role <- NULL
      auth$id <- NULL
      auth$name <- NULL
      auth$email <- NULL
      auth$phone <- NULL
      auth$must_change_password <- FALSE
      showNotification(
        "Your account has been deactivated. Please contact the administration.",
        type = "error",
        duration = NULL
      )
    }
  }, ignoreInit = TRUE)

  technician_tickets <- reactive({
    tech_ticket_refresh()
    req(auth$role == "technician")
    tryCatch(
      load_technician_tickets(auth$email),
      error = function(e) {
        showNotification(paste("Could not load your tickets:", conditionMessage(e)), type = "error")
        data.frame()
      }
    )
  })

  observe({
    req(auth$role == "technician")
    invalidateLater(30000, session)
    isolate(tech_ticket_refresh(tech_ticket_refresh() + 1))
  })

  filtered_tech_data <- reactive({
    data <- technician_tickets()
    if (nrow(data) == 0) return(data)

    if (!is.null(input$tech_status_filter) && input$tech_status_filter != "All") {
      data <- data[tolower(trimws(as.character(data$status))) == tolower(input$tech_status_filter), , drop = FALSE]
    }
    if (!is.null(input$tech_urgency_filter) && input$tech_urgency_filter != "All") {
      data <- data[tolower(trimws(as.character(data$urgency))) == tolower(input$tech_urgency_filter), , drop = FALSE]
    }
    data
  })

  output$tech_ticket_list <- renderUI({
    req(auth$role == "technician")
    data <- filtered_tech_data()

    if (nrow(data) == 0) {
      return(tags$div(class = "tech-empty-state",
        bs_icon("inbox", class = "tech-empty-icon"),
        tags$p("No tickets match your filters.")
      ))
    }

    data <- data[order(as.Date(data$created_at), decreasing = TRUE), , drop = FALSE]

    tags$div(class = "tech-ticket-list", lapply(seq_len(nrow(data)), function(i) {
      row <- data[i, ]
      tid <- as.character(row$ticket_id)
      tags$div(class = "tech-ticket-card",
        tags$div(class = "tech-ticket-card-header",
          tags$strong(paste0("#", tid)),
          tags$span(class = paste("tech-status-badge", status_badge_class(row$status)), row$status),
          if ("urgency" %in% names(row)) {
            tags$span(class = paste("tech-status-badge", urgency_badge_class(row$urgency)), row$urgency)
          },
          if ("safety_flag" %in% names(row) && identical(as.character(row$safety_flag), "Yes")) {
            tags$span(class = "tech-status-badge tech-badge-high", bs_icon("shield-exclamation"), " Safety")
          }
        ),
        tags$div(class = "tech-ticket-card-body",
          tags$div(class = "tech-ticket-field", tags$strong("Region: "), row$region),
          if ("name" %in% names(row)) tags$div(class = "tech-ticket-field", tags$strong("Customer: "), row$name),
          if ("phone" %in% names(row)) tags$div(class = "tech-ticket-field", tags$strong("Phone: "), row$phone),
          if ("time_window" %in% names(row)) tags$div(class = "tech-ticket-field", tags$strong("Window: "), row$time_window),
          if ("created_at" %in% names(row)) {
            tags$div(class = "tech-ticket-field", tags$strong("Reported: "), format(as.Date(row$created_at), "%d %b %Y"))
          }
        ),
        if ("description" %in% names(row) && nzchar(as.character(row$description))) {
          tags$p(class = "tech-activity-desc", row$description)
        }
      )
    }))
  })

  observeEvent(input$tech_nav_assignments, {
    updateTabsetPanel(session, "tech_tabs", selected = "assignments")
  })

  observeEvent(input$tech_nav_profile, {
    updateTabsetPanel(session, "tech_tabs", selected = "profile")
  })

  output$tech_priority_alert <- renderUI({
    req(auth$role == "technician")
    data <- technician_tickets()
    if (nrow(data) == 0) return(NULL)

    urgent_open <- data[is_open_status(data$status) & tolower(as.character(data$urgency)) == "high", , drop = FALSE]
    safety_open <- if ("safety_flag" %in% names(data)) {
      data[is_open_status(data$status) & data$safety_flag == "Yes", , drop = FALSE]
    } else {
      urgent_open[0, , drop = FALSE]
    }

    if (nrow(urgent_open) == 0 && nrow(safety_open) == 0) return(NULL)

    tags$div(class = "tech-priority-banner",
      tags$div(class = "tech-priority-icon", bs_icon("exclamation-octagon-fill")),
      tags$div(class = "tech-priority-text",
        if (nrow(safety_open) > 0) {
          tags$p(tags$strong("Safety alert: "), paste0(nrow(safety_open), " open ticket(s) flagged for safety review."))
        },
        if (nrow(urgent_open) > 0) {
          tags$p(tags$strong("High urgency: "), paste0(nrow(urgent_open), " open ticket(s) need immediate attention."))
        }
      )
    )
  })

  output$tech_total_count <- renderText({
    req(auth$role == "technician")
    nrow(technician_tickets())
  })

  output$tech_open_count <- renderText({
    req(auth$role == "technician")
    sum(is_open_status(technician_tickets()$status))
  })

  output$tech_progress_count <- renderText({
    req(auth$role == "technician")
    sum(is_progress_status(technician_tickets()$status))
  })

  output$tech_urgent_count <- renderText({
    req(auth$role == "technician")
    data <- technician_tickets()
    if (nrow(data) == 0) return(0)
    sum(tolower(as.character(data$urgency)) == "high" & is_open_status(data$status))
  })

  output$tech_status_chart <- renderUI({
    req(auth$role == "technician")
    data <- technician_tickets()
    if (nrow(data) == 0) {
      return(tags$div(class = "tech-empty-state",
        bs_icon("inbox", class = "tech-empty-icon"),
        tags$p("No tickets assigned yet.")
      ))
    }
    echarts4rOutput("tech_status_donut", height = "280px")
  })

  output$tech_region_chart <- renderUI({
    req(auth$role == "technician")
    data <- technician_tickets()
    if (nrow(data) == 0) {
      return(tags$div(class = "tech-empty-state",
        bs_icon("geo-alt", class = "tech-empty-icon"),
        tags$p("Regional breakdown appears when tickets are assigned.")
      ))
    }
    echarts4rOutput("tech_region_plot", height = "280px")
  })

  output$tech_status_donut <- renderEcharts4r({
    req(auth$role == "technician")
    data <- technician_tickets()
    req(nrow(data) > 0)

    data %>%
      mutate(status = tools::toTitleCase(tolower(trimws(as.character(status))))) %>%
      count(status) %>%
      e_charts(status) %>%
      e_pie(n, radius = c("42%", "68%")) %>%
      e_tooltip(trigger = "item") %>%
      e_legend(orient = "horizontal", bottom = 0) %>%
      e_color(REG_CHART_STATUS_COLORS)
  })

  output$tech_region_plot <- renderEcharts4r({
    req(auth$role == "technician")
    data <- technician_tickets()
    req(nrow(data) > 0)

    data %>%
      count(region) %>%
      arrange(desc(n)) %>%
      e_charts(region) %>%
      e_bar(n, name = "Tickets") %>%
      e_tooltip(trigger = "axis") %>%
      e_legend(show = FALSE) %>%
      e_color(REG_CHART_PRIMARY)
  })

  output$tech_recent_activity <- renderUI({
    req(auth$role == "technician")
    data <- technician_tickets()

    if (nrow(data) == 0) {
      return(tags$div(class = "tech-empty-state",
        bs_icon("clipboard-check", class = "tech-empty-icon"),
        tags$p("You're all caught up — no recent activity.")
      ))
    }

    recent <- head(data[order(as.Date(data$created_at), decreasing = TRUE), , drop = FALSE], 6)

    tagList(lapply(seq_len(nrow(recent)), function(i) {
      row <- recent[i, ]
      tid <- as.character(row$ticket_id)
      tags$div(class = "tech-activity-item",
        tags$div(class = "tech-activity-main",
          tags$div(class = "tech-activity-top",
            tags$strong(class = "tech-activity-id", paste0("#", tid)),
            tags$span(class = paste("tech-status-badge", status_badge_class(row$status)), row$status),
            if ("urgency" %in% names(row)) {
              tags$span(class = paste("tech-status-badge", urgency_badge_class(row$urgency)), row$urgency)
            }
          ),
          tags$p(class = "tech-activity-region", bs_icon("geo-alt"), row$region),
          if ("description" %in% names(row) && nzchar(as.character(row$description))) {
            tags$p(class = "tech-activity-desc", row$description)
          }
        ),
        tags$div(class = "tech-activity-meta",
          if ("time_window" %in% names(row)) tags$span(row$time_window),
          if ("created_at" %in% names(row)) tags$span(format(as.Date(row$created_at), "%d %b %Y"))
        )
      )
    }))
  })

  output$notif_badge <- renderText({
    req(auth$role == "technician")
    data <- technician_tickets()
    if (nrow(data) == 0) return("0")
    as.character(sum(is_new_status(data$status)))
  })

  observeEvent(input$notif_bell, {
    req(auth$role == "technician")
    data <- technician_tickets()
    new_tickets <- data[is_new_status(data$status), , drop = FALSE]

    body <- if (nrow(new_tickets) == 0) {
      tags$div(class = "tech-empty-state tech-empty-state-compact",
        bs_icon("bell-slash", class = "tech-empty-icon"),
        tags$p("No new tickets right now.")
      )
    } else {
      tagList(lapply(seq_len(nrow(new_tickets)), function(i) {
        row <- new_tickets[i, ]
        tags$div(class = "tech-activity-item tech-activity-item-compact",
          bs_icon("ticket-detailed", class = "dropdown-item-icon"),
          tags$strong(paste0("#", row$ticket_id)), " — ", row$region,
          tags$span(class = paste("tech-status-badge", urgency_badge_class(row$urgency)), row$urgency)
        )
      }))
    }

    showModal(modalDialog(
      title = tagList(bs_icon("bell-fill"), " New ticket alerts"),
      body,
      easyClose = TRUE,
      footer = modalButton("Close")
    ))
  })

  observeEvent(input$save_profile_btn, {
    req(auth$role == "technician")
    tryCatch({
      update_technician_profile(auth$id, trimws(input$profile_email), trimws(input$profile_phone))
      auth$email <- trimws(input$profile_email)
      auth$phone <- trimws(input$profile_phone)
      output$profile_save_message <- renderUI(
        tags$p(class = "msg-success", bs_icon("check-circle-fill"), "Saved.")
      )
    }, error = function(e) {
      output$profile_save_message <- renderUI(
        tags$p(class = "msg-error", bs_icon("exclamation-circle-fill"), paste("Could not save:", conditionMessage(e)))
      )
    })
  })

  observeEvent(input$save_password_btn, {
    req(auth$role == "technician")

    if (!verify_technician_password(auth$id, input$current_password)) {
      output$password_save_message <- renderUI(tags$p(class = "msg-error", bs_icon("exclamation-circle-fill"), "Current password is incorrect."))
      return()
    }
    if (nchar(input$profile_new_password) < 6) {
      output$password_save_message <- renderUI(tags$p(class = "msg-error", bs_icon("exclamation-circle-fill"), "New password must be at least 6 characters."))
      return()
    }
    if (input$profile_new_password != input$profile_confirm_password) {
      output$password_save_message <- renderUI(tags$p(class = "msg-error", bs_icon("exclamation-circle-fill"), "New passwords don't match."))
      return()
    }

    tryCatch({
      update_technician_password(auth$id, input$profile_new_password)
      output$password_save_message <- renderUI(
        tags$p(class = "msg-success", bs_icon("check-circle-fill"), "Password updated.")
      )
    }, error = function(e) {
      output$password_save_message <- renderUI(
        tags$p(class = "msg-error", bs_icon("exclamation-circle-fill"), paste("Could not update password:", conditionMessage(e)))
      )
    })
  })
}
