# Login and password-change UI

login_ui <- function(error_message = NULL) {
  tags$div(class = "auth-wrapper",
           tags$div(class = "landing-container",
                    tags$div(class = "landing-hero",
                             tags$div(
                               tags$div(class = "landing-badge",
                                        bs_icon("activity"), " Live Incident & Grid Monitor"
                               ),
                               tags$div(class = "landing-brand",
                                        bs_icon("lightning-charge-fill"), " PulseGrid"
                               ),
                               tags$div(class = "landing-title", "Empowering Rapid Utility & Grid Response"),
                               tags$div(class = "landing-desc",
                                        "Unified ticket tracking, regional incident dispatching, and field operations management across Rwanda."
                               ),
                               tags$div(class = "feature-list",
                                        tags$div(class = "feature-item",
                                                 tags$div(class = "feature-icon-box", bs_icon("geo-alt-fill")),
                                                 tags$div(class = "feature-text",
                                                          tags$h5("Regional Incident Mapping"),
                                                          tags$p("Instant outage metrics for Kigali, Huye, Musanze, Rubavu & Nyagatare.")
                                                 )
                                        ),
                                        tags$div(class = "feature-item",
                                                 tags$div(class = "feature-icon-box", bs_icon("tools")),
                                                 tags$div(class = "feature-text",
                                                          tags$h5("Technician Field Portal"),
                                                          tags$p("Direct ticket assignments, immediate status updates, and priority queues.")
                                                 )
                                        ),
                                        tags$div(class = "feature-item",
                                                 tags$div(class = "feature-icon-box", bs_icon("database-check")),
                                                 tags$div(class = "feature-text",
                                                          tags$h5("Supabase Live Sync"),
                                                          tags$p("High reliability data persistence backed by Postgres encryption.")
                                                 )
                                        )
                               )
                             ),
                             tags$div(class = "hero-footer",
                                      bs_icon("shield-lock-fill"), " Secured Enterprise Auth • PulseGrid Operations v2.0"
                             )
                    ),
                    tags$div(class = "landing-auth-card",
                             tags$div(class = "auth-card-header",
                                      tags$h3("Account Access"),
                                      tags$p("Sign in with your operational credentials")
                             ),
                             tags$div(class = "form-group-custom",
                                      tags$label("Email Address"),
                                      tags$div(class = "input-with-icon",
                                               bs_icon("envelope-fill"),
                                               textInput("login_email", label = NULL, placeholder = "name@pulsegrid.rw")
                                      )
                             ),
                             tags$div(class = "form-group-custom",
                                      tags$label("Password"),
                                      tags$div(class = "input-with-icon",
                                               bs_icon("lock-fill"),
                                               passwordInput("login_password", label = NULL, placeholder = "••••••••")
                                      )
                             ),
                             tags$button(id = "login_btn", type = "button", class = "btn btn-submit-custom action-button",
                                         bs_icon("box-arrow-in-right"), " Sign In to Portal"
                             ),
                             if (!is.null(error_message)) {
                               tags$div(class = "auth-error",
                                        bs_icon("exclamation-circle-fill"), error_message
                               )
                             },
                             tags$div(class = "role-hint-box",
                                      tags$div(bs_icon("info-circle-fill"), style = "display: inline; margin-right: 5px; color: #0284c7;"),
                                      tags$strong("Access Note: "), "Administrators view full region ops. Field technicians access personal assignment queues."
                             )
                    )
           )
  )
}

change_password_ui <- function(error_message = NULL) {
  tags$div(class = "auth-wrapper",
           tags$div(class = "landing-container", style = "max-width: 480px;",
                    tags$div(class = "landing-auth-card", style = "border-radius: 20px; width: 100%;",
                             tags$div(class = "auth-card-header",
                                      tags$h3(bs_icon("key-fill"), " First Login Security"),
                                      tags$p("Set your permanent password to continue.")
                             ),
                             tags$div(class = "form-group-custom",
                                      tags$label("New Password"),
                                      tags$div(class = "input-with-icon",
                                               bs_icon("lock-fill"),
                                               passwordInput("new_password", label = NULL, placeholder = "Enter new password")
                                      )
                             ),
                             tags$div(class = "form-group-custom",
                                      tags$label("Confirm New Password"),
                                      tags$div(class = "input-with-icon",
                                               bs_icon("shield-check"),
                                               passwordInput("confirm_password", label = NULL, placeholder = "Confirm new password")
                                      )
                             ),
                             tags$button(id = "change_password_btn", type = "button", class = "btn btn-submit-custom action-button",
                                         bs_icon("check-lg"), " Save & Access Dashboard"
                             ),
                             if (!is.null(error_message)) {
                               tags$div(class = "auth-error",
                                        bs_icon("exclamation-circle-fill"), error_message
                               )
                             }
                    )
           )
  )
}
