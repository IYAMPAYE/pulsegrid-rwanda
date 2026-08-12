# =============================================================
# PulseGrid — Ticket Tracking Platform
# -------------------------------------------------------------
# Entry point: loads R modules and runs the Shiny app.
# Modules live in the R/ folder (db, auth, UI, server logic).
# =============================================================

library(shiny)
library(DT)
library(dplyr)
library(echarts4r)
library(DBI)
library(RPostgres)
library(bslib)
library(bsicons)
library(bcrypt)

# Load app modules (order matters for dependencies)
source("R/constants.R")
source("R/db.R")
source("R/auth.R")
source("R/ui_landing.R")
source("R/ui_auth.R")
source("R/ui_admin.R")
source("R/ui_technician.R")
source("R/ui_main.R")
source("R/server_auth.R")
source("R/server_admin.R")
source("R/server_technician.R")
source("R/server.R")

shinyApp(
  ui = ui,
  server = server,
  onStart = function() {
    init_db_pool()
    warm_db_pool()
  }
)
