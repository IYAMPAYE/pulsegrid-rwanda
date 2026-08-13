# Admin dashboard server logic

normalize_region_label <- function(x) {
  tools::toTitleCase(tolower(trimws(as.character(x))))
}

normalize_status_label <- function(x) {
  tools::toTitleCase(tolower(trimws(as.character(x))))
}

is_unassigned_ticket <- function(technician, technician_email) {
  tech <- tolower(trimws(as.character(technician)))
  email <- tolower(trimws(as.character(technician_email)))
  tech_missing <- is.na(technician) | !nzchar(tech) | tech == "unassigned" | tech == "na"
  email_missing <- is.na(technician_email) | !nzchar(email) | email == "na"
  tech_missing | email_missing
}

apply_ops_date_filter <- function(data, preset) {
  if (nrow(data) == 0 || is.null(preset) || preset == "All time") return(data)
  today <- Sys.Date()
  start <- switch(
    preset,
    "Today" = today,
    "Last 7 days" = today - 6L,
    "Last 30 days" = today - 29L,
    "Last 90 days" = today - 89L,
    today - 29L
  )
  data[data$created_at >= start & data$created_at <= today, , drop = FALSE]
}

format_admin_datetime <- function(x) {
  if (length(x) == 0 || all(is.na(x))) return("Never")
  x <- suppressWarnings(as.POSIXct(x, tz = "Africa/Kigali"))
  ifelse(
    is.na(x),
    "Never",
    format(x, "%d %b %Y, %H:%M")
  )
}

render_ops_ticket_card <- function(row) {
  tid <- as.character(row$ticket_id)
  tags$div(class = "ops-ticket-card",
    tags$div(class = "ops-ticket-card-header",
      tags$strong(paste0("#", tid)),
      tags$span(class = "tech-status-badge tech-badge-default", normalize_status_label(row$status)),
      if ("urgency" %in% names(row)) {
        tags$span(class = paste("tech-status-badge", urgency_badge_class_ops(row$urgency)), row$urgency)
      }
    ),
    tags$div(class = "ops-ticket-card-body",
      tags$div(class = "tech-ticket-field", tags$strong("Region: "), normalize_region_label(row$region)),
      if ("name" %in% names(row) && nzchar(as.character(row$name))) {
        tags$div(class = "tech-ticket-field", tags$strong("Customer: "), row$name)
      },
      if ("created_at" %in% names(row)) {
        tags$div(class = "tech-ticket-field", tags$strong("Reported: "), format(as.Date(row$created_at), "%d %b %Y"))
      }
    )
  )
}

urgency_badge_class_ops <- function(urgency) {
  u <- tolower(trimws(as.character(urgency)))
  switch(u,
    "low" = "tech-badge-low",
    "medium" = "tech-badge-medium",
    "high" = "tech-badge-high",
    "tech-badge-default"
  )
}

build_ops_ticket_table <- function(data, include_technician = TRUE) {
  if (nrow(data) == 0) {
    cols <- c("Ticket #", "Region", "Status", "Urgency", "Customer", "Reported")
    if (include_technician) cols <- c("Ticket #", "Technician", cols[-1])
    return(as.data.frame(setNames(replicate(length(cols), character(0), simplify = FALSE), cols)))
  }

  out <- data.frame(
    `Ticket #` = as.character(data$ticket_id),
    Region = vapply(data$region, normalize_region_label, character(1)),
    Status = vapply(data$status, normalize_status_label, character(1)),
    Urgency = if ("urgency" %in% names(data)) as.character(data$urgency) else rep("—", nrow(data)),
    Customer = if ("name" %in% names(data)) {
      vapply(data$name, function(x) if (is.na(x) || !nzchar(as.character(x))) "—" else as.character(x), character(1))
    } else {
      rep("—", nrow(data))
    },
    Reported = if ("created_at" %in% names(data)) {
      vapply(data$created_at, function(x) if (is.na(x)) "—" else format(as.Date(x), "%d %b %Y"), character(1))
    } else {
      rep("—", nrow(data))
    },
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  if (include_technician) {
    tech_col <- vapply(seq_len(nrow(data)), function(i) {
      tech <- as.character(data$technician[[i]])
      if (is.na(tech) || !nzchar(trimws(tech))) "—" else tech
    }, character(1))
    out <- cbind(`Ticket #` = out[["Ticket #"]], Technician = tech_col, out[, setdiff(names(out), "Ticket #"), drop = FALSE])
  }

  out
}

build_technician_display <- function(techs, tickets = NULL) {
  if (nrow(techs) == 0) return(techs)

  ticket_counts <- if (!is.null(tickets) && nrow(tickets) > 0) {
    tickets %>%
      filter(!is_unassigned_ticket(technician, technician_email)) %>%
      mutate(email_key = tolower(trimws(as.character(technician_email)))) %>%
      group_by(email_key) %>%
      summarise(
        assigned_tickets = n(),
        open_tickets = sum(tolower(trimws(as.character(status))) != "resolved"),
        .groups = "drop"
      )
  } else {
    data.frame(email_key = character(), assigned_tickets = integer(), open_tickets = integer())
  }

  techs %>%
    mutate(
      email_key = tolower(trimws(as.character(email))),
      last_login = format_admin_datetime(last_login),
      region_label = ifelse(
        is.na(region) | !nzchar(as.character(region)),
        "—",
        normalize_region_label(region)
      ),
      status_label = ifelse(is.na(active) | active, "Active", "Inactive")
    ) %>%
    left_join(ticket_counts, by = "email_key") %>%
    mutate(
      assigned_tickets = ifelse(is.na(assigned_tickets), 0L, assigned_tickets),
      open_tickets = ifelse(is.na(open_tickets), 0L, open_tickets)
    ) %>%
    transmute(
      id = id,
      Name = name,
      Email = email,
      Phone = ifelse(is.na(phone) | !nzchar(as.character(phone)), "—", as.character(phone)),
      Region = region_label,
      Status = status_label,
      `Last Login` = last_login,
      Assigned = assigned_tickets,
      Open = open_tickets
    )
}

init_admin_server <- function(input, output, session, auth) {
  admin_nav_active <- function(section) {
    session$sendCustomMessage("adminNavActive", list(section = section))
  }

  observeEvent(input$admin_nav_overview, {
    updateTabsetPanel(session, "admin_tabs", selected = "overview")
    admin_nav_active("overview")
  })

  observeEvent(input$admin_nav_operations, {
    updateTabsetPanel(session, "admin_tabs", selected = "operations")
    admin_nav_active("operations")
  })

  show_team_config_modal <- function() {
    showModal(modalDialog(
      title = NULL,
      easyClose = TRUE,
      footer = NULL,
      size = "l",
      admin_team_modal_body()
    ))
  }

  observeEvent(input$admin_nav_team, {
    req(auth$role == "admin")
    show_team_config_modal()
  }, ignoreInit = TRUE)

  observeEvent(input$admin_nav_analytics, {
    updateTabsetPanel(session, "admin_tabs", selected = "analytics")
    admin_nav_active("analytics")
  })

  observeEvent(input$admin_nav_gis, {
    updateTabsetPanel(session, "admin_tabs", selected = "gis")
    admin_nav_active("gis")
  })

  output$admin_page_title <- renderText({
    switch(
      if (is.null(input$admin_tabs)) "overview" else input$admin_tabs,
      overview = "Overview Dashboard",
      operations = "Operations",
      analytics = "Analytics & Reports",
      gis = "GIS Portal",
      "Overview Dashboard"
    )
  })

  ops_invalidate <- reactiveVal(0)
  bump_ops_data <- function() ops_invalidate(ops_invalidate() + 1L)

  tech_table_proxy <- dataTableProxy("ops_technician_table")

  clear_technician_edit <- function() {
    updateSelectInput(session, "ops_manage_technician_id", selected = "")
    tryCatch(selectRows(tech_table_proxy, NULL), error = function(e) NULL)
  }

  ticket_data <- reactivePoll(
    intervalMillis = 30000,
    session        = session,
    checkFunc      = function() {
      if (!isTRUE(auth$logged_in) || is.null(auth$role) || auth$role != "admin") {
        return("idle")
      }
      paste0(Sys.time(), "-", ops_invalidate())
    },
    valueFunc      = function() {
      tryCatch(
        load_tickets(),
        error = function(e) {
          showNotification(
            paste("Could not connect to the database:", conditionMessage(e)),
            type = "error",
            duration = NULL
          )
          data.frame()
        }
      )
    }
  )

  filtered_data <- reactive({
    data <- ticket_data()
    if (nrow(data) == 0) return(data)

    if (!is.null(input$region_filter) && input$region_filter != "All") {
      data <- data %>% filter(tolower(trimws(as.character(region))) == tolower(input$region_filter))
    }
    if (!is.null(input$status_filter) && input$status_filter != "All") {
      data <- data %>% filter(tolower(trimws(as.character(status))) == tolower(input$status_filter))
    }
    if (!is.null(input$urgency_filter) && input$urgency_filter != "All") {
      data <- data %>% filter(tolower(trimws(as.character(urgency))) == tolower(input$urgency_filter))
    }
    data
  })

  output$total_count <- renderText({
    tryCatch(nrow(filtered_data()), error = function(e) 0)
  })

  output$open_count <- renderText({
    tryCatch(
      filtered_data() %>%
        filter(tolower(trimws(as.character(status))) != "resolved") %>%
        nrow(),
      error = function(e) 0
    )
  })

  output$progress_count <- renderText({
    tryCatch(
      filtered_data() %>%
        filter(tolower(trimws(as.character(status))) == "in progress") %>%
        nrow(),
      error = function(e) 0
    )
  })

  output$urgent_count <- renderText({
    tryCatch(
      filtered_data() %>%
        filter(tolower(trimws(as.character(urgency))) == "high") %>%
        nrow(),
      error = function(e) 0
    )
  })

  output$safety_count <- renderText({
    tryCatch({
      data <- filtered_data()
      if (!"safety_flag" %in% names(data)) return(0)
      data %>% filter(safety_flag == "Yes") %>% nrow()
    }, error = function(e) 0)
  })

  output$admin_region_chart <- renderUI({
    req(auth$role == "admin")
    data <- filtered_data()
    if (nrow(data) == 0) {
      return(tags$div(class = "tech-empty-state",
        bs_icon("geo-alt", class = "tech-empty-icon"),
        tags$p("No regional data for the current filters.")
      ))
    }
    echarts4rOutput("region_plot", height = "280px")
  })

  output$region_plot <- renderEcharts4r({
    req(auth$role == "admin")
    data <- filtered_data()
    req(nrow(data) > 0)

    data %>%
      mutate(region = normalize_region_label(region)) %>%
      count(region) %>%
      arrange(desc(n)) %>%
      e_charts(region) %>%
      e_bar(n, name = "Tickets") %>%
      e_tooltip(trigger = "axis") %>%
      e_legend(show = FALSE) %>%
      e_color(REG_CHART_PRIMARY)
  })

  output$admin_status_chart <- renderUI({
    req(auth$role == "admin")
    data <- filtered_data()
    if (nrow(data) == 0) {
      return(tags$div(class = "tech-empty-state",
        bs_icon("pie-chart", class = "tech-empty-icon"),
        tags$p("No status breakdown for the current filters.")
      ))
    }
    echarts4rOutput("status_plot", height = "280px")
  })

  output$status_plot <- renderEcharts4r({
    req(auth$role == "admin")
    data <- filtered_data()
    req(nrow(data) > 0)

    data %>%
      mutate(status = normalize_status_label(status)) %>%
      count(status) %>%
      e_charts(status) %>%
      e_pie(n, radius = c("42%", "68%")) %>%
      e_tooltip(trigger = "item") %>%
      e_legend(orient = "horizontal", bottom = 0) %>%
      e_color(REG_CHART_STATUS_COLORS)
  })

  output$ticket_table <- renderDT({
    data <- filtered_data()
    if (nrow(data) == 0) {
      return(datatable(
        data.frame(Message = "No tickets match the current filters."),
        options = list(dom = "t", ordering = FALSE),
        rownames = FALSE,
        class = "cell-border stripe compact"
      ))
    }

    data <- data %>%
      mutate(
        region = normalize_region_label(region),
        status = normalize_status_label(status)
      ) %>%
      arrange(desc(created_at))

    display_cols <- intersect(
      c("ticket_id", "name", "phone", "email", "region", "time_window",
        "status", "urgency", "safety_flag", "technician", "description",
        "urgency_reason", "created_at"),
      names(data)
    )
    data <- data[, display_cols, drop = FALSE]

    dt <- datatable(
      data,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        autoWidth = TRUE,
        dom = "frtip",
        language = list(search = "Search tickets:")
      ),
      rownames = FALSE,
      class = "cell-border stripe nowrap compact"
    )

    if ("urgency" %in% names(data)) {
      dt <- dt %>% formatStyle(
        "urgency",
        backgroundColor = styleEqual(
          c("Low", "Medium", "High"),
          REG_URGENCY_COLORS
        ),
        fontWeight = "bold"
      )
    }

    if ("safety_flag" %in% names(data)) {
      dt <- dt %>% formatStyle(
        "safety_flag",
        target = "row",
        backgroundColor = styleEqual("Yes", REG_SAFETY_ROW_COLOR)
      )
    }

    dt
  })

  analytics_filtered_data <- reactive({
    req(auth$role == "admin")
    data <- ticket_data()
    if (nrow(data) == 0) return(data)

    preset <- if (is.null(input$analytics_date_filter)) "Last 30 days" else input$analytics_date_filter
    data <- apply_ops_date_filter(data, preset)

    if (!is.null(input$analytics_region_filter) && input$analytics_region_filter != "All") {
      data <- data %>%
        filter(tolower(trimws(as.character(region))) == tolower(input$analytics_region_filter))
    }
    data
  })

  analytics_period_days <- reactive({
    preset <- if (is.null(input$analytics_date_filter)) "Last 30 days" else input$analytics_date_filter
    if (preset == "All time") {
      data <- analytics_filtered_data()
      if (nrow(data) == 0) return(1L)
      return(as.integer(difftime(max(data$created_at), min(data$created_at), units = "days")) + 1L)
    }
    switch(
      preset,
      "Today" = 1L,
      "Last 7 days" = 7L,
      "Last 30 days" = 30L,
      "Last 90 days" = 90L,
      30L
    )
  })

  output$analytics_total_count <- renderText({
    tryCatch(nrow(analytics_filtered_data()), error = function(e) 0)
  })

  output$analytics_avg_daily <- renderText({
    tryCatch({
      n <- nrow(analytics_filtered_data())
      days <- max(1L, analytics_period_days())
      sprintf("%.1f", n / days)
    }, error = function(e) "0")
  })

  output$analytics_resolved_rate <- renderText({
    tryCatch({
      data <- analytics_filtered_data()
      if (nrow(data) == 0) return("0%")
      resolved <- sum(tolower(trimws(as.character(data$status))) == "resolved")
      paste0(round(100 * resolved / nrow(data)), "%")
    }, error = function(e) "0%")
  })

  output$analytics_high_urgency_count <- renderText({
    tryCatch({
      data <- analytics_filtered_data()
      if (nrow(data) == 0) return(0)
      sum(tolower(trimws(as.character(data$urgency))) == "high")
    }, error = function(e) 0)
  })

  analytics_empty_chart <- function(message, icon = "bar-chart") {
    tags$div(class = "tech-empty-state",
      bs_icon(icon, class = "tech-empty-icon"),
      tags$p(message)
    )
  }

  output$analytics_daily_chart <- renderUI({
    req(auth$role == "admin")
    data <- analytics_filtered_data()
    if (nrow(data) == 0) {
      return(analytics_empty_chart("No ticket data for the selected period.", "graph-up"))
    }
    echarts4rOutput("analytics_daily_plot", height = "300px")
  })

  output$analytics_daily_plot <- renderEcharts4r({
    req(auth$role == "admin")
    data <- analytics_filtered_data()
    req(nrow(data) > 0)

    daily <- data %>%
      count(created_at, name = "tickets") %>%
      rename(day = created_at)

    all_days <- seq(min(daily$day), max(daily$day), by = "day")
    plot_data <- data.frame(day = all_days) %>%
      left_join(daily, by = "day") %>%
      mutate(
        tickets = ifelse(is.na(tickets), 0L, tickets),
        label = format(day, "%d %b")
      )

    plot_data %>%
      e_charts(label) %>%
      e_line(
        tickets,
        name = "Reports",
        smooth = TRUE,
        symbol = "circle",
        symbolSize = 6,
        areaStyle = list(opacity = 0.12)
      ) %>%
      e_tooltip(trigger = "axis") %>%
      e_grid(left = "3%", right = "4%", bottom = "12%", containLabel = TRUE) %>%
      e_legend(show = FALSE) %>%
      e_color(REG_CHART_PRIMARY)
  })

  output$analytics_region_chart <- renderUI({
    req(auth$role == "admin")
    data <- analytics_filtered_data()
    if (nrow(data) == 0) {
      return(analytics_empty_chart("No regional data for the selected period.", "geo-alt"))
    }
    echarts4rOutput("analytics_region_plot", height = "300px")
  })

  output$analytics_region_plot <- renderEcharts4r({
    req(auth$role == "admin")
    data <- analytics_filtered_data()
    req(nrow(data) > 0)

    data %>%
      mutate(region = normalize_region_label(region)) %>%
      count(region, name = "tickets") %>%
      arrange(desc(tickets)) %>%
      e_charts(region) %>%
      e_bar(tickets, name = "Reports") %>%
      e_tooltip(trigger = "axis") %>%
      e_legend(show = FALSE) %>%
      e_color(REG_CHART_PRIMARY)
  })

  output$analytics_status_chart <- renderUI({
    req(auth$role == "admin")
    data <- analytics_filtered_data()
    if (nrow(data) == 0) {
      return(analytics_empty_chart("No status data for the selected period.", "pie-chart"))
    }
    echarts4rOutput("analytics_status_plot", height = "280px")
  })

  output$analytics_status_plot <- renderEcharts4r({
    req(auth$role == "admin")
    data <- analytics_filtered_data()
    req(nrow(data) > 0)

    data %>%
      mutate(status = normalize_status_label(status)) %>%
      count(status) %>%
      e_charts(status) %>%
      e_pie(n, radius = c("42%", "68%")) %>%
      e_tooltip(trigger = "item") %>%
      e_legend(orient = "horizontal", bottom = 0) %>%
      e_color(REG_CHART_STATUS_COLORS)
  })

  output$analytics_urgency_chart <- renderUI({
    req(auth$role == "admin")
    data <- analytics_filtered_data()
    if (nrow(data) == 0) {
      return(analytics_empty_chart("No urgency data for the selected period.", "speedometer2"))
    }
    echarts4rOutput("analytics_urgency_plot", height = "280px")
  })

  output$analytics_urgency_plot <- renderEcharts4r({
    req(auth$role == "admin")
    data <- analytics_filtered_data()
    req(nrow(data) > 0)

    data %>%
      mutate(urgency = as.character(urgency)) %>%
      count(urgency) %>%
      e_charts(urgency) %>%
      e_pie(n, radius = c("42%", "68%")) %>%
      e_tooltip(trigger = "item") %>%
      e_legend(orient = "horizontal", bottom = 0) %>%
      e_color(c("#15803d", "#f59e0b", "#ef4444"))
  })

  output$analytics_region_table <- renderDT({
    req(auth$role == "admin")
    data <- analytics_filtered_data()

    if (nrow(data) == 0) {
      return(datatable(
        data.frame(Notice = "No data for the selected period."),
        options = list(dom = "t", ordering = FALSE),
        rownames = FALSE,
        class = "cell-border stripe compact"
      ))
    }

    summary <- data %>%
      mutate(
        region = normalize_region_label(region),
        status_norm = tolower(trimws(as.character(status))),
        urgency_norm = tolower(trimws(as.character(urgency)))
      ) %>%
      group_by(region) %>%
      summarise(
        Total = n(),
        Open = sum(status_norm != "resolved"),
        Resolved = sum(status_norm == "resolved"),
        `High urgency` = sum(urgency_norm == "high"),
        `Safety flags` = if ("safety_flag" %in% names(data)) sum(safety_flag == "Yes", na.rm = TRUE) else 0L,
        .groups = "drop"
      ) %>%
      arrange(desc(Total))

    datatable(
      summary,
      options = list(
        pageLength = 10,
        dom = "tip",
        ordering = TRUE,
        language = list(emptyTable = "No regional summary available")
      ),
      rownames = FALSE,
      class = "cell-border stripe nowrap compact admin-ops-dt"
    )
  })

  technician_roster <- reactivePoll(
    intervalMillis = 30000,
    session        = session,
    checkFunc      = function() {
      if (!isTRUE(auth$logged_in) || auth$role != "admin") return("idle")
      paste0("tech-", Sys.time(), "-", ops_invalidate())
    },
    valueFunc      = function() {
      tryCatch(
        load_technicians(),
        error = function(e) data.frame()
      )
    }
  )

  active_technicians <- reactive({
    req(auth$role == "admin")
    techs <- technician_roster()
    if (nrow(techs) == 0) return(techs)
    if (!"active" %in% names(techs)) techs$active <- TRUE
    if (!"routing_region" %in% names(techs)) techs$routing_region <- NA_character_
    if (!"assigned_region" %in% names(techs)) techs$assigned_region <- NA_character_
    techs %>%
      filter(is.na(active) | active) %>%
      mutate(region = coalesce(routing_region, assigned_region)) %>%
      distinct(id, .keep_all = TRUE) %>%
      arrange(name)
  })

  technicians_for_display <- reactive({
    techs <- technician_roster()
    if (nrow(techs) == 0) return(techs)
    if (!"routing_region" %in% names(techs)) techs$routing_region <- NA_character_
    if (!"assigned_region" %in% names(techs)) techs$assigned_region <- NA_character_
    if (!"active" %in% names(techs)) techs$active <- TRUE
    techs %>%
      group_by(id) %>%
      slice(1) %>%
      ungroup() %>%
      mutate(region = coalesce(routing_region, assigned_region))
  })

  observe({
    techs <- technicians_for_display()
    req(auth$role == "admin")
    if (nrow(techs) == 0) {
      updateSelectInput(session, "ops_manage_technician_id", choices = c("— Select from roster above —" = ""))
      return()
    }
    labels <- paste0(
      techs$name, " (",
      ifelse(is.na(techs$region) | !nzchar(as.character(techs$region)), "No region", normalize_region_label(techs$region)),
      ifelse(is.na(techs$active) | techs$active, ", Active", ", Inactive"),
      ")"
    )
    choices <- stats::setNames(as.character(techs$id), labels)
    selected <- isolate(input$ops_manage_technician_id)
    if (is.null(selected) || !selected %in% choices) selected <- ""
    updateSelectInput(
      session,
      "ops_manage_technician_id",
      choices = c("— Select from roster above —" = "", choices),
      selected = selected
    )
  })

  observeEvent(input$ops_technician_table_rows_selected, {
    req(auth$role == "admin")
    sel <- input$ops_technician_table_rows_selected
    if (length(sel) != 1) return()
    techs <- technicians_for_display()
    if (nrow(techs) == 0) return()
    display <- build_technician_display(techs, ops_filtered_data())
    if (sel > nrow(display)) return()
    updateSelectInput(
      session,
      "ops_manage_technician_id",
      selected = as.character(display$id[[sel]])
    )
  }, ignoreNULL = TRUE)

  selected_manage_technician <- reactive({
    req(auth$role == "admin")
    id <- input$ops_manage_technician_id
    if (is.null(id) || !nzchar(id)) return(NULL)
    techs <- technicians_for_display()
    tech <- techs[as.character(techs$id) == as.character(id), , drop = FALSE]
    if (nrow(tech) == 0) return(NULL)
    tech
  })

  ops_filtered_data <- reactive({
    req(auth$role == "admin")
    data <- ticket_data()
    if (nrow(data) == 0) return(data)

    data <- apply_ops_date_filter(data, input$ops_date_filter)

    if (!is.null(input$ops_region_filter) && input$ops_region_filter != "All") {
      data <- data[tolower(trimws(as.character(data$region))) == tolower(input$ops_region_filter), , drop = FALSE]
    }
    if (!is.null(input$ops_status_filter) && input$ops_status_filter != "All") {
      data <- data[tolower(trimws(as.character(data$status))) == tolower(input$ops_status_filter), , drop = FALSE]
    }
    data
  })

  ops_assigned_data <- reactive({
    data <- ops_filtered_data()
    if (nrow(data) == 0) return(data)
    assigned <- !is_unassigned_ticket(data$technician, data$technician_email)
    data[assigned, , drop = FALSE]
  })

  ops_unassigned_data <- reactive({
    data <- ops_filtered_data()
    if (nrow(data) == 0) return(data)
    unassigned <- is_unassigned_ticket(data$technician, data$technician_email)
    data[unassigned, , drop = FALSE]
  })

  output$ops_assigned_count <- renderText({
    tryCatch(nrow(ops_assigned_data()), error = function(e) 0)
  })

  output$ops_unassigned_count <- renderText({
    tryCatch(nrow(ops_unassigned_data()), error = function(e) 0)
  })

  output$ops_technician_count <- renderText({
    tryCatch(nrow(technicians_for_display()), error = function(e) 0)
  })

  output$ops_assignments_summary <- renderText({
    data <- tryCatch(ops_assigned_data(), error = function(e) data.frame())
    n_tickets <- nrow(data)
    if (n_tickets == 0) return("No assigned tickets")
    n_techs <- length(unique(tolower(trimws(as.character(data$technician_email)))))
    paste0(n_tickets, " ticket", if (n_tickets != 1) "s" else "", " · ", n_techs, " technician", if (n_techs != 1) "s" else "")
  })

  output$ops_unassigned_summary <- renderText({
    n <- tryCatch(nrow(ops_unassigned_data()), error = function(e) 0)
    if (n == 0) "All clear"
    else paste0(n, " waiting")
  })

  output$ops_assignments_table <- renderDT({
    req(auth$role == "admin")
    data <- ops_assigned_data()

    if (nrow(data) == 0) {
      return(datatable(
        data.frame(Notice = "No assigned tickets match the current filters."),
        options = list(dom = "t", ordering = FALSE),
        rownames = FALSE,
        class = "cell-border stripe compact"
      ))
    }

    data <- data[order(
      tolower(trimws(as.character(data$technician))),
      -as.numeric(as.Date(data$created_at))
    ), , drop = FALSE]

    display <- build_ops_ticket_table(data, include_technician = TRUE)
    dt <- datatable(
      display,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = "frtip",
        order = list(list(1, "asc"), list(6, "desc")),
        language = list(search = "Search assignments:", emptyTable = "No assigned tickets")
      ),
      rownames = FALSE,
      selection = "none",
      class = "cell-border stripe nowrap compact admin-ops-dt"
    )

    if ("Status" %in% names(display)) {
      dt <- dt %>% formatStyle(
        "Status",
        backgroundColor = styleEqual(
          c("New", "In Progress", "Resolved"),
          c("#fef9c3", "#dbeafe", "#dcfce7")
        ),
        fontWeight = "600"
      )
    }
    if ("Urgency" %in% names(display)) {
      dt <- dt %>% formatStyle(
        "Urgency",
        backgroundColor = styleEqual(c("Low", "Medium", "High"), REG_URGENCY_COLORS),
        fontWeight = "600"
      )
    }
    dt
  })

  output$ops_unassigned_table <- renderDT({
    req(auth$role == "admin")
    data <- ops_unassigned_data()

    if (nrow(data) == 0) {
      return(datatable(
        data.frame(Notice = "No unassigned tickets — all reports are routed."),
        options = list(dom = "t", ordering = FALSE),
        rownames = FALSE,
        class = "cell-border stripe compact"
      ))
    }

    data <- data[order(data$created_at, decreasing = TRUE), , drop = FALSE]
    display <- build_ops_ticket_table(data, include_technician = FALSE)

    dt <- datatable(
      display,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = "frtip",
        order = list(list(5, "desc")),
        language = list(search = "Search queue:", emptyTable = "Queue is empty")
      ),
      rownames = FALSE,
      selection = "none",
      class = "cell-border stripe nowrap compact admin-ops-dt"
    )

    if ("Status" %in% names(display)) {
      dt <- dt %>% formatStyle(
        "Status",
        backgroundColor = styleEqual(
          c("New", "In Progress", "Resolved"),
          c("#fef9c3", "#dbeafe", "#dcfce7")
        ),
        fontWeight = "600"
      )
    }
    if ("Urgency" %in% names(display)) {
      dt <- dt %>% formatStyle(
        "Urgency",
        backgroundColor = styleEqual(c("Low", "Medium", "High"), REG_URGENCY_COLORS),
        fontWeight = "600"
      )
    }
    dt
  })

  output$ops_reassign_panel <- renderUI({
    req(auth$role == "admin")
    techs <- active_technicians()
    if (nrow(techs) == 0) {
      return(tags$div(class = "admin-ops-card admin-ops-action-desk",
        tags$div(class = "admin-ops-card-head",
          bs_icon("arrow-left-right"),
          tags$span("Quick assign")
        ),
        tags$div(class = "admin-ops-card-body",
          tags$p(class = "admin-ops-help", "No active technicians available. Add or activate a technician in the Team tab.")
        )
      ))
    }

    unassigned <- ops_unassigned_data()
    open_tickets <- ops_filtered_data()
    if (nrow(open_tickets) > 0) {
      open_tickets <- open_tickets[
        tolower(trimws(as.character(open_tickets$status))) != "resolved",
        ,
        drop = FALSE
      ]
    }

    ticket_source <- if (nrow(unassigned) > 0) unassigned else open_tickets
    if (nrow(ticket_source) == 0) {
      return(tags$div(class = "admin-ops-card admin-ops-action-desk",
        tags$div(class = "admin-ops-card-head",
          bs_icon("arrow-left-right"),
          tags$span("Quick assign")
        ),
        tags$div(class = "admin-ops-card-body",
          tags$p(class = "admin-ops-help", "No open tickets match the current filters.")
        )
      ))
    }

    ticket_labels <- paste0(
      "#", ticket_source$ticket_id, " — ",
      normalize_region_label(ticket_source$region), " (",
      normalize_status_label(ticket_source$status), ")"
    )
    if (nrow(unassigned) > 0) {
      ticket_labels <- paste0("[Unassigned] ", ticket_labels)
    }
    ticket_choices <- stats::setNames(as.character(ticket_source$ticket_id), ticket_labels)

    tech_labels <- paste0(
      techs$name, " — ",
      normalize_region_label(techs$region)
    )
    tech_choices <- stats::setNames(as.character(techs$id), tech_labels)

    tags$div(class = "admin-ops-card admin-ops-action-desk",
      tags$div(class = "admin-ops-card-head",
        bs_icon("arrow-left-right"),
        tags$span("Quick assign")
      ),
      tags$div(class = "admin-ops-card-body",
        tags$p(class = "admin-ops-help",
          if (nrow(unassigned) > 0) {
            paste0(nrow(unassigned), " unassigned ticket(s) in queue.")
          } else {
            "Reassign any open ticket to a different technician."
          }
        ),
        tags$div(class = "admin-ops-action-grid",
          selectInput("ops_reassign_ticket", "Ticket", choices = ticket_choices, width = "100%"),
          selectInput("ops_reassign_technician", "Assign to", choices = tech_choices, width = "100%"),
          tags$div(class = "admin-ops-action-submit",
            actionButton(
              "ops_reassign_submit",
              tagList(bs_icon("check2"), " Assign"),
              class = "btn btn-primary btn-submit-custom"
            )
          )
        )
      )
    )
  })

  observeEvent(input$ops_reassign_submit, {
    req(auth$role == "admin", input$ops_reassign_ticket, input$ops_reassign_technician)
    techs <- active_technicians()
    tech <- techs[as.character(techs$id) == as.character(input$ops_reassign_technician), , drop = FALSE]
    if (nrow(tech) == 0) {
      showNotification("Select a valid technician.", type = "error")
      return()
    }
    tryCatch({
      reassign_ticket(input$ops_reassign_ticket, tech$name[[1]], tech$email[[1]])
      bump_ops_data()
      showNotification(
        paste0("Ticket #", input$ops_reassign_ticket, " assigned to ", tech$name[[1]], "."),
        type = "message"
      )
    }, error = function(e) {
      showNotification(conditionMessage(e), type = "error")
    })
  }, ignoreInit = TRUE)

  observeEvent(input$ops_add_technician_btn, {
    req(auth$role == "admin")
    showModal(modalDialog(
      title = tagList(bs_icon("person-plus"), " Add technician"),
      size = "m",
      easyClose = TRUE,
      textInput("ops_new_name", "Full name"),
      textInput("ops_new_email", "Email"),
      textInput("ops_new_phone", "Phone (optional)"),
      selectInput("ops_new_region", "Assigned region", choices = regions),
      passwordInput("ops_new_password", "Temporary password"),
      tags$p(class = "admin-ops-help", "They will be asked to change this password on first login."),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("ops_create_technician_confirm", "Create", class = "btn btn-primary btn-submit-custom")
      )
    ))
  }, ignoreInit = TRUE)

  observeEvent(input$ops_create_technician_confirm, {
    req(auth$role == "admin")
    tryCatch({
      create_technician(
        input$ops_new_name,
        input$ops_new_email,
        input$ops_new_phone,
        input$ops_new_region,
        input$ops_new_password
      )
      removeModal()
      bump_ops_data()
      showNotification("Technician created and region routing updated.", type = "message")
    }, error = function(e) {
      showNotification(conditionMessage(e), type = "error", duration = 8)
    })
  }, ignoreInit = TRUE)

  output$ops_technician_table <- renderDT({
    req(auth$role == "admin")
    tryCatch({
      techs <- technicians_for_display()
      tickets <- ops_filtered_data()

      if (nrow(techs) == 0) {
        return(datatable(
          data.frame(Notice = "No technicians yet. Use Add technician above."),
          options = list(dom = "t", ordering = FALSE),
          rownames = FALSE,
          class = "cell-border stripe compact"
        ))
      }

      display <- build_technician_display(techs, tickets)

      dt <- datatable(
        display,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = "frtip",
          language = list(search = "Search roster:", emptyTable = "No technicians"),
          columnDefs = list(list(visible = FALSE, targets = 0))
        ),
        rownames = FALSE,
        selection = "single",
        class = "cell-border stripe nowrap compact admin-ops-dt"
      )
      if ("Status" %in% names(display)) {
        dt <- dt %>% formatStyle(
          "Status",
          backgroundColor = styleEqual(c("Active", "Inactive"), c("#dcfce7", "#fee2e2")),
          fontWeight = "bold"
        )
      }
      dt
    }, error = function(e) {
      datatable(
        data.frame(Error = paste("Could not load technicians:", conditionMessage(e))),
        options = list(dom = "t", ordering = FALSE),
        rownames = FALSE,
        class = "cell-border stripe compact"
      )
    })
  })

  output$ops_technician_edit_form <- renderUI({
    req(auth$role == "admin")
    tech <- selected_manage_technician()
    if (is.null(tech)) {
      return(tags$div(class = "admin-ops-edit-empty",
        bs_icon("person-lines-fill"),
        tags$p("Select a technician from the roster table or dropdown to edit their profile.")
      ))
    }

    is_active <- is.na(tech$active[[1]]) || isTRUE(tech$active[[1]])
    tagList(
      tags$div(class = "admin-ops-form-section",
        tags$h4(class = "admin-ops-form-section-title", "Profile"),
        tags$div(class = "admin-ops-form-grid",
          textInput("ops_edit_name", "Full name", value = tech$name[[1]]),
          textInput("ops_edit_email", "Email", value = tech$email[[1]]),
          textInput("ops_edit_phone", "Phone", value = ifelse(is.na(tech$phone), "", tech$phone[[1]]))
        )
      ),
      tags$div(class = "admin-ops-form-section",
        tags$h4(class = "admin-ops-form-section-title", "Region & routing"),
        selectInput(
          "ops_edit_region", "Assigned region (n8n auto-routing)",
          choices = regions,
          selected = ifelse(
            is.na(tech$region) || !nzchar(as.character(tech$region)),
            regions[[1]],
            normalize_region_label(tech$region)
          ),
          width = "100%"
        ),
        checkboxInput(
          "ops_edit_active",
          "Active — receives new auto-routed tickets",
          value = is_active
        )
      ),
      tags$div(class = "admin-ops-form-section",
        tags$h4(class = "admin-ops-form-section-title", "Account access"),
        passwordInput("ops_edit_password", "New temporary password (optional)"),
        tags$div(class = "admin-ops-form-actions",
          actionButton(
            "ops_save_technician_btn",
            tagList(bs_icon("check2"), " Save changes"),
            class = "btn btn-primary btn-submit-custom"
          ),
          if (is_active) {
            actionButton(
              "ops_deactivate_technician_btn",
              tagList(bs_icon("person-x"), " Deactivate"),
              class = "btn btn-outline-danger admin-ops-secondary-btn"
            )
          } else {
            actionButton(
              "ops_activate_technician_btn",
              tagList(bs_icon("person-check"), " Activate"),
              class = "btn btn-outline-success admin-ops-secondary-btn"
            )
          }
        )
      )
    )
  })

  observeEvent(input$ops_save_technician_btn, {
    req(auth$role == "admin")
    tech <- selected_manage_technician()
    if (is.null(tech)) return()

    tech_id <- tech$id[[1]]
    tryCatch({
      update_technician_admin(
        tech_id,
        input$ops_edit_name,
        input$ops_edit_email,
        input$ops_edit_phone,
        input$ops_edit_region,
        isTRUE(input$ops_edit_active)
      )
      if (nzchar(input$ops_edit_password)) {
        admin_reset_technician_password(tech_id, input$ops_edit_password)
      }
      bump_ops_data()
      clear_technician_edit()
      showNotification("Technician updated successfully.", type = "message")
    }, error = function(e) {
      showNotification(conditionMessage(e), type = "error", duration = 8)
    })
  }, ignoreInit = TRUE)

  observeEvent(input$ops_deactivate_technician_btn, {
    req(auth$role == "admin")
    tech <- selected_manage_technician()
    if (is.null(tech)) return()
    tryCatch({
      set_technician_active(tech$id[[1]], FALSE)
      bump_ops_data()
      clear_technician_edit()
      showNotification(
        paste0(tech$name[[1]], " deactivated — they can no longer sign in."),
        type = "message"
      )
    }, error = function(e) {
      showNotification(conditionMessage(e), type = "error")
    })
  }, ignoreInit = TRUE)

  observeEvent(input$ops_activate_technician_btn, {
    req(auth$role == "admin")
    tech <- selected_manage_technician()
    if (is.null(tech)) return()
    tryCatch({
      set_technician_active(tech$id[[1]], TRUE)
      bump_ops_data()
      clear_technician_edit()
      showNotification(
        paste0(tech$name[[1]], " activated — they can sign in and receive routed tickets."),
        type = "message"
      )
    }, error = function(e) {
      showNotification(conditionMessage(e), type = "error")
    })
  }, ignoreInit = TRUE)
}
