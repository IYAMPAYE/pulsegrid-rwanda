# Technician dashboard UI

technician_dashboard_ui <- function(technician) {
  tagList(
    tags$div(class = "dashboard-shell",
      tags$div(class = "main-content tech-dashboard",

             tags$div(class = "header-title",
                      tags$h2(paste("Welcome,", technician$name)),
                      tags$div(class = "tech-header-actions",
                        tags$button(id = "notif_bell", class = "tech-notif-btn action-button",
                          bs_icon("bell-fill", style = "font-size: 18px;"),
                          tags$span(textOutput("notif_badge", inline = TRUE),
                            style = "position: absolute; top: -4px; right: -4px; background: #ef4444; color: white; border-radius: 12px; padding: 2px 6px; font-size: 11px; font-weight: 700; border: 2px solid white; box-shadow: 0 2px 4px rgba(239, 68, 68, 0.3);")
                        ),

                        tags$div(class = "admin-profile-container",
                                 tags$div(class = "admin-profile-trigger",
                                          tags$div(class = "admin-avatar-small", style = "width: 42px; height: 42px; border-radius: 50%; background-color: #3b82f6; color: white; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 18px; font-family: 'Inter', sans-serif; box-shadow: 0 2px 5px rgba(0,0,0,0.1);",
                                            tolower(substr(technician$name, 1, 1))),
                                          tags$div(class = "admin-info",
                                                   tags$p(class = "admin-name", technician$name),
                                                   tags$p(class = "admin-role", "Field Technician")
                                          ),
                                          bs_icon("chevron-down", class = "trigger-icon")
                                 ),
                                 tags$div(class = "admin-profile-dropdown",
                                          tags$div(class = "dropdown-header",
                                                   tags$div(class = "dropdown-avatar-wrapper",
                                                            tags$div(class = "dropdown-avatar-initial", style="background-color: #3b82f6;", tolower(substr(technician$name, 1, 1))),
                                                            tags$div(class = "status-dot")
                                                   ),
                                                   tags$p(class = "dropdown-name", technician$name)
                                          ),
                                          tags$ul(class = "dropdown-menu-list",
                                                  tags$li(tags$a(href = "#", "My Assignments")),
                                                  tags$li(tags$a(href = "#", "Field Tools")),
                                                  tags$hr(class = "dropdown-divider"),
                                                  tags$li(
                                                    tags$button(id = "logout_btn", class = "dropdown-signout action-button", "Sign Out")
                                                  )
                                          )
                                 )
                        )
                      )
             ),
             tags$div(class = "header-subtitle", "Your assigned tickets, at a glance"),

             tags$div(class = "tech-tabs",
               tabsetPanel(
                 id = "tech_tabs",
                 type = "tabs",
                 tabPanel("Dashboard",
                        tags$div(class = "dashboard-chart-row",
                          tags$div(class = "chart-container", style = "margin-top: 20px;",
                                   tags$h4("Ticket Status", style = "font-weight:bold;"),
                                   echarts4rOutput("tech_status_donut", height = "280px")
                          ),
                          tags$div(class = "chart-container", style = "margin-top: 20px;",
                                   tags$h4("Recent Activity", style = "font-weight:bold;"),
                                   uiOutput("tech_recent_activity")
                          )
                        )
                 ),
                 tabPanel("Profile",
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
                                          tags$button(id = "save_profile_btn", type = "button", class = "btn btn-submit-custom action-button", style = "width: auto; padding: 0 32px;",
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
                                          tags$button(id = "save_password_btn", type = "button", class = "btn btn-submit-custom action-button", style = "width: auto; padding: 0 32px; background-color: #0f172a;",
                                                      bs_icon("shield-lock"), " Update Password"
                                          ),
                                          uiOutput("password_save_message", style = "margin-top: 16px;")
                                 )
                        )
                 )
               )
             )
      ),
      )
  )
}
