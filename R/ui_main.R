# Main application UI shell

ui <- fluidPage(
  title = "PulseGrid",
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1, maximum-scale=5"),
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "preconnect", href = "https://fonts.gstatic.com", crossorigin = "anonymous"),
    tags$link(
      rel = "stylesheet",
      href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@600;700&display=swap"
    ),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/app.css"),
    tags$script(src = "js/landing.js"),
    tags$script(src = "js/dashboard-mobile.js"),
    tags$script(src = "js/auth.js"),
    tags$link(rel = "preload", href = "hello.jpg", as = "image"),
    tags$link(rel = "preload", href = "hello2.mp4", as = "video", type = "video/mp4"),
    tags$link(rel = "preload", href = "Video.mp4", as = "video", type = "video/mp4")
  ),
  uiOutput("page")
)
