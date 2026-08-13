# Technician dashboard UI

technician_dashboard_ui <- function(technician) {
  tagList(
    tags$div(class = "dashboard-shell tech-dashboard-shell",
      tags$div(class = "sidebar-backdrop"),
      tags$div(class = "custom-sidebar tech-sidebar",
        tags$div(class = "sidebar-brand",
          tags$h3(bs_icon("tools"), " Field Portal"),
          tags$p(paste("Signed in as", technician$name))
        ),
        tags$div(class = "nav-header", "WORKSPACE"),
        tags$div(class = "nav-item active", bs_icon("speedometer2"), " Dashboard"),
        tags$div(class = "nav-item", bs_icon("list-task"), " Assignments"),
        tags$div(class = "nav-item", bs_icon("person-gear"), " Profile"),
        tags$br(),
        tags$div(class = "nav-header", "STATUS"),
        tags$div(class = "nav-item tech-live-pill", bs_icon("broadcast"), " Live sync active")
      ),

      tags$div(class = "main-content tech-dashboard",
        tags$div(class = "header-title",
          tags$div(class = "header-title-left",
            tags$button(
              id = "dashboard_menu_btn", type = "button",
              class = "dashboard-menu-btn mobile-menu-btn action-button",
              bs_icon("list"), title = "Toggle sidebar"
            ),
            tags$h2(paste("Welcome,", technician$name))
          ),
          tags$div(class = "header-title-actions tech-header-actions",
            tags$button(id = "notif_bell", class = "tech-notif-btn action-button",
              bs_icon("bell-fill"),
              tags$span(textOutput("notif_badge", inline = TRUE), class = "tech-notif-count")
            ),
            tags$div(class = "admin-profile-container",
              tags$div(class = "admin-profile-trigger",
                tags$div(class = "admin-avatar-small tech-avatar-initial",
                  tolower(substr(technician$name, 1, 1))
                ),
                tags$div(class = "admin-info",
                  tags$p(class = "admin-name", technician$name),
                  tags$p(class = "admin-role", "Field Technician")
                ),
                bs_icon("chevron-down", class = "trigger-icon")
              ),
              tags$div(class = "admin-profile-dropdown",
                tags$div(class = "dropdown-header",
                  tags$div(class = "dropdown-avatar-wrapper",
                    tags$div(class = "dropdown-avatar-initial tech-avatar-initial",
                      tolower(substr(technician$name, 1, 1))
                    ),
                    tags$div(class = "status-dot")
                  ),
                  tags$p(class = "dropdown-name", technician$name)
                ),
                tags$ul(class = "dropdown-menu-list",
                  tags$li(actionLink("tech_nav_assignments",
                    tagList(bs_icon("list-task", class = "dropdown-item-icon"), "My Assignments"),
                    class = "dropdown-link-item"
                  )),
                  tags$li(actionLink("tech_nav_profile",
                    tagList(bs_icon("person-gear", class = "dropdown-item-icon"), "Profile Settings"),
                    class = "dropdown-link-item"
                  )),
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

        uiOutput("tech_priority_alert"),

        tags$div(class = "tech-tabs",
          tabsetPanel(
            id = "tech_tabs",
            type = "tabs",
            tabPanel(
              title = tagList(bs_icon("speedometer2"), " Dashboard"),
              value = "dashboard",
              tags$div(class = "kpi-row tech-kpi-row",
                tags$div(class = "kpi-card primary",
                  tags$div(class = "kpi-title", "Assigned"),
                  tags$div(class = "kpi-value", textOutput("tech_total_count")),
                  tags$div(class = "kpi-icon", bs_icon("ticket-detailed"))
                ),
                tags$div(class = "kpi-card warning",
                  tags$div(class = "kpi-title", "New / Open"),
                  tags$div(class = "kpi-value", textOutput("tech_open_count")),
                  tags$div(class = "kpi-icon", bs_icon("envelope-open"))
                ),
                tags$div(class = "kpi-card info",
                  tags$div(class = "kpi-title", "In Progress"),
                  tags$div(class = "kpi-value", textOutput("tech_progress_count")),
                  tags$div(class = "kpi-icon", bs_icon("gear-wide-connected"))
                ),
                tags$div(class = "kpi-card danger",
                  tags$div(class = "kpi-title", "High Urgency"),
                  tags$div(class = "kpi-value", textOutput("tech_urgent_count")),
                  tags$div(class = "kpi-icon", bs_icon("exclamation-triangle"))
                )
              ),
              tags$div(class = "dashboard-chart-row",
                tags$div(class = "chart-container",
                  tags$h4(class = "tech-panel-title", bs_icon("pie-chart"), " Ticket Status"),
                  uiOutput("tech_status_chart")
                ),
                tags$div(class = "chart-container",
                  tags$h4(class = "tech-panel-title", bs_icon("bar-chart"), " By Region"),
                  uiOutput("tech_region_chart")
                )
              ),
              tags$div(class = "data-table-container tech-activity-panel",
                tags$h4(class = "tech-panel-title", bs_icon("clock-history"), " Recent Activity"),
                uiOutput("tech_recent_activity")
              )
            ),
            tabPanel(
              title = tagList(bs_icon("list-task"), " Assignments"),
              value = "assignments",
              tags$div(class = "filter-row",
                selectInput("tech_status_filter", "Status:", choices = c("All", statuses), selected = "All"),
                selectInput("tech_urgency_filter", "Urgency:", choices = c("All", urgencies), selected = "All")
              ),
              tags$div(class = "data-table-container",
                tags$h4(class = "tech-panel-title", bs_icon("list-task"), " My Assigned Tickets"),
                tags$p(class = "settings-desc",
                  bs_icon("envelope-open"), " View-only list. To change status, use the update link in your assignment email."
                ),
                uiOutput("tech_ticket_list")
              )
            ),
            tabPanel(
              title = tagList(bs_icon("person-gear"), " Profile"),
              value = "profile",
              tags$div(class = "profile-settings-grid",
                tags$div(class = "settings-card",
                  tags$div(class = "settings-card-header",
                    tags$div(class = "settings-icon-box", bs_icon("person-vcard")),
                    tags$h4("Personal Information")
                  ),
                  tags$p(class = "settings-desc", "Update your contact details so dispatchers and automated systems can reach you in the field."),
                  tags$div(class = "form-group-custom", style = "margin-top: 24px;",
                    tags$label("Email Address"),
                    tags$div(class = "input-with-icon",
                      bs_icon("envelope"),
                      textInput("profile_email", label = NULL, value = technician$email)
                    )
                  ),
                  tags$div(class = "form-group-custom",
                    tags$label("Phone Number"),
                    tags$div(class = "input-with-icon",
                      bs_icon("telephone"),
                      textInput("profile_phone", label = NULL, value = ifelse(is.na(technician$phone), "", technician$phone))
                    )
                  ),
                  tags$button(id = "save_profile_btn", type = "button",
                    class = "btn btn-submit-custom action-button btn-reg-inline",
                    bs_icon("check2-circle"), " Save Changes"
                  ),
                  uiOutput("profile_save_message", style = "margin-top: 16px;")
                ),
                tags$div(class = "settings-card",
                  tags$div(class = "settings-card-header",
                    tags$div(class = "settings-icon-box", bs_icon("shield-lock")),
                    tags$h4("Security Settings")
                  ),
                  tags$p(class = "settings-desc", "Ensure your account is protected. We recommend using a strong password with symbols and numbers."),
                  tags$div(class = "form-group-custom", style = "margin-top: 24px;",
                    tags$label("Current Password"),
                    tags$div(class = "input-with-icon",
                      bs_icon("key"),
                      passwordInput("current_password", label = NULL, placeholder = "Enter current password")
                    )
                  ),
                  tags$div(class = "form-group-custom",
                    tags$label("New Password"),
                    tags$div(class = "input-with-icon",
                      bs_icon("lock"),
                      passwordInput("profile_new_password", label = NULL, placeholder = "Enter new password")
                    )
                  ),
                  tags$div(class = "form-group-custom",
                    tags$label("Confirm New Password"),
                    tags$div(class = "input-with-icon",
                      bs_icon("shield-check"),
                      passwordInput("profile_confirm_password", label = NULL, placeholder = "Confirm new password")
                    )
                  ),
                  tags$button(id = "save_password_btn", type = "button",
                    class = "btn btn-submit-custom action-button btn-reg-inline btn-reg-dark",
                    bs_icon("shield-lock"), " Update Password"
                  ),
                  uiOutput("password_save_message", style = "margin-top: 16px;")
                )
              )
            )
          )
        )
      )
    )
  )
}
