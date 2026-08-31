# Chat server module — routes chatbot messages through n8n → Gemini → reply
#
# HOW IT WORKS:
#   1. User types in the chatbot widget on the landing page
#   2. JS sends input$pg_chat_message via Shiny.setInputValue()
#   3. This observer POSTs the message to your n8n webhook
#   4. n8n calls Gemini, optionally logs the chat to Supabase, returns a reply
#   5. The reply is pushed back to the browser with session$sendCustomMessage()
#
# SETUP:
#   - Add N8N_CHAT_WEBHOOK_URL to your .Renviron (see .Renviron.example)
#   - Import the n8n/pulsegrid-chat-workflow.json into your n8n instance
#   - Activate the workflow

init_chat_server <- function(input, output, session) {

  # ── Read webhook URL from environment ────────────────────────────────────
  webhook_url <- Sys.getenv("N8N_CHAT_WEBHOOK_URL")

  # ── Observe every chat message from the browser ──────────────────────────
  observeEvent(input$pg_chat_message, {
    user_msg <- trimws(input$pg_chat_message)
    if (nchar(user_msg) == 0) return()

    # Guard: no webhook configured → fall back to a friendly message
    if (nchar(webhook_url) == 0) {
      session$sendCustomMessage("pg_chat_reply", list(
        text = paste0(
          "⚠️ Chatbot backend not configured yet. ",
          "Please set N8N_CHAT_WEBHOOK_URL in your .Renviron and restart R."
        )
      ))
      return()
    }

    # ── POST to n8n webhook ───────────────────────────────────────────────
    # Payload sent to n8n:
    #   message    — the raw user text
    #   session_id — unique per browser session (useful for n8n conversation memory)
    #   timestamp  — ISO 8601 UTC
    payload <- list(
      message    = user_msg,
      session_id = session$token,
      timestamp  = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    )

    tryCatch({
      response <- httr::POST(
        url     = webhook_url,
        body    = jsonlite::toJSON(payload, auto_unbox = TRUE),
        httr::content_type_json(),
        httr::timeout(15)          # 15-second timeout
      )

      # ── Parse n8n response ──────────────────────────────────────────────
      # Expected JSON from n8n: { "reply": "Bot answer here" }
      if (httr::status_code(response) == 200) {
        data  <- httr::content(response, as = "parsed", type = "application/json")
        reply <- data$reply

        # Validate reply exists and is a non-empty string
        if (is.null(reply) || !nzchar(trimws(reply))) {
          reply <- "🤖 I received your message but couldn't generate a reply. Please try again."
        }
      } else {
        reply <- paste0(
          "⚠️ The assistant is temporarily unavailable (HTTP ",
          httr::status_code(response),
          "). Please try again shortly or call REG on +250 252 570 720."
        )
      }

    }, error = function(e) {
      # Network error / timeout
      reply <<- paste0(
        "⚠️ Could not reach the assistant right now. ",
        "Please check your connection or call REG on +250 252 570 720."
      )
    })

    # ── Push reply back to the chatbot widget ─────────────────────────────
    session$sendCustomMessage("pg_chat_reply", list(text = reply))
  }, ignoreNULL = TRUE, ignoreInit = TRUE)
}
