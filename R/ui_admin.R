# Admin dashboard UI

admin_overview_panel <- function() {
  tagList(
    tags$div(class = "filter-row admin-filter-row",
      selectInput("region_filter", "Region:", choices = c("All", regions), selected = "All"),
      selectInput("status_filter", "Status:", choices = c("All", statuses), selected = "All"),
      selectInput("urgency_filter", "Urgency:", choices = c("All", urgencies), selected = "All")
    ),

    tags$div(class = "kpi-row admin-kpi-row",
      tags$div(class = "kpi-card primary",
        tags$div(class = "kpi-title", "Total Tickets"),
        tags$div(class = "kpi-value", textOutput("total_count")),
        tags$div(class = "kpi-icon", bs_icon("ticket-detailed"))
      ),
      tags$div(class = "kpi-card warning",
        tags$div(class = "kpi-title", "Open Tickets"),
        tags$div(class = "kpi-value", textOutput("open_count")),
        tags$div(class = "kpi-icon", bs_icon("envelope-open"))
      ),
      tags$div(class = "kpi-card info",
        tags$div(class = "kpi-title", "In Progress"),
        tags$div(class = "kpi-value", textOutput("progress_count")),
        tags$div(class = "kpi-icon", bs_icon("gear-wide-connected"))
      ),
      tags$div(class = "kpi-card danger",
        tags$div(class = "kpi-title", "High Urgency"),
        tags$div(class = "kpi-value", textOutput("urgent_count")),
        tags$div(class = "kpi-icon", bs_icon("exclamation-triangle"))
      ),
      tags$div(class = "kpi-card critical",
        tags$div(class = "kpi-title", "Safety Flags"),
        tags$div(class = "kpi-value", textOutput("safety_count")),
        tags$div(class = "kpi-icon", bs_icon("shield-exclamation"))
      )
    ),

    tags$div(class = "dashboard-chart-row admin-chart-row",
      tags$div(class = "chart-container",
        tags$h4(class = "tech-panel-title", bs_icon("bar-chart-fill"), " Tickets by Region"),
        uiOutput("admin_region_chart")
      ),
      tags$div(class = "chart-container",
        tags$h4(class = "tech-panel-title", bs_icon("pie-chart"), " Ticket Status"),
        uiOutput("admin_status_chart")
      )
    ),

    tags$div(class = "data-table-container",
      tags$h4(class = "tech-panel-title", bs_icon("table"), " All Tickets"),
      DTOutput("ticket_table")
    )
  )
}

admin_operations_panel <- function() {
  tagList(
    tags$div(class = "admin-ops-shell",

      tags$div(class = "admin-ops-topbar",
        tags$div(class = "admin-ops-topbar-main",
          tags$span(class = "admin-ops-topbar-label", bs_icon("funnel"), "Filters"),
          tags$div(class = "admin-ops-topbar-filters",
            selectInput(
              "ops_date_filter", "Date range",
              choices = c("All time", "Today", "Last 7 days", "Last 30 days"),
              selected = "Last 30 days"
            ),
            selectInput(
              "ops_region_filter", "Region",
              choices = c("All", regions), selected = "All"
            ),
            selectInput(
              "ops_status_filter", "Status",
              choices = c("All", statuses), selected = "All"
            )
          )
        ),
        tags$div(class = "admin-ops-topbar-meta",
          bs_icon("arrow-repeat"),
          tags$span("Live data · refreshes every 30s")
        )
      ),

      tags$div(class = "kpi-row admin-ops-kpi-row",
        tags$div(class = "kpi-card primary admin-ops-kpi",
          tags$div(class = "kpi-icon", bs_icon("diagram-3")),
          tags$div(class = "kpi-body",
            tags$div(class = "kpi-title", "Assigned tickets"),
            tags$div(class = "kpi-value", textOutput("ops_assigned_count"))
          )
        ),
        tags$div(class = "kpi-card warning admin-ops-kpi",
          tags$div(class = "kpi-icon", bs_icon("inbox")),
          tags$div(class = "kpi-body",
            tags$div(class = "kpi-title", "Needs assignment"),
            tags$div(class = "kpi-value", textOutput("ops_unassigned_count"))
          )
        ),
        tags$div(class = "kpi-card info admin-ops-kpi",
          tags$div(class = "kpi-icon", bs_icon("people")),
          tags$div(class = "kpi-body",
            tags$div(class = "kpi-title", "Active technicians"),
            tags$div(class = "kpi-value", textOutput("ops_technician_count"))
          )
        )
      ),

      tags$div(class = "admin-ops-workspace admin-ops-tabs tech-tabs",
        tabsetPanel(
          id = "ops_tabs",
          type = "tabs",
          selected = "assignments",

          tabPanel(
            title = tagList(bs_icon("diagram-3"), " Assignments"),
            value = "assignments",
            tags$div(class = "admin-ops-panel",
              tags$div(class = "admin-ops-panel-header",
                tags$div(class = "admin-ops-panel-heading",
                  tags$h3(class = "admin-ops-panel-title", "Assigned ticket queue"),
                  tags$p(class = "admin-ops-panel-desc",
                    "All routed tickets grouped by technician. Status updates are handled via the n8n email form.")
                ),
                tags$div(class = "admin-ops-panel-badge",
                  textOutput("ops_assignments_summary", inline = TRUE)
                )
              ),
              tags$div(class = "admin-ops-card admin-ops-card-table",
                tags$div(class = "admin-ops-card-body admin-ops-table-wrap",
                  DTOutput("ops_assignments_table")
                )
              )
            )
          ),

          tabPanel(
            title = tagList(bs_icon("inbox"), " Unassigned"),
            value = "unassigned",
            tags$div(class = "admin-ops-panel",
              tags$div(class = "admin-ops-panel-header",
                tags$div(class = "admin-ops-panel-heading",
                  tags$h3(class = "admin-ops-panel-title", "Assignment desk"),
                  tags$p(class = "admin-ops-panel-desc",
                    "Assign new reports to a technician or reassign open tickets manually.")
                ),
                tags$div(class = "admin-ops-panel-badge admin-ops-panel-badge-warn",
                  textOutput("ops_unassigned_summary", inline = TRUE)
                )
              ),
              uiOutput("ops_reassign_panel"),
              tags$div(class = "admin-ops-card admin-ops-card-table",
                tags$div(class = "admin-ops-card-head",
                  bs_icon("list-ul"),
                  tags$span("Unassigned ticket queue")
                ),
                tags$div(class = "admin-ops-card-body admin-ops-table-wrap",
                  DTOutput("ops_unassigned_table")
                )
              )
            )
          )
        )
      )
    )
  )
}

admin_team_modal_body <- function() {
  tagList(
    tags$div(class = "admin-team-modal",
      tags$div(class = "admin-team-modal-header",
        tags$h3(tagList(bs_icon("people-fill"), " Team Configuration")),
        tags$p("Manage technician accounts, assigned regions, and n8n auto-routing.")
      ),
      tags$div(class = "admin-team-modal-toolbar",
        actionButton(
          "ops_add_technician_btn",
          tagList(bs_icon("person-plus"), " Add technician"),
          class = "btn btn-primary btn-submit-custom admin-team-add-btn"
        )
      ),
      tags$div(class = "admin-ops-card admin-ops-card-table",
        tags$div(class = "admin-ops-card-head",
          bs_icon("table"),
          tags$span("Technician roster"),
          tags$span(class = "admin-ops-card-head-hint", "Click a row to edit")
        ),
        tags$div(class = "admin-ops-card-body admin-ops-table-wrap",
          DTOutput("ops_technician_table")
        )
      ),
      tags$div(class = "admin-ops-card admin-ops-card-edit",
        tags$div(class = "admin-ops-card-head",
          bs_icon("pencil-square"),
          tags$span("Edit technician")
        ),
        tags$div(class = "admin-ops-card-body admin-ops-manage-body",
          selectInput(
            "ops_manage_technician_id",
            "Technician",
            choices = c("— Select from roster above —" = ""),
            width = "100%"
          ),
          uiOutput("ops_technician_edit_form")
        )
      ),
      tags$div(class = "admin-team-modal-footer",
        modalButton("Close")
      )
    )
  )
}

admin_coming_soon_panel <- function(title, description, icon_name) {
  tags$div(class = "admin-coming-soon",
    tags$div(class = "admin-coming-soon-icon", bs_icon(icon_name)),
    tags$h3(title),
    tags$p(description)
  )
}

admin_analytics_panel <- function() {
  tagList(
    tags$div(class = "admin-analytics-shell",
      tags$div(class = "admin-ops-topbar",
        tags$div(class = "admin-ops-topbar-main",
          tags$span(class = "admin-ops-topbar-label", bs_icon("funnel"), "Report period"),
          tags$div(class = "admin-ops-topbar-filters",
            selectInput(
              "analytics_date_filter", "Date range",
              choices = c("Last 7 days", "Last 30 days", "Last 90 days", "All time"),
              selected = "Last 30 days"
            ),
            selectInput(
              "analytics_region_filter", "Region",
              choices = c("All", regions), selected = "All"
            )
          )
        ),
        tags$div(class = "admin-ops-topbar-meta",
          bs_icon("bar-chart-line"),
          tags$span("Trends & regional comparisons")
        )
      ),

      tags$div(class = "kpi-row admin-analytics-kpi-row",
        tags$div(class = "kpi-card primary admin-ops-kpi",
          tags$div(class = "kpi-icon", bs_icon("ticket-detailed")),
          tags$div(class = "kpi-body",
            tags$div(class = "kpi-title", "Total reports"),
            tags$div(class = "kpi-value", textOutput("analytics_total_count"))
          )
        ),
        tags$div(class = "kpi-card info admin-ops-kpi",
          tags$div(class = "kpi-icon", bs_icon("calendar3")),
          tags$div(class = "kpi-body",
            tags$div(class = "kpi-title", "Avg per day"),
            tags$div(class = "kpi-value", textOutput("analytics_avg_daily"))
          )
        ),
        tags$div(class = "kpi-card primary admin-ops-kpi",
          tags$div(class = "kpi-icon", bs_icon("check-circle")),
          tags$div(class = "kpi-body",
            tags$div(class = "kpi-title", "Resolved rate"),
            tags$div(class = "kpi-value", textOutput("analytics_resolved_rate"))
          )
        ),
        tags$div(class = "kpi-card danger admin-ops-kpi",
          tags$div(class = "kpi-icon", bs_icon("exclamation-triangle")),
          tags$div(class = "kpi-body",
            tags$div(class = "kpi-title", "High urgency"),
            tags$div(class = "kpi-value", textOutput("analytics_high_urgency_count"))
          )
        )
      ),

      tags$div(class = "dashboard-chart-row admin-analytics-chart-row",
        tags$div(class = "chart-container admin-analytics-chart-wide",
          tags$h4(class = "tech-panel-title", bs_icon("graph-up"), " Daily ticket volume"),
          uiOutput("analytics_daily_chart")
        ),
        tags$div(class = "chart-container",
          tags$h4(class = "tech-panel-title", bs_icon("bar-chart-fill"), " Regional comparison"),
          uiOutput("analytics_region_chart")
        )
      ),

      tags$div(class = "dashboard-chart-row admin-analytics-chart-row",
        tags$div(class = "chart-container",
          tags$h4(class = "tech-panel-title", bs_icon("pie-chart"), " Status mix"),
          uiOutput("analytics_status_chart")
        ),
        tags$div(class = "chart-container",
          tags$h4(class = "tech-panel-title", bs_icon("speedometer2"), " Urgency mix"),
          uiOutput("analytics_urgency_chart")
        )
      ),

      tags$div(class = "admin-ops-card admin-ops-card-table",
        tags$div(class = "admin-ops-card-head",
          bs_icon("table"),
          tags$span("Regional summary")
        ),
        tags$div(class = "admin-ops-card-body admin-ops-table-wrap",
          DTOutput("analytics_region_table")
        )
      )
    )
  )
}

admin_dashboard_ui <- function(admin_name) {
  tagList(
    tags$div(class = "dashboard-shell admin-dashboard-shell",
      tags$div(class = "sidebar-backdrop"),
      tags$div(class = "custom-sidebar admin-sidebar",
        tags$div(class = "sidebar-brand",
          tags$h3(bs_icon("graph-up-arrow"), " PulseGrid"),
          tags$p(paste("Signed in as", admin_name))
        ),
        tags$div(class = "nav-header", "ADMIN PORTAL"),
        actionLink(
          "admin_nav_overview",
          tagList(bs_icon("speedometer2"), " Overview"),
          class = "nav-item admin-nav-link active"
        ),
        actionLink(
          "admin_nav_operations",
          tagList(bs_icon("lightning-fill"), " Operations"),
          class = "nav-item admin-nav-link"
        ),
        actionLink(
          "admin_nav_analytics",
          tagList(bs_icon("bar-chart-line-fill"), " Analytics"),
          class = "nav-item admin-nav-link"
        ),
        actionLink(
          "admin_nav_gis",
          tagList(bs_icon("geo-alt-fill"), " GIS Portal"),
          class = "nav-item admin-nav-link"
        ),
        tags$br(),
        tags$div(class = "nav-header", "DATA SOURCE"),
        tags$div(class = "nav-item nav-item-muted tech-live-pill",
          bs_icon("broadcast"), " Live sync active"
        )
      ),

      tags$div(class = "main-content admin-dashboard",
        tags$div(class = "header-title",
          tags$div(class = "header-title-left",
            tags$button(
              id = "dashboard_menu_btn", type = "button",
              class = "dashboard-menu-btn mobile-menu-btn action-button",
              bs_icon("list"), title = "Toggle sidebar"
            ),
            tags$h2(textOutput("admin_page_title", inline = TRUE))
          ),
          tags$div(class = "header-title-actions admin-header-actions",
            tags$div(class = "admin-sync-pill",
              bs_icon("arrow-repeat"), " Updates every 30s"
            ),
            tags$div(class = "admin-profile-container",
              tags$div(class = "admin-profile-trigger",
                tags$img(src = "admin_profile.jpg", class = "admin-avatar-small", alt = "Admin"),
                tags$div(class = "admin-info",
                  tags$p(class = "admin-name", admin_name),
                  tags$p(class = "admin-role", "Super Administrator")
                ),
                bs_icon("chevron-down", class = "trigger-icon")
              ),
              tags$div(class = "admin-profile-dropdown",
                tags$div(class = "dropdown-header",
                  tags$div(class = "dropdown-avatar-wrapper",
                    tags$div(class = "dropdown-avatar-initial", tolower(substr(admin_name, 1, 1))),
                    tags$div(class = "status-dot")
                  ),
                  tags$p(class = "dropdown-name", admin_name)
                ),
                tags$ul(class = "dropdown-menu-list",
                  tags$li(
                    actionLink(
                      "admin_nav_team",
                      tagList(bs_icon("people-fill", class = "dropdown-item-icon"), "Team Configuration"),
                      class = "dropdown-link-item"
                    )
                  ),
                  tags$hr(class = "dropdown-divider"),
                  tags$li(
                    tags$button(id = "logout_btn", class = "dropdown-signout action-button",
                      tagList(bs_icon("box-arrow-right", class = "dropdown-item-icon"), "Sign Out")
                    )
                  )
                )
              )
            )
          )
        ),

        tags$div(class = "admin-sections",
          tabsetPanel(
            id = "admin_tabs",
            type = "hidden",
            tabPanel(title = "Overview", value = "overview", admin_overview_panel()),
            tabPanel(title = "Operations", value = "operations", admin_operations_panel()),
            tabPanel(title = "Analytics", value = "analytics", admin_analytics_panel()),
            tabPanel(
              title = "GIS", value = "gis",
              admin_coming_soon_panel(
                "GIS Portal",
                "Regional outage mapping and field tracking — coming in Phase 4.",
                "geo-alt-fill"
              )
            )
          )
        )
      )
    )
  )
}
