# Admin dashboard UI

admin_dashboard_ui <- function(admin_name) {
  tagList(
    tags$div(class = "dashboard-shell",
      tags$div(class = "sidebar-backdrop"),
      tags$div(class = "custom-sidebar",
             tags$div(class = "sidebar-brand",
                      tags$h3(bs_icon("graph-up-arrow"), " PulseGrid"),
                      tags$p(paste("Signed in as", admin_name))
             ),
             tags$div(class = "nav-header", "NAVIGATION"),
             tags$div(class = "nav-item active", bs_icon("pie-chart-fill"), " Overview"),
             tags$div(class = "nav-item", bs_icon("people-fill"), " Personnel"),
             tags$div(class = "nav-item", bs_icon("lightning-fill"), " Operations"),
             tags$div(class = "nav-item", bs_icon("building"), " Infrastructure"),
             tags$br(),
             tags$div(class = "nav-header", "DATA SOURCE"),
             tags$div(class = "nav-item", style = "color:#64748b;", bs_icon("database"), " Supabase (Postgres)")
    ),

    tags$div(class = "main-content",
             tags$div(class = "header-title",
                      tags$button(
                        id = "dashboard_menu_btn", type = "button",
                        class = "mobile-menu-btn action-button",
                        HTML("&#9776;")
                      ),
                      tags$h2("Overview Dashboard"),
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
                                                tags$li(tags$a(href = "#", "Project Briefs")),
                                                tags$li(tags$a(href = "#", "Settings")),
                                                tags$hr(class = "dropdown-divider"),
                                                tags$li(
                                                  tags$button(id = "logout_btn", class = "dropdown-signout action-button", "Sign Out")
                                                )
                                        )
                               )
                      )
             ),
             tags$div(class = "header-subtitle", "Rwanda Regional Tickets • Live Data • Supabase"),

             tags$div(class = "filter-row",
                      selectInput("region_filter", "Region:", choices = c("All", regions), selected = "All"),
                      selectInput("status_filter", "Status:", choices = c("All", statuses), selected = "All"),
                      selectInput("urgency_filter", "Urgency:", choices = c("All", urgencies), selected = "All")
             ),

             tags$div(class = "kpi-row",
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

             tags$div(class = "dashboard-chart-row",
                      tags$div(class = "chart-container", echarts4rOutput("region_plot", height = "280px")),
                      tags$div(class = "chart-container", echarts4rOutput("status_plot", height = "280px"))
             ),

             tags$div(class = "data-table-container",
                      tags$h4("All Tickets", style = "font-weight:bold; margin-bottom: 20px; color: #0f172a;"),
                      DTOutput("ticket_table")
             )
    ),
    )
  )
}
