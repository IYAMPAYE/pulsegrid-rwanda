# Landing page UI

reg_landing_ui <- function() {
  tagList(
    # Header App Bar
    tags$header(class = "reg-header",
      tags$div(class = "reg-brand",
        tags$img(src = "download.png", alt = "REG Logo", class = "reg-brand-logo",
          style = "height: 42px; width: auto; object-fit: contain;")
      ),
      tags$nav(class = "reg-nav",
        tags$a(class = "reg-nav-link active", href = "#", "Home"),
        tags$a(class = "reg-nav-link", href = "#about", "About"),
        tags$a(class = "reg-nav-link", href = "#how-it-works", "How It Works"),
        tags$a(class = "reg-nav-link", href = "#contact", "Contact")
      ),
      tags$div(style = "display: flex; gap: 12px; align-items: center;",
        actionButton("nav_login_btn", "Portal Login", class = "reg-btn-primary"),
        tags$a(href = "https://regrwanda.app.n8n.cloud/form/7e0ba083-f5ba-4555-aa07-2f1e34997e15", target = "_blank", "Report Outage", class = "btn btn-outline-primary", style = "height: 48px; border-radius: 8px; font-weight: 600; display: inline-flex; align-items: center; justify-content: center; text-decoration: none;")
      )
    ),

    # Hero Section
    tags$section(class = "reg-hero",
      tags$div(class = "reg-hero-video-stack",
        tags$img(src = "hello.jpg", class = "reg-hero-poster", alt = ""),
        tags$video(
          id = "hero-vid-1",
          muted = NA, playsinline = NA, preload = "auto", poster = "hello.jpg",
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
      tags$script(HTML("if (window.PulseGrid) PulseGrid.initLanding();")),
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
            tags$a(href = "https://regrwanda.app.n8n.cloud/form/7e0ba083-f5ba-4555-aa07-2f1e34997e15", target = "_blank", "Report an Outage", class = "reg-btn-accent", style = "text-decoration: none; display: inline-flex; align-items: center; justify-content: center;"),
            actionButton("hero_login_btn", "Track My Report / Login", class = "reg-btn-outline-hero")
          )
        )
      )
    ),

    # Trust & Features Section
    tags$section(class = "reg-trust-section",
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

    # CTA Section
    tags$section(class = "reg-cta-section",
      tags$div(class = "reg-cta-content",
        tags$h2(class = "reg-cta-title", "Electricity problem in your area? Let us know."),
        tags$div(class = "reg-cta-actions",
          tags$a(href = "https://regrwanda.app.n8n.cloud/form/7e0ba083-f5ba-4555-aa07-2f1e34997e15", target = "_blank", "Report an Outage", class = "reg-btn-primary", style = "height: 54px; font-size: 16px; padding: 0 32px; text-decoration: none; display: inline-flex; align-items: center; justify-content: center;"),
          actionButton("cta_login_btn", "Login to Operational Dashboard", class = "btn btn-outline-dark", style = "height: 54px; font-size: 16px; padding: 0 32px; border-radius: 8px;")
        )
      )
    ),

    # Footer
    tags$footer(class = "reg-footer",
      tags$div(class = "reg-footer-inner",
        tags$p(class = "reg-footer-copy", "© 2026 Rwanda Energy Group (REG). All rights reserved."),
        tags$div(class = "reg-footer-links",
          tags$a(class = "reg-footer-link", href = "#", "Privacy Policy"),
          tags$a(class = "reg-footer-link", href = "#", "Terms of Service"),
          tags$a(class = "reg-footer-link", href = "#", "FAQ"),
          tags$a(class = "reg-footer-link", href = "#", "Emergency Contact")
        )
      )
    )

  )
}
