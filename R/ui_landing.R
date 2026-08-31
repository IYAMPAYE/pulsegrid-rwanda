# Landing page UI

reg_landing_ui <- function() {
  tagList(
    # Header App Bar
    tags$header(class = "reg-header",
      tags$div(class = "reg-brand",
        tags$img(src = "download.png", alt = "REG Logo", class = "reg-brand-logo")
      ),
      tags$nav(class = "reg-nav",
        tags$a(class = "reg-nav-link active", href = "#", "Home"),
        tags$a(class = "reg-nav-link", href = "#features", "Features"),
        tags$a(class = "reg-nav-link", href = "#how-it-works", "How It Works")
      ),
      tags$div(class = "reg-header-actions",
        actionButton(
          "nav_login_btn",
          tagList(
            bs_icon("box-arrow-in-right"),
            tags$span(class = "reg-btn-text reg-btn-text-long", "Portal Login"),
            tags$span(class = "reg-btn-text reg-btn-text-short", "Login")
          ),
          class = "reg-btn-primary reg-header-btn",
          title = "Portal Login"
        ),
        tags$a(
          href = " https://utuje.app.n8n.cloud/form/0335b65f-8051-41dd-9b4f-ea18874c5f3b",
          target = "_blank",
          title = "Report Outage",
          tagList(
            bs_icon("lightning-fill"),
            tags$span(class = "reg-btn-text reg-btn-text-long", "Report Outage"),
            tags$span(class = "reg-btn-text reg-btn-text-short", "Report")
          ),
          class = "btn btn-outline-primary reg-btn-outline-header reg-header-btn"
        )
      )
    ),

    # Hero Section
    tags$section(class = "reg-hero",
      tags$div(class = "reg-hero-video-stack",
        tags$img(src = "hello.jpg", class = "reg-hero-poster", alt = ""),
        tags$video(
          id = "hero-vid-1",
          autoplay = NA, muted = NA, playsinline = NA, preload = "auto", poster = "hello.jpg",
          class = "reg-hero-video-bg",
          tags$source(src = "hello2.mp4", type = "video/mp4")
        ),
        tags$video(
          id = "hero-vid-2",
          muted = NA, playsinline = NA, preload = "auto", poster = "hello.jpg",
          class = "reg-hero-video-bg",
          tags$source(src = "Video.mp4", type = "video/mp4")
        )
      ),
      tags$div(class = "reg-hero-overlay"),
      tags$div(class = "reg-hero-content",
        tags$div(class = "reg-hero-body",
          tags$h1(class = "reg-hero-headline",
            tags$span(id = "figma-line-1", class = "figma-animated-word", "Power Problems?"), tags$br(),
            tags$span(id = "figma-line-2", class = "figma-animated-word", "Report Them Once."), tags$br(),
            tags$span(id = "figma-line-3", class = "figma-animated-word", "We'll Take It From Here.", style = "color: var(--reg-tertiary-fixed);")
          ),
          tags$p(class = "reg-hero-sub",
            "A faster, more reliable way to report electricity outages across Rwanda. Track ticket resolution status in real-time, straight from your device."
          ),
          tags$div(class = "reg-hero-actions",
            tags$a(
              href = "https://regrwanda.app.n8n.cloud/form/db35406c-9d56-4a55-81df-444072f2260d",
              target = "_blank",
              tagList(bs_icon("exclamation-triangle-fill"), "Report an Outage"),
              class = "reg-btn-accent", style = "text-decoration: none; display: inline-flex; align-items: center; justify-content: center;"
            ),
            actionButton("hero_login_btn", tagList(bs_icon("search"), "Track My Report / Login"), class = "reg-btn-outline-hero")
          )
        )
      )
    ),

    # Trust & Features Section
    tags$section(id = "features", class = "reg-trust-section",
      tags$div(class = "reg-trust-container",
        tags$div(class = "reg-grid-4",
          tags$div(class = "reg-card",
            tags$div(class = "reg-card-icon", bs_icon("file-earmark-text-fill")),
            tags$div(class = "reg-card-title", "Report Easily"),
            tags$p(class = "reg-card-desc", "Submit outage details quickly with instant region and sector tagging for precise location reporting.")
          ),
          tags$div(class = "reg-card",
            tags$div(class = "reg-card-icon", bs_icon("ticket-perforated-fill")),
            tags$div(class = "reg-card-title", "Automatic Ticketing"),
            tags$p(class = "reg-card-desc", "Every report generates a unique encrypted ticket ID instantly for your personal tracking records.")
          ),
          tags$div(class = "reg-card",
            tags$div(class = "reg-card-icon", bs_icon("lightning-fill")),
            tags$div(class = "reg-card-title", "Faster Response"),
            tags$p(class = "reg-card-desc", "Direct routing to localized Rwanda Energy Group technician teams ensures rapid dispatch times.")
          ),
          tags$div(class = "reg-card",
            tags$div(class = "reg-card-icon", bs_icon("bell-fill")),
            tags$div(class = "reg-card-title", "Stay Informed"),
            tags$p(class = "reg-card-desc", "Receive continuous status updates as field technicians work on restoring electrical service.")
          )
        )
      )
    ),

    # How It Works Section — Interactive n8n Workflow Graph
    tags$section(id = "how-it-works", class = "reg-how-section",
      tags$div(class = "reg-how-container",
        tags$div(class = "reg-section-header",
          tags$span(class = "reg-section-badge", "Seamless Operational Workflow")
        ),

        # Hub Animated Beam Node Layout (Clean Background without box container)
        tags$div(class = "reg-hub-beam-wrapper",
          
          # SVG Connection Beams Layer
          tags$div(class = "reg-hub-svg-layer",
            HTML('
              <svg class="reg-hub-svg" viewBox="0 0 1020 460" fill="none" xmlns="http://www.w3.org/2000/svg">
                <!-- Curved Track Beams connecting Intake & State to Center Hub and Outbound Nodes -->
                <path d="M 160 70 Q 320 70, 510 230" class="reg-hub-track" />
                <path d="M 130 230 L 510 230" class="reg-hub-track" />
                <path d="M 160 390 Q 320 390, 510 230" class="reg-hub-track" />

                <path d="M 510 230 Q 700 70, 860 70" class="reg-hub-track" />
                <path d="M 510 230 L 890 230" class="reg-hub-track" />
                <path d="M 510 230 Q 700 390, 860 390" class="reg-hub-track" />

                <!-- Animated Beam Beacons -->
                <path d="M 160 70 Q 320 70, 510 230" class="reg-hub-pulse hub-pulse-1" />
                <path d="M 130 230 L 510 230" class="reg-hub-pulse hub-pulse-2" />
                <path d="M 160 390 Q 320 390, 510 230" class="reg-hub-pulse hub-pulse-3" />

                <path d="M 510 230 Q 700 70, 860 70" class="reg-hub-pulse hub-pulse-4" />
                <path d="M 510 230 L 890 230" class="reg-hub-pulse hub-pulse-5" />
                <path d="M 510 230 Q 700 390, 860 390" class="reg-hub-pulse hub-pulse-6" />
              </svg>
            ')
          ),

          # Nodes Grid with actual n8n workflow nodes & styling
          tags$div(class = "reg-hub-nodes-grid",
            
            # Left Column Nodes (Intake & Field Inputs)
            tags$div(class = "reg-hub-col reg-hub-left",
              tags$div(class = "reg-hub-circle-node", title = "n8n Node: On Form Submission (Form Trigger)",
                tags$div(class = "reg-circle-icon reg-n8n-node-trigger", bs_icon("file-earmark-medical-fill")),
                tags$div(class = "reg-circle-label", "On form submission"),
                tags$span(class = "reg-node-tag", "Form Trigger")
              ),
              tags$div(class = "reg-hub-circle-node", title = "n8n Node: Edit Fields & Format Payload",
                tags$div(class = "reg-circle-icon reg-n8n-node-set", bs_icon("sliders")),
                tags$div(class = "reg-circle-label", "Edit Fields"),
                tags$span(class = "reg-node-tag", "Set Node")
              ),
              tags$div(class = "reg-hub-circle-node", title = "n8n Node: Schedule Trigger (Automated Polling)",
                tags$div(class = "reg-circle-icon reg-n8n-node-trigger", bs_icon("clock-fill")),
                tags$div(class = "reg-circle-label", "Schedule Trigger"),
                tags$span(class = "reg-node-tag", "Cron Job")
              )
            ),

            # Center Hub Node (n8n Urgency Scoring & Clustering Core)
            tags$div(class = "reg-hub-col reg-hub-center",
              tags$div(class = "reg-hub-circle-node reg-hub-main", title = "n8n Core Pipeline Hub: Urgency Scoring, Clustering & Routing",
                tags$div(class = "reg-circle-icon-main", bs_icon("diagram-3-fill")),
                tags$div(class = "reg-circle-main-label", "n8n Engine Hub"),
                tags$span(class = "reg-main-tag", "Clustering & Triage")
              )
            ),

            # Right Column Nodes (AI, DB & Email Notifications)
            tags$div(class = "reg-hub-col reg-hub-right",
              tags$div(class = "reg-hub-circle-node", title = "n8n Node: Google Gemini 1.5 Flash AI Triage",
                tags$div(class = "reg-circle-icon reg-n8n-node-gemini",
                  tags$img(src = "Google_Gemini_icon_2025.svg.webp", alt = "Google Gemini AI", class = "reg-node-img")
                ),
                tags$div(class = "reg-circle-label", "Gemini 1.5 AI"),
                tags$span(class = "reg-node-tag reg-tag-gemini", "Gemini AI Triage")
              ),
              tags$div(class = "reg-hub-circle-node", title = "n8n Node: Postgres DB (Supabase State Management)",
                tags$div(class = "reg-circle-icon reg-n8n-node-db", bs_icon("database-fill-gear")),
                tags$div(class = "reg-circle-label", "Supabase (Postgres)"),
                tags$span(class = "reg-node-tag", "Insert & Query")
              ),
              tags$div(class = "reg-hub-circle-node", title = "n8n Node: Gmail / Email Dispatch to Technicians and Customers",
                tags$div(class = "reg-circle-icon reg-n8n-node-gmail",
                  tags$img(src = "google_mail_gmail_logo_icon_159346.png", alt = "Gmail Dispatch", class = "reg-node-img")
                ),
                tags$div(class = "reg-circle-label", "Send Message"),
                tags$span(class = "reg-node-tag reg-tag-gmail", "Gmail Dispatch")
              )
            )
          )
        ),

        # Step Cards Below
        tags$div(class = "reg-steps-grid", style = "margin-top: 60px;",
          # Step 1
          tags$div(class = "reg-step-card reg-pinned-card",
            tags$div(class = "reg-step-number", "01"),
            tags$div(class = "reg-step-icon", bs_icon("file-earmark-text-fill")),
            tags$div(class = "reg-step-badge", "Form Submission"),
            tags$h3(class = "reg-step-title", "1. Intake & Edit Fields"),
            tags$p(class = "reg-step-desc", "Citizens log issues on n8n forms. The 'Edit Fields' node generates unique ticket IDs and formats sector parameters.")
          ),
          # Step 2
          tags$div(class = "reg-step-card reg-pinned-card",
            tags$div(class = "reg-step-number", "02"),
            tags$div(class = "reg-step-icon", bs_icon("cpu-fill")),
            tags$div(class = "reg-step-badge", "AI Urgency Scoring"),
            tags$h3(class = "reg-step-title", "2. Gemini AI Triage"),
            tags$p(class = "reg-step-desc", "HTTP Request passes Kinyarwanda/French text to Gemini 1.5 Flash to score urgency and flag fire or shock hazards.")
          ),
          # Step 3
          tags$div(class = "reg-step-card reg-pinned-card",
            tags$div(class = "reg-step-number", "03"),
            tags$div(class = "reg-step-icon", bs_icon("database-fill-check")),
            tags$div(class = "reg-step-badge", "Postgres State"),
            tags$h3(class = "reg-step-title", "3. Clustering & Routing"),
            tags$p(class = "reg-step-desc", "Postgres node checks recent tickets for 3-hour regional outage clusters and assigns designated regional technicians.")
          ),
          # Step 4
          tags$div(class = "reg-step-card reg-pinned-card",
            tags$div(class = "reg-step-number", "04"),
            tags$div(class = "reg-step-icon", bs_icon("envelope-check-fill")),
            tags$div(class = "reg-step-badge", "Gmail Dispatch"),
            tags$h3(class = "reg-step-title", "4. Send Message Alerts"),
            tags$p(class = "reg-step-desc", "Automated Gmail nodes send confirmation receipts to citizens and dispatch urgent repair details to field technicians.")
          )
        )
      )
    ),

    # CTA Section
    tags$section(class = "reg-cta-section",
      tags$div(class = "reg-cta-content",
        tags$h2(class = "reg-cta-title", "Electricity problem in your area? Let us know."),
        tags$div(class = "reg-cta-actions",
          tags$a(
            href = "https://regrwanda.app.n8n.cloud/form/db35406c-9d56-4a55-81df-444072f2260d",
            target = "_blank",
            tagList(bs_icon("lightning-fill"), "Report an Outage"),
            class = "reg-btn-primary", style = "height: 54px; font-size: 16px; padding: 0 32px; text-decoration: none; display: inline-flex; align-items: center; justify-content: center;"
          ),
          actionButton("cta_login_btn", tagList(bs_icon("speedometer2"), "Login to Operational Dashboard"),
            class = "btn btn-outline-dark reg-btn-outline-cta", style = "height: 54px; font-size: 16px; padding: 0 32px; border-radius: 8px;"
          )
        )
      )
    ),

    # Footer (With Integrated REG Contact Details)
    tags$footer(id = "contact", class = "reg-footer",
      tags$div(class = "reg-footer-inner",
        tags$div(class = "reg-footer-contact-strip",
          tags$div(class = "reg-footer-contact-item",
            bs_icon("telephone-fill"),
            tags$span(tags$strong("24/7 Emergency:"), " 2727 / +250 788 300 000")
          ),
          tags$div(class = "reg-footer-contact-item",
            bs_icon("headset"),
            tags$span(tags$strong("Helpline:"), " +250 252 570 720")
          ),
          tags$div(class = "reg-footer-contact-item",
            bs_icon("envelope-fill"),
            tags$span(tags$strong("Email:"), " info@reg.rw")
          ),
          tags$div(class = "reg-footer-contact-item",
            bs_icon("geo-alt-fill"),
            tags$span(tags$strong("HQ:"), " KN 82 St, Nyarugenge, Kigali")
          )
        ),
        tags$div(class = "reg-footer-bottom",
          tags$p(class = "reg-footer-copy", "© 2026 Rwanda Energy Group (REG). All rights reserved."),
          tags$div(class = "reg-footer-links",
            tags$a(class = "reg-footer-link", href = "#", tagList(bs_icon("shield-lock"), "Privacy Policy")),
            tags$a(class = "reg-footer-link", href = "#", tagList(bs_icon("file-earmark-text"), "Terms of Service"))
          )
        )
      )
    ),

    # ── Chatbot Widget ──────────────────────────────────────────────────────────
    tags$div(id = "pg-chat-widget",

      # Floating toggle button
      tags$button(
        id    = "pg-chat-toggle",
        class = "pg-chat-toggle",
        title = "Chat with PulseGrid Assistant",
        tags$span(class = "pg-chat-toggle-icon pg-chat-icon-open",
          bs_icon("chat-dots-fill")
        ),
        tags$span(class = "pg-chat-toggle-icon pg-chat-icon-close",
          bs_icon("x-lg")
        ),
        tags$span(class = "pg-chat-toggle-label", "Ask PulseGrid")
      ),

      # Chat window
      tags$div(id = "pg-chat-window", class = "pg-chat-window",

        # Header
        tags$div(class = "pg-chat-header",
          tags$div(class = "pg-chat-header-avatar",
            bs_icon("lightning-charge-fill")
          ),
          tags$div(class = "pg-chat-header-info",
            tags$div(class = "pg-chat-header-name", "PulseGrid Assistant"),
            tags$div(class = "pg-chat-header-status",
              tags$span(class = "pg-chat-status-dot"),
              "Online — REG Support"
            )
          ),
          tags$button(
            class = "pg-chat-header-close",
            id    = "pg-chat-close",
            title = "Close",
            bs_icon("x-lg")
          )
        ),

        # Messages area
        tags$div(id = "pg-chat-messages", class = "pg-chat-messages",
          # Welcome bot message
          tags$div(class = "pg-chat-msg pg-chat-msg-bot",
            tags$div(class = "pg-chat-bubble",
              "👋 Hi! I'm the PulseGrid Assistant. I can help you report an outage, check ticket status, or answer questions about electricity in Rwanda. How can I help?"
            ),
            tags$div(class = "pg-chat-time", "Just now")
          ),

          # Quick-reply chips
          tags$div(class = "pg-chat-chips",
            tags$button(class = "pg-chat-chip", "Report an outage"),
            tags$button(class = "pg-chat-chip", "Track my ticket"),
            tags$button(class = "pg-chat-chip", "Safety emergency"),
            tags$button(class = "pg-chat-chip", "Contact REG")
          )
        ),

        # Typing indicator (hidden by default)
        tags$div(id = "pg-chat-typing", class = "pg-chat-typing pg-hidden",
          tags$div(class = "pg-chat-bubble pg-typing-bubble",
            tags$span(class = "pg-dot"),
            tags$span(class = "pg-dot"),
            tags$span(class = "pg-dot")
          )
        ),

        # Input area
        tags$div(class = "pg-chat-input-area",
          tags$textarea(
            id          = "pg-chat-input",
            class       = "pg-chat-input",
            placeholder = "Type your message…",
            rows        = "1",
            `aria-label` = "Chat message"
          ),
          tags$button(
            id    = "pg-chat-send",
            class = "pg-chat-send",
            title = "Send message",
            bs_icon("send-fill")
          )
        ),

        # Powered-by strip
        tags$div(class = "pg-chat-footer",
          "Powered by ", tags$strong("PulseGrid AI"), " · REG Rwanda"
        )
      )
    )
    # ── End Chatbot Widget ──────────────────────────────────────────────────────

  )
}
