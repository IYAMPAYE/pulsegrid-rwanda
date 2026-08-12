# Admin dashboard server logic

init_admin_server <- function(input, output, session, auth) {
  ticket_data <- reactivePoll(
    intervalMillis = 30000,
    session        = session,
    checkFunc      = function() {
      if (!isTRUE(auth$logged_in) || is.null(auth$role) || auth$role != "admin") {
        return("idle")
      }
      as.character(Sys.time())
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
    req(nrow(data) > 0)

    if (!is.null(input$region_filter) && input$region_filter != "All") {
      data <- data %>% filter(region == input$region_filter)
    }
    if (!is.null(input$status_filter) && input$status_filter != "All") {
      data <- data %>% filter(status == input$status_filter)
    }
    if (!is.null(input$urgency_filter) && input$urgency_filter != "All") {
      data <- data %>% filter(urgency == input$urgency_filter)
    }
    data
  })

  output$total_count <- renderText({
    tryCatch(nrow(filtered_data()), error = function(e) 0)
  })

  output$open_count <- renderText({
    tryCatch(filtered_data() %>% filter(status != "Resolved") %>% nrow(), error = function(e) 0)
  })

  output$urgent_count <- renderText({
    tryCatch(filtered_data() %>% filter(urgency == "High") %>% nrow(), error = function(e) 0)
  })

  output$safety_count <- renderText({
    tryCatch({
      data <- filtered_data()
      if (!"safety_flag" %in% names(data)) return(0)
      data %>% filter(safety_flag == "Yes") %>% nrow()
    }, error = function(e) 0)
  })

  output$region_plot <- renderEcharts4r({
    req(nrow(filtered_data()) > 0)
    filtered_data() %>%
      count(region) %>%
      arrange(desc(n)) %>%
      e_charts(region) %>%
      e_bar(n, name = "Count") %>%
      e_title("Tickets by Region") %>%
      e_tooltip(trigger = "axis") %>%
      e_legend(show = FALSE)
  })

  output$status_plot <- renderEcharts4r({
    req(nrow(filtered_data()) > 0)
    filtered_data() %>%
      count(status) %>%
      e_charts(status) %>%
      e_bar(n, name = "Count") %>%
      e_title("Tickets by Status") %>%
      e_tooltip(trigger = "axis") %>%
      e_legend(show = FALSE)
  })

  output$ticket_table <- renderDT({
    req(nrow(filtered_data()) >= 0)
    data <- filtered_data() %>% arrange(desc(created_at))

    display_cols <- intersect(
      c("ticket_id", "name", "phone", "email", "region", "time_window",
        "status", "urgency", "safety_flag", "technician", "description",
        "urgency_reason", "created_at"),
      names(data)
    )
    data <- data[, display_cols]

    dt <- datatable(
      data,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        autoWidth = TRUE,
        dom = "lfrtip"
      ),
      rownames = FALSE,
      class = "cell-border stripe nowrap compact"
    )

    if ("urgency" %in% names(data)) {
      dt <- dt %>% formatStyle(
        "urgency",
        backgroundColor = styleEqual(
          c("Low", "Medium", "High"),
          c("#dcfce7", "#fef9c3", "#fee2e2")
        ),
        fontWeight = "bold"
      )
    }

    if ("safety_flag" %in% names(data)) {
      dt <- dt %>% formatStyle(
        "safety_flag",
        target = "row",
        backgroundColor = styleEqual("Yes", "#fef2f2")
      )
    }

    dt
  })
}
