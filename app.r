# =============================================================
# PulseGrid — Ticket Tracking Platform
# -------------------------------------------------------------
# Now with real authentication:
#   - Admins log in and see the full ops dashboard
#   - Technicians log in with a temporary password, are forced
#     to set their own on first login, then see their own page
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

# -------------------------------------------------------------
# DATA SOURCE: Supabase (Postgres)
# -------------------------------------------------------------
# SETUP (one time):
#   1. Create a file called ".Renviron" in this same folder
#   2. Inside it: SUPABASE_DB_PASSWORD=your_actual_database_password
#   3. Restart R (Session > Restart R) so it picks up the password
# -------------------------------------------------------------

DB_HOST     <- "aws-1-eu-west-1.pooler.supabase.com"
DB_PORT     <- 5432
DB_NAME     <- "postgres"
DB_USER     <- "postgres.cjybmjsaqlhxfiytsjuj"
DB_PASSWORD <- Sys.getenv("SUPABASE_DB_PASSWORD")

get_db_connection <- function() {
  dbConnect(
    RPostgres::Postgres(),
    host     = DB_HOST,
    port     = DB_PORT,
    dbname   = DB_NAME,
    user     = DB_USER,
    password = DB_PASSWORD,
    sslmode  = "require"
  )
}

load_tickets <- function() {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  data <- dbGetQuery(con, "select * from tickets order by created_at desc")
  data %>%
    mutate(
      urgency    = factor(urgency, levels = c("Low", "Medium", "High")),
      created_at = as.Date(created_at)
    )
}

regions   <- c("Kigali", "Huye", "Musanze", "Rubavu", "Nyagatare")
statuses  <- c("New", "In Progress", "Resolved")
urgencies <- c("Low", "Medium", "High")

# -------------------------------------------------------------
# AUTH HELPERS
# -------------------------------------------------------------

check_admin_login <- function(email, password) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  row <- dbGetQuery(con, "select * from admins where email = $1", params = list(email))
  if (nrow(row) == 0) return(NULL)
  if (!bcrypt::checkpw(password, row$password_hash[1])) return(NULL)
  list(role = "admin", id = row$id[1], name = row$name[1], email = row$email[1])
}

check_technician_login <- function(email, password) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  row <- dbGetQuery(con, "select * from technicians where email = $1", params = list(email))
  if (nrow(row) == 0) return(NULL)
  if (is.na(row$password_hash[1])) return(NULL)
  if (!bcrypt::checkpw(password, row$password_hash[1])) return(NULL)
  
  dbExecute(con, "update technicians set last_login = now() where id = $1", params = list(row$id[1]))
  
  list(
    role = "technician",
    id = row$id[1],
    name = row$name[1],
    email = row$email[1],
    phone = row$phone[1],
    must_change_password = isTRUE(row$must_change_password[1])
  )
}

verify_technician_password <- function(technician_id, password) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  row <- dbGetQuery(con, "select password_hash from technicians where id = $1", params = list(technician_id))
  if (nrow(row) == 0) return(FALSE)
  bcrypt::checkpw(password, row$password_hash[1])
}

update_technician_password <- function(technician_id, new_password) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  hash <- bcrypt::hashpw(new_password)
  dbExecute(con, "update technicians set password_hash = $1 where id = $2", params = list(hash, technician_id))
}

update_technician_profile <- function(technician_id, email, phone) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  dbExecute(
    con,
    "update technicians set email = $1, phone = $2 where id = $3",
    params = list(email, phone, technician_id)
  )
}

load_technician_tickets <- function(technician_email) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  dbGetQuery(
    con,
    "select * from tickets where technician_email = $1 order by created_at desc",
    params = list(technician_email)
  )
}

set_new_technician_password <- function(technician_id, new_password) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  hash <- bcrypt::hashpw(new_password)
  dbExecute(
    con,
    "update technicians set password_hash = $1, must_change_password = false where id = $2",
    params = list(hash, technician_id)
  )
}

# -------------------------------------------------------------
# SHARED STYLES
# -------------------------------------------------------------

app_styles <- HTML("
  /* Stitch REG Portal Design System */
  :root {
    --reg-primary: #031635;
    --reg-primary-container: #1a2b4b;
    --reg-secondary: #0058be;
    --reg-tertiary-fixed: #ffddb1;
    --reg-tertiary-fixed-dim: #e8c08a;
    --reg-bg: #f9f9ff;
    --reg-surface-lowest: #ffffff;
    --reg-surface-container: #e6eeff;
    --reg-on-surface: #121c2a;
    --reg-on-surface-variant: #44474e;
    --reg-outline-variant: #c5c6cf;
  }

  body, html { margin: 0; padding: 0; height: 100%; background-color: var(--reg-bg); font-family: 'Inter', system-ui, -apple-system, sans-serif; color: var(--reg-on-surface); }
  .container-fluid { padding: 0; }

  .custom-sidebar {
    position: fixed; top: 0; left: 0; height: 100vh; width: 280px;
    background: linear-gradient(rgba(15, 23, 42, 0.6), rgba(15, 23, 42, 0.6)), url('sidebar_bg.jpg') no-repeat center center;
    background-size: cover; color: white; padding: 20px 0; z-index: 1000;
    box-shadow: 1px 0 3px rgba(0,0,0,0.05);
  }
  .sidebar-brand { padding: 0 20px 20px 20px; border-bottom: 1px solid rgba(255,255,255,0.1); margin-bottom: 20px; }
  .sidebar-brand h3 { margin: 0; font-weight: bold; color: #38bdf8; display: flex; align-items: center; gap: 10px; font-size: 22px; }
  .sidebar-brand p { margin: 5px 0 0 0; font-size: 13px; color: #cbd5e1; }
  .nav-header { padding: 0 20px; font-size: 11px; font-weight: bold; color: #94a3b8; letter-spacing: 1px; margin-bottom: 10px; margin-top: 15px; }
  .nav-item { padding: 12px 20px; display: flex; align-items: center; gap: 15px; cursor: pointer; color: #cbd5e1; font-size: 14px; transition: 0.3s; margin: 0 10px; border-radius: 6px; }
  .nav-item:hover { background: rgba(255,255,255,0.05); color: white; }
  .nav-item.active { background: rgba(255,255,255,0.1); color: white; border-left: 4px solid #38bdf8; border-radius: 0 6px 6px 0; }

  .main-content { margin-left: 280px; padding: 30px 40px; background-color: #f8fafc; min-height: 100vh; }
  .header-title { display: flex; align-items: center; justify-content: space-between; margin-bottom: 5px; }
  .header-title h2 { margin: 0; font-weight: bold; color: #0f172a; font-size: 28px; }
  /* Admin Profile Dropdown */
  .admin-profile-container { position: relative; display: inline-block; z-index: 1000; }
  .admin-profile-trigger {
    display: flex; align-items: center; gap: 12px; background: #ffffff;
    padding: 6px 16px 6px 6px; border-radius: 50px; cursor: pointer;
    border: 1px solid rgba(226, 232, 240, 0.8);
    box-shadow: 0 4px 15px -5px rgba(15, 23, 42, 0.05);
    transition: box-shadow 0.2s, transform 0.2s;
  }
  .admin-profile-trigger:hover { box-shadow: 0 8px 25px -5px rgba(15, 23, 42, 0.08); transform: translateY(-2px); }
  .admin-avatar-small { width: 42px; height: 42px; border-radius: 50%; object-fit: cover; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
  
  .admin-info { display: flex; flex-direction: column; justify-content: center; }
  .admin-name { font-size: 14.5px; font-weight: 700; color: #0f172a; margin: 0; line-height: 1.2; }
  .admin-role { font-size: 12.5px; font-weight: 600; color: #64748b; margin: 0; line-height: 1.2; }
  .trigger-icon { color: #94a3b8; font-size: 14px; margin-left: 4px; }

  .admin-profile-dropdown {
    position: absolute; top: calc(100% + 12px); right: 0; width: 260px;
    background: #ffffff; border-radius: 12px; box-shadow: 0 10px 40px -10px rgba(0,0,0,0.15);
    border: 1px solid #f1f5f9; padding: 24px 0 12px 0;
    opacity: 0; visibility: hidden; transform: translateY(-10px); transition: all 0.25s ease;
  }
  .admin-profile-container:hover .admin-profile-dropdown {
    opacity: 1; visibility: visible; transform: translateY(0);
  }
  .dropdown-header { display: flex; flex-direction: column; align-items: center; margin-bottom: 24px; }
  .dropdown-avatar-wrapper { position: relative; margin-bottom: 16px; }
  .dropdown-avatar-initial {
    width: 64px; height: 64px; background-color: #5c433b; color: #ffffff;
    border-radius: 50%; display: flex; align-items: center; justify-content: center;
    font-size: 28px; font-weight: 500; font-family: 'Inter', sans-serif;
  }
  .status-dot {
    position: absolute; bottom: 2px; right: 2px; width: 14px; height: 14px;
    background-color: #4ade80; border: 2px solid #ffffff; border-radius: 50%;
  }
  .dropdown-name { font-size: 16px; font-weight: 700; color: #0f172a; margin: 0; }
  
  .dropdown-menu-list { list-style: none; padding: 0; margin: 0; }
  .dropdown-menu-list li a, .dropdown-signout {
    display: block; padding: 12px 24px; color: #1e293b; text-decoration: none;
    font-size: 14.5px; transition: background 0.2s; background: none; border: none; width: 100%; text-align: left; cursor: pointer;
  }
  .dropdown-menu-list li a:hover, .dropdown-signout:hover { background-color: #f8fafc; }
  .dropdown-divider { margin: 12px 24px; border: 0; border-top: 1px solid #e2e8f0; }

  .kpi-row { display: flex; gap: 20px; margin-bottom: 30px; }
  .kpi-card {
    background: white; padding: 25px; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    flex: 1; position: relative; border-top: 4px solid #e2e8f0;
  }
  .kpi-card.primary { border-top-color: #ec4899; }
  .kpi-card.warning { border-top-color: #f59e0b; }
  .kpi-card.danger { border-top-color: #ef4444; }
  .kpi-card.critical { border-top-color: #b91c1c; background: #fef2f2; }
  .kpi-title { font-size: 14px; color: #64748b; font-weight: bold; margin-bottom: 15px; }
  .kpi-value { font-size: 36px; font-weight: bold; color: #0f172a; }
  .kpi-icon { position: absolute; top: 25px; right: 25px; font-size: 28px; color: #e2e8f0; }

  .chart-container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05); margin-bottom: 20px; min-width: 0; }
  .chart-container .html-widget,
  .chart-container .echarts4r,
  .chart-container div[id$='_w'] { width: 100% !important; max-width: 100%; }
  .data-table-container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05); margin-bottom: 20px; }

  /* Profile Settings Tab */
  .settings-card {
    background: #ffffff; padding: 32px; border-radius: 16px;
    border: 1px solid rgba(226, 232, 240, 0.8);
    box-shadow: 0 4px 15px -5px rgba(15, 23, 42, 0.05);
  }
  .settings-card-header { display: flex; align-items: center; gap: 16px; margin-bottom: 8px; }
  .settings-icon-box {
    width: 48px; height: 48px; border-radius: 12px; background-color: #e0f2fe;
    display: flex; align-items: center; justify-content: center; color: #3b82f6; font-size: 22px;
  }
  .settings-card-header h4 { margin: 0; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 20px; font-weight: 700; color: #0f172a; }
  .settings-desc { color: #64748b; font-size: 14px; margin-bottom: 24px; line-height: 1.5; font-family: 'Inter', sans-serif; }

  /* ── Dashboard layout ─────────────────────────────────────── */
  .dashboard-shell { position: relative; min-height: 100vh; width: 100%; overflow-x: hidden; }
  .sidebar-backdrop {
    display: none; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.55);
    z-index: 1040; opacity: 0; transition: opacity 0.25s ease;
  }
  .dashboard-shell.sidebar-open .sidebar-backdrop {
    display: block; opacity: 1;
  }
  .header-subtitle { color: #64748b; font-size: 14px; margin-bottom: 24px; }
  .dashboard-chart-row {
    display: grid; grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 20px; margin-bottom: 20px;
  }
  .tech-dashboard {
    margin-left: auto !important; margin-right: auto !important;
    max-width: 1100px; width: 100%; box-sizing: border-box;
  }
  .tech-header-actions {
    display: flex; align-items: center; gap: 12px; flex-shrink: 0;
  }
  .tech-notif-btn {
    background: white; border: 1px solid rgba(226, 232, 240, 0.8); border-radius: 50%;
    width: 44px; height: 44px; min-width: 44px; display: flex; align-items: center;
    justify-content: center; position: relative; cursor: pointer; color: #64748b;
    box-shadow: 0 4px 15px -5px rgba(15, 23, 42, 0.05); transition: transform 0.2s;
  }
  .tech-notif-btn:hover { transform: scale(1.05); }
  .profile-settings-grid {
    display: grid; grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 32px; margin-top: 32px;
  }
  .tech-tabs .nav-tabs { border-bottom: 2px solid #e2e8f0; flex-wrap: nowrap; overflow-x: auto; -webkit-overflow-scrolling: touch; }
  .tech-tabs .nav-tabs > li > a { white-space: nowrap; font-weight: 600; color: #64748b; padding: 12px 20px; }
  .tech-tabs .nav-tabs > li.active > a { color: #0f172a !important; border-bottom: 3px solid #0284c7 !important; }
  .admin-profile-container.dropdown-open .admin-profile-dropdown {
    opacity: 1; visibility: visible; transform: translateY(0);
  }

  @media (max-width: 992px) {
    .kpi-row { flex-wrap: wrap; }
    .kpi-card { flex: 1 1 calc(50% - 10px); min-width: 140px; }
    .custom-sidebar {
      transform: translateX(-100%);
      transition: transform 0.3s ease;
      z-index: 1050;
    }
    .dashboard-shell.sidebar-open .custom-sidebar { transform: translateX(0); }
    .main-content { margin-left: 0 !important; padding: 20px 20px 32px; width: 100%; max-width: 100%; box-sizing: border-box; }
    .dashboard-chart-row { grid-template-columns: 1fr; }
    .profile-settings-grid { grid-template-columns: 1fr; gap: 24px; }
    .mobile-menu-btn { display: flex; align-items: center; justify-content: center; }
    .header-title { flex-wrap: wrap; gap: 12px; align-items: flex-start; }
    .header-title h2 { font-size: 24px; flex: 1 1 auto; min-width: 0; word-break: break-word; }
    .admin-profile-container { margin-left: auto; }
    .settings-card { padding: 24px 20px; }
  }

  @media (max-width: 768px) {
    .profile-settings-grid { grid-template-columns: 1fr !important; }
    .main-content { padding: 16px 14px 28px; }
    .kpi-card { flex: 1 1 100%; padding: 18px; }
    .kpi-value { font-size: 28px; }
    .kpi-icon { font-size: 22px; top: 18px; right: 18px; }
    .header-title h2 { font-size: 20px; line-height: 1.25; }
    .header-subtitle { font-size: 13px; margin-bottom: 18px; }
    .filter-row { flex-direction: column; gap: 10px; }
    .filter-row .shiny-input-container { width: 100% !important; max-width: 100%; }
    .chart-container { padding: 16px 14px; }
    .data-table-container { padding: 16px 12px; }
    .data-table-container h4 { font-size: 17px; }
    .admin-profile-trigger { padding: 4px 10px 4px 4px; gap: 8px; max-width: 100%; }
    .admin-name { font-size: 13px; max-width: 120px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .admin-role { font-size: 11px; }
    .admin-profile-dropdown { width: min(260px, calc(100vw - 28px)); right: 0; left: auto; }
    .tech-header-actions { gap: 8px; }
    .tech-notif-btn { width: 40px; height: 40px; min-width: 40px; }
    .settings-card { padding: 20px 16px; border-radius: 12px; }
    .settings-card-header h4 { font-size: 18px; }
    .btn-submit-custom { width: 100% !important; }
    .tech-tabs .nav-tabs > li > a { padding: 10px 16px; font-size: 14px; }
  }

  @media (max-width: 480px) {
    .main-content { padding: 14px 12px 24px; }
    .header-title h2 { font-size: 18px; }
    .kpi-value { font-size: 24px; }
    .admin-info .admin-role { display: none; }
    .admin-name { max-width: 90px; }
    .sidebar-brand h3 { font-size: 18px; }
    .sidebar-brand p { font-size: 12px; }
    .dataTables_wrapper { font-size: 12px; }
    .dataTables_wrapper .dataTables_length,
    .dataTables_wrapper .dataTables_filter { text-align: left; margin-bottom: 8px; }
    .dataTables_wrapper .dataTables_length select,
    .dataTables_wrapper .dataTables_filter input { width: 100%; max-width: 100%; margin-left: 0; }
  }

  .data-table-container { 
    background: white; padding: 20px; border-radius: 8px; 
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05); 
    margin-bottom: 20px;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }
  .data-table-container .dataTables_wrapper { width: 100%; overflow-x: auto; }

  /* Hamburger Menu Button for Mobile */
  .mobile-menu-btn {
    display: none;
    background: #ffffff;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    width: 44px; height: 44px; min-width: 44px;
    font-size: 22px;
    color: #0f172a;
    cursor: pointer;
    margin-right: 12px;
    flex-shrink: 0;
    box-shadow: 0 2px 8px rgba(15, 23, 42, 0.06);
  }
  .mobile-menu-btn:active { transform: scale(0.96); }

  @media (max-width: 992px) {
    .header-title { justify-content: flex-start; align-items: center; }
  }

  .filter-row { margin-bottom: 20px; display: flex; gap: 15px; flex-wrap: wrap; }
  .filter-row .shiny-input-container { margin-bottom: 0; width: 200px; flex: 1 1 160px; min-width: 140px; }
  .filter-row .control-label { font-size: 12px; color: #64748b; font-weight: bold; }
  .filter-row .form-control { border-radius: 6px; border: 1px solid #cbd5e1; }

  /* Top App Bar */
  .reg-header {
    position: fixed; top: 0; left: 0; right: 0; height: 72px; z-index: 1000;
    background-color: var(--reg-bg); border-bottom: 1px solid var(--reg-outline-variant);
    display: flex; align-items: center; justify-content: space-between; padding: 0 32px;
    transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
    box-sizing: border-box;
  }
  .reg-header.nav-scrolled {
    top: 12px; height: 60px; padding: 0 24px;
    max-width: 1200px; margin: 0 auto; left: 16px; right: 16px;
    background-color: rgba(241, 245, 249, 0.4);
    backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
    border: 1px solid rgba(197, 198, 207, 0.6);
    border-radius: 14px;
    box-shadow: 0 10px 30px -5px rgba(3, 22, 53, 0.12);
  }
  .reg-brand { display: flex; align-items: center; gap: 10px; color: var(--reg-primary); text-decoration: none; }
  .reg-brand-title { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 22px; font-weight: 700; color: var(--reg-primary); }
  
  .reg-nav { display: flex; align-items: center; gap: 36px; height: 100%; }
  .reg-nav-link {
    height: 100%; display: flex; align-items: center; color: var(--reg-on-surface-variant);
    text-decoration: none; font-weight: 500; font-size: 15px; transition: color 0.2s; padding: 0 4px;
  }
  .reg-nav-link:hover { color: var(--reg-secondary); }
  .reg-nav-link.active { color: var(--reg-secondary); font-weight: 700; border-bottom: 3px solid var(--reg-secondary); }

  .reg-btn-primary {
    display: inline-flex; align-items: center; justify-content: center; height: 48px; padding: 0 24px;
    background-color: var(--reg-primary); color: #ffffff !important; border-radius: 8px; font-weight: 600;
    text-decoration: none; border: none; cursor: pointer; transition: background-color 0.2s; font-size: 14px;
  }
  .reg-btn-primary:hover { background-color: #08224d; }

  .reg-btn-accent {
    display: inline-flex; align-items: center; justify-content: center; height: 56px; padding: 0 32px;
    background-color: var(--reg-tertiary-fixed); color: var(--reg-primary) !important; border-radius: 8px;
    font-weight: 600; text-decoration: none; border: none; cursor: pointer; transition: background-color 0.2s; font-size: 16px;
    box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
  }
  .reg-btn-accent:hover { background-color: var(--reg-tertiary-fixed-dim); }

  .reg-btn-outline-hero {
    display: inline-flex; align-items: center; justify-content: center; height: 56px; padding: 0 32px;
    background: rgba(255,255,255,0.1); color: #ffffff !important; border: 1px solid rgba(255,255,255,0.3);
    border-radius: 8px; font-weight: 600; text-decoration: none; cursor: pointer; backdrop-filter: blur(4px);
    transition: background-color 0.2s; font-size: 16px;
  }
  .reg-btn-outline-hero:hover { background: rgba(255,255,255,0.2); }

  /* Hero Section */
  .reg-hero {
    position: relative;
    background: url('hello.jpg') center/cover no-repeat;
    background-color: #030c1a;
    color: #ffffff;
    min-height: 100vh; display: flex; align-items: center; padding: 100px 32px 80px 32px; overflow: hidden; margin-top: 72px;
  }
  .reg-hero-video-stack {
    position: absolute; inset: 0; z-index: 0; overflow: hidden;
    background: url('hello.jpg') center/cover no-repeat;
    background-color: #030c1a;
  }
  .reg-hero-poster {
    position: absolute; top: 0; left: 0; width: 100%; height: 100%;
    object-fit: cover; object-position: center;
    filter: brightness(0.88);
    z-index: 0;
    transition: opacity 0.8s ease;
    pointer-events: none;
  }
  .reg-hero-poster.is-hidden {
    opacity: 0;
  }
  .reg-hero-video-bg {
    position: absolute; top: 0; left: 0; width: 100%; height: 100%;
    object-fit: cover; object-position: center;
    filter: brightness(0.88);
    will-change: opacity;
    opacity: 0;
    transition: opacity 0.9s ease;
    pointer-events: none;
    z-index: 1;
  }
  .reg-hero-video-bg.is-visible {
    opacity: 1;
    z-index: 2;
  }
  .reg-hero-overlay {
    position: absolute; inset: 0; z-index: 1;
    background: linear-gradient(135deg, rgba(3, 22, 53, 0.48) 0%, rgba(3, 22, 53, 0.18) 100%);
  }
  .reg-hero-content { position: relative; z-index: 2; max-width: 1200px; margin: 0 auto; width: 100%; }
  .reg-hero-body { max-width: 680px; }
  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(30px); }
    to { opacity: 1; transform: translateY(0); }
  }

  .reg-hero-headline {
    font-family: 'Plus Jakarta Sans', sans-serif; font-size: 46px; font-weight: 800; line-height: 1.15;
    margin-bottom: 24px; color: #ffffff; letter-spacing: -0.02em; text-shadow: 0 3px 15px rgba(0,0,0,0.85);
    opacity: 0;
    animation: fadeUp 0.9s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }
  .reg-hero-headline span { color: var(--reg-tertiary-fixed); }
  .reg-hero-sub { 
    font-size: 18px; line-height: 1.6; color: rgba(255,255,255,0.98); margin-bottom: 40px; text-shadow: 0 2px 10px rgba(0,0,0,0.85); 
    opacity: 0;
    animation: fadeUp 0.9s cubic-bezier(0.16, 1, 0.3, 1) 0.2s forwards;
  }
  .reg-hero-actions { 
    display: flex; gap: 16px; flex-wrap: wrap; 
    opacity: 0;
    animation: fadeUp 0.9s cubic-bezier(0.16, 1, 0.3, 1) 0.4s forwards;
  }

  /* Features / About Section - Transparent Pale Gray Glassmorphism */
  .reg-trust-section {
    padding: 100px 32px;
    background-color: rgba(241, 245, 249, 0.45);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    border-top: 1px solid rgba(197, 198, 207, 0.4);
    border-bottom: 1px solid rgba(197, 198, 207, 0.4);
  }
  .reg-trust-container { max-width: 1200px; margin: 0 auto; }
  .reg-grid-4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 24px; }
  
  .reg-card {
    background: rgba(255, 255, 255, 0.65);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    padding: 32px 28px;
    border-radius: 18px;
    border: 1px solid rgba(255, 255, 255, 0.7);
    box-shadow: 0 10px 30px -5px rgba(3, 22, 53, 0.06), inset 0 0 0 1px rgba(255, 255, 255, 0.4);
    transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.35s ease, background-color 0.3s ease, opacity 0.6s ease;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    opacity: 0;
    transform: translateY(40px);
  }
  .reg-card.scroll-animated {
    opacity: 1;
    transform: translateY(0);
  }
  .reg-card:hover {
    background: rgba(255, 255, 255, 0.9);
    transform: translateY(-8px) scale(1.02);
    box-shadow: 0 20px 40px -10px rgba(3, 22, 53, 0.12), 0 0 20px rgba(0, 88, 190, 0.15);
    border-color: rgba(0, 88, 190, 0.3);
  }
  .reg-card-icon {
    width: 54px; height: 54px; border-radius: 14px;
    background: linear-gradient(135deg, rgba(224, 242, 254, 0.9), rgba(186, 230, 253, 0.6));
    display: flex; align-items: center; justify-content: center; color: #0284c7;
    font-size: 24px; margin-bottom: 24px;
    transition: transform 0.3s ease, background 0.3s ease, color 0.3s ease;
  }
  .reg-card:hover .reg-card-icon {
    transform: scale(1.1) rotate(-3deg);
    background: linear-gradient(135deg, #0284c7, #0369a1);
    color: #ffffff;
  }
  .reg-card-title { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 20px; font-weight: 700; color: #0f172a; margin-bottom: 12px; }
  .reg-card-desc { font-family: 'Inter', sans-serif; font-size: 14.5px; color: #475569; line-height: 1.65; font-weight: 500; margin: 0; }

  /* CTA Section */
  .reg-cta-section { background-color: var(--reg-surface-container); padding: 80px 32px; text-align: center; }
  .reg-cta-content { max-width: 700px; margin: 0 auto; }
  .reg-cta-title { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 32px; font-weight: 700; color: var(--reg-primary); margin-bottom: 24px; }
  .reg-cta-actions { display: flex; justify-content: center; gap: 16px; flex-wrap: wrap; }

  /* Footer */
  .reg-footer { background-color: var(--reg-primary); color: #ffffff; padding: 48px 32px; }
  .reg-footer-inner {
    max-width: 1200px; margin: 0 auto; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 20px;
  }
  .reg-footer-copy { font-size: 14px; color: rgba(255,255,255,0.8); margin: 0; }
  .reg-footer-links { display: flex; gap: 24px; flex-wrap: wrap; }
  .reg-footer-link { color: rgba(255,255,255,0.8); text-decoration: none; font-size: 14px; transition: color 0.2s; }
  .reg-footer-link:hover { color: var(--reg-tertiary-fixed); }

  /* Auth / Modal Styling */
  .auth-wrapper {
    min-height: 100vh; display: flex; align-items: center; justify-content: center;
    background: radial-gradient(circle at 15% 50%, #0f172a 0%, #090d16 100%);
    padding: 30px 20px; box-sizing: border-box; font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  }

  .landing-auth-card {
    background: #ffffff; padding: 30px 25px; border-radius: 12px;
  }
  .auth-card-header h3 { margin: 0 0 6px 0; font-weight: 700; color: #0f172a; font-size: 22px; }
  .auth-card-header p { margin: 0 0 20px 0; color: #64748b; font-size: 13px; }

  .form-group-custom { margin-bottom: 16px; }
  .form-group-custom label { display: block; font-size: 13px; font-weight: 600; color: #334155; margin-bottom: 6px; }
  .input-with-icon { position: relative; }
  .input-with-icon i { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); color: #94a3b8; font-size: 16px; pointer-events: none; }
  .input-with-icon .form-control {
    padding-left: 42px !important; height: 44px; border-radius: 8px; border: 1px solid #cbd5e1;
    font-size: 14px; color: #0f172a; transition: all 0.2s ease;
  }
  .input-with-icon .form-control:focus {
    border-color: #0284c7; box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15); outline: none;
  }
  .btn-submit-custom {
    width: 100%; height: 44px; border-radius: 8px; background: linear-gradient(135deg, #0284c7, #0369a1);
    color: white; border: none; font-size: 15px; font-weight: 600; cursor: pointer; transition: all 0.2s ease;
    display: flex; align-items: center; justify-content: center; gap: 8px; margin-top: 10px; box-shadow: 0 4px 12px rgba(2, 132, 199, 0.25);
  }
  .btn-submit-custom:hover { background: linear-gradient(135deg, #0369a1, #075985); }
  .auth-error {
    background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; padding: 10px 12px;
    border-radius: 8px; font-size: 13px; margin-top: 14px; display: flex; align-items: center; gap: 8px;
  }

  @media (max-width: 992px) {
    .reg-grid-4 { grid-template-columns: repeat(2, 1fr); }
    .reg-nav { display: none; }
  }
  /* Dynamic Animated Text Motion Styles */
  .figma-animated-line {
    display: inline-block;
    position: relative;
    color: var(--reg-tertiary-fixed);
  }
  
  .figma-animated-word {
    display: inline-block;
    transition: transform 0.45s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.35s ease, filter 0.35s ease;
    will-change: transform, opacity, filter;
  }
  .figma-animated-word.swap-out {
    transform: translateY(-24px);
    opacity: 0;
    filter: blur(4px);
  }
  .figma-animated-word.swap-in {
    transform: translateY(24px);
    opacity: 0;
    filter: blur(4px);
  }

  /* Dynamic Scroll Reveal for Cards & Buttons */
  .reg-btn-accent, .reg-btn-outline-hero {
    transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.3s ease, background-color 0.2s ease;
  }
  .reg-btn-accent:hover { transform: translateY(-3px) scale(1.03); box-shadow: 0 10px 20px rgba(0,0,0,0.2); }
  .reg-btn-outline-hero:hover { transform: translateY(-3px) scale(1.03); box-shadow: 0 10px 20px rgba(0,0,0,0.15); }
")

# -------------------------------------------------------------
# REG PORTAL UI PIECES
# -------------------------------------------------------------

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
      tags$script(HTML("
        (function() {
          // ── Video playlist config ─────────────────────────────────────
          // Use the SAME rate for both clips for the smoothest loop.
          // If you need hello2 faster later, raise only hero-vid-1 — the
          // timer below handles different speeds without freezing.
          var HERO_RATES = { 'hero-vid-1': 1.5, 'hero-vid-2': 1.5 };
          var FADE_MS = 900;

          function initVideos() {
            var hero = document.querySelector('.reg-hero');
            var v1 = document.getElementById('hero-vid-1');
            var v2 = document.getElementById('hero-vid-2');
            if (!hero || !v1 || !v2) { requestAnimationFrame(initVideos); return; }
            if (hero.dataset.videosInit === '1') return;
            hero.dataset.videosInit = '1';

            var videos = [v1, v2];
            var activeIdx = 0;
            var switching = false;
            var started = false;
            var switchTimer = null;

            videos.forEach(function(video) {
              video.muted = true;
              video.playsInline = true;
              video.setAttribute('playsinline', '');
              video.setAttribute('webkit-playsinline', '');
              video.preload = 'auto';
              video.loop = false;
              video.playbackRate = HERO_RATES[video.id] || 1;
            });

            function getActive() { return videos[activeIdx]; }
            function getStandby() { return videos[1 - activeIdx]; }

            function safePlay(video) {
              var playPromise = video.play();
              if (playPromise && typeof playPromise.then === 'function') {
                return playPromise.catch(function() {});
              }
              return Promise.resolve();
            }

            function clearSwitchTimer() {
              if (switchTimer) {
                clearTimeout(switchTimer);
                switchTimer = null;
              }
            }

            // Wall-clock timer: switch before the clip ends (works with any playback rate)
            function scheduleNextSwitch(video) {
              clearSwitchTimer();
              var rate = HERO_RATES[video.id] || 1;
              var wallMs = 12000;
              if (video.duration && !isNaN(video.duration)) {
                wallMs = (video.duration / rate) * 1000;
              }
              var switchAt = Math.max(2500, wallMs - FADE_MS - 300);
              switchTimer = setTimeout(crossfade, switchAt);
            }

            function crossfade() {
              if (switching) return;
              clearSwitchTimer();

              var active = getActive();
              var standby = getStandby();
              if (!active || !standby) return;

              switching = true;

              standby.currentTime = 0;
              standby.playbackRate = HERO_RATES[standby.id] || 1;

              safePlay(standby).then(function() {
                standby.classList.add('is-visible');
                active.classList.remove('is-visible');

                setTimeout(function() {
                  active.pause();
                  active.currentTime = 0;
                  activeIdx = 1 - activeIdx;
                  switching = false;
                  scheduleNextSwitch(getActive());
                }, FADE_MS);
              }).catch(function() {
                switching = false;
                scheduleNextSwitch(getActive());
              });
            }

            videos.forEach(function(video) {
              video.addEventListener('ended', function() {
                if (video === getActive() && !switching) crossfade();
              });
            });

            function hidePoster() {
              var poster = document.querySelector('.reg-hero-poster');
              if (poster) poster.classList.add('is-hidden');
            }

            function startPlayback() {
              if (started) return;
              started = true;
              v1.classList.add('is-visible');
              safePlay(v1).then(function() {
                hidePoster();
                scheduleNextSwitch(v1);
              });
            }

            function waitForFirstFrame(video, done) {
              if (video.readyState >= 2) {
                done();
                return;
              }
              video.addEventListener('loadeddata', done, { once: true });
              video.addEventListener('canplay', done, { once: true });
            }

            v1.load();
            v2.load();
            waitForFirstFrame(v1, startPlayback);

            document.addEventListener('visibilitychange', function() {
              if (!document.hidden) {
                var active = getActive();
                safePlay(active);
                scheduleNextSwitch(active);
              }
            });

            document.addEventListener('click', function kickstart() {
              var active = getActive();
              safePlay(active);
              if (!switchTimer) scheduleNextSwitch(active);
              document.removeEventListener('click', kickstart);
            }, { once: true });
          }

          // Rotating Animated Phrases Script with Staggered Cascading Replacement
          function initHeadlineAnimation() {
            var line1 = document.getElementById('figma-line-1');
            var line2 = document.getElementById('figma-line-2');
            var line3 = document.getElementById('figma-line-3');
            if (!line1 || !line2 || !line3) { requestAnimationFrame(initHeadlineAnimation); return; }
            
            var phrases = [
              { l1: 'Power Problems?', l2: 'Report Them Once.', l3: 'We\\'ll Take It From Here.' },
              { l1: 'Transformer Tripped?', l2: 'Instant Dispatch.', l3: 'Technicians On The Way.' },
              { l1: 'Grid Disruption?', l2: 'Real-Time Tracking.', l3: 'Restoration Guaranteed.' },
              { l1: 'Blackout in Area?', l2: 'One-Click Report.', l3: 'We Keep Rwanda Powered.' }
            ];
            var index = 0;
            
            setInterval(function() {
              index = (index + 1) % phrases.length;
              var next = phrases[index];

              // Staggered sequential disappearance (Line 1 -> Line 2 -> Line 3)
              line1.classList.add('swap-out');
              setTimeout(function() { line2.classList.add('swap-out'); }, 220);
              setTimeout(function() { line3.classList.add('swap-out'); }, 440);
              
              // After all lines disappear, swap text and trigger staggered entrance (Line 1 -> Line 2 -> Line 3)
              setTimeout(function() {
                line1.innerText = next.l1;
                line2.innerText = next.l2;
                line3.innerText = next.l3;

                line1.classList.remove('swap-out'); line1.classList.add('swap-in');
                line2.classList.remove('swap-out'); line2.classList.add('swap-in');
                line3.classList.remove('swap-out'); line3.classList.add('swap-in');

                requestAnimationFrame(function() {
                  setTimeout(function() { line1.classList.remove('swap-in'); }, 80);
                  setTimeout(function() { line2.classList.remove('swap-in'); }, 300);
                  setTimeout(function() { line3.classList.remove('swap-in'); }, 520);
                });
              }, 850);
            }, 4600);
          }

          // Scroll-triggered dynamic motion for feature boxes & cards
          function initScrollMotion() {
            var cards = document.querySelectorAll('.reg-card');
            if (!cards.length) return;

            var observer = new IntersectionObserver(function(entries) {
              entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                  entry.target.classList.add('scroll-animated');
                }
              });
            }, { threshold: 0.15 });

            cards.forEach(function(card) {
              observer.observe(card);
            });
          }

          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', function() {
              initVideos();
              initHeadlineAnimation();
              initScrollMotion();
            });
          } else {
            initVideos();
            initHeadlineAnimation();
            initScrollMotion();
          }
        })();
      ")),
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
    ),

    # JavaScript Scroll Tracker for Floating Glass Navigation
    tags$script(HTML("
      (function() {
        const header = document.querySelector('.reg-header');
        if (!header) return;

        window.addEventListener('scroll', function() {
          if (window.scrollY > 30) {
            header.classList.add('nav-scrolled');
          } else {
            header.classList.remove('nav-scrolled');
          }
        }, { passive: true });

      })();
    "))
  )
}

# -------------------------------------------------------------
# UI PIECES
# -------------------------------------------------------------

login_ui <- function(error_message = NULL) {
  tags$div(class = "auth-wrapper",
           tags$div(class = "landing-container",
                    # Left Hero Banner
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
                    # Right Auth Card
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

dashboard_mobile_script <- function() {
  tags$script(HTML("
    (function() {
      function initDashboardMobile() {
        var shell = document.querySelector('.dashboard-shell');
        if (!shell || shell.dataset.mobileInit === '1') return;
        shell.dataset.mobileInit = '1';

        var menuBtn = document.getElementById('dashboard_menu_btn');
        var backdrop = shell.querySelector('.sidebar-backdrop');

        function closeSidebar() { shell.classList.remove('sidebar-open'); }

        if (menuBtn) {
          menuBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            shell.classList.toggle('sidebar-open');
          });
        }
        if (backdrop) {
          backdrop.addEventListener('click', closeSidebar);
        }

        shell.querySelectorAll('.custom-sidebar .nav-item').forEach(function(item) {
          item.addEventListener('click', closeSidebar);
        });

        document.querySelectorAll('.admin-profile-container').forEach(function(container) {
          var trigger = container.querySelector('.admin-profile-trigger');
          if (!trigger || trigger.dataset.bound === '1') return;
          trigger.dataset.bound = '1';
          trigger.addEventListener('click', function(e) {
            e.stopPropagation();
            var open = container.classList.contains('dropdown-open');
            document.querySelectorAll('.admin-profile-container').forEach(function(c) {
              c.classList.remove('dropdown-open');
            });
            if (!open) container.classList.add('dropdown-open');
          });
        });

        document.addEventListener('click', function() {
          document.querySelectorAll('.admin-profile-container').forEach(function(c) {
            c.classList.remove('dropdown-open');
          });
        });
      }

      initDashboardMobile();
      document.addEventListener('shiny:connected', initDashboardMobile);
      $(document).on('shiny:value', function(event) {
        if (event.name === 'page') setTimeout(initDashboardMobile, 50);
      });
    })();
  "))
}

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
    dashboard_mobile_script()
    )
  )
}

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
                                 # Left Column: Contact Details
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
                                 
                                 # Right Column: Security
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
      dashboard_mobile_script()
    )
  )
}

# -------------------------------------------------------------
# MAIN UI
# -------------------------------------------------------------

ui <- fluidPage(
  title = "PulseGrid",
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1, maximum-scale=5"),
    tags$style(app_styles),
    tags$link(rel = "preload", href = "hello.jpg", as = "image"),
    tags$link(rel = "preload", href = "hello2.mp4", as = "video", type = "video/mp4"),
    tags$link(rel = "preload", href = "Video.mp4", as = "video", type = "video/mp4")
  ),
  uiOutput("page")
)

# -------------------------------------------------------------
# SERVER
# -------------------------------------------------------------

server <- function(input, output, session) {
  
  auth <- reactiveValues(
    logged_in = FALSE,
    role = NULL,
    id = NULL,
    name = NULL,
    email = NULL,
    phone = NULL,
    must_change_password = FALSE
  )
  
  login_error <- reactiveVal(NULL)
  change_password_error <- reactiveVal(NULL)
  
  # --- Login attempt ---
  observeEvent(input$login_btn, {
    email <- trimws(input$login_email)
    password <- input$login_password
    
    result <- tryCatch({
      admin_result <- check_admin_login(email, password)
      if (is.null(admin_result)) {
        check_technician_login(email, password)
      } else {
        admin_result
      }
    }, error = function(e) {
      login_error(paste("Connection error:", conditionMessage(e)))
      NULL
    })
    
    if (is.null(result)) {
      if (is.null(login_error())) login_error("Invalid email or password.")
      return()
    }
    
    login_error(NULL)
    removeModal()
    auth$logged_in <- TRUE
    auth$role <- result$role
    auth$id <- result$id
    auth$name <- result$name
    auth$email <- result$email
    auth$phone <- result$phone
    auth$must_change_password <- isTRUE(result$must_change_password)
  })
  
  # --- Forced password change (technicians, first login) ---
  observeEvent(input$change_password_btn, {
    new_pw <- input$new_password
    confirm_pw <- input$confirm_password
    
    if (nchar(new_pw) < 6) {
      change_password_error("Password must be at least 6 characters.")
      return()
    }
    if (new_pw != confirm_pw) {
      change_password_error("Passwords don't match.")
      return()
    }
    
    tryCatch({
      set_new_technician_password(auth$id, new_pw)
      change_password_error(NULL)
      auth$must_change_password <- FALSE
    }, error = function(e) {
      change_password_error(paste("Could not update password:", conditionMessage(e)))
    })
  })
  
  show_login_modal <- function(error_msg = NULL) {
    showModal(modalDialog(
      title = NULL,
      easyClose = TRUE,
      footer = NULL,
      tags$div(class = "landing-auth-card", style = "padding: 20px 10px; border-radius: 12px;",
        tags$div(class = "auth-card-header",
          tags$h3("Operational Login"),
          tags$p("Sign in with your REG operational credentials")
        ),
        tags$div(class = "form-group-custom",
          tags$label("Email Address"),
          tags$div(class = "input-with-icon",
            bs_icon("envelope-fill"),
            textInput("login_email", label = NULL, placeholder = "name@reg.rw")
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
        if (!is.null(error_msg)) {
          tags$div(class = "auth-error",
            bs_icon("exclamation-circle-fill"), error_msg
          )
        }
      )
    ))
  }

  observeEvent(input$nav_login_btn, { show_login_modal() })
  observeEvent(input$hero_login_btn, { show_login_modal() })
  observeEvent(input$cta_login_btn, { show_login_modal() })

  # --- Logout ---
  observeEvent(input$logout_btn, {
    auth$logged_in <- FALSE
    auth$role <- NULL
    auth$id <- NULL
    auth$name <- NULL
    auth$email <- NULL
    auth$phone <- NULL
    auth$must_change_password <- FALSE
    login_error(NULL)
  })
  
  # --- Page router ---
  output$page <- renderUI({
    if (!auth$logged_in) {
      reg_landing_ui()
    } else if (auth$role == "technician" && auth$must_change_password) {
      change_password_ui(change_password_error())
    } else if (auth$role == "admin") {
      admin_dashboard_ui(auth$name)
    } else if (auth$role == "technician") {
      technician_dashboard_ui(list(id = auth$id, name = auth$name, email = auth$email, phone = auth$phone))
    }
  })
  
  # -----------------------------------------------------------
  # Everything below only actually gets used once the admin
  # dashboard is rendered — safe to leave defined unconditionally.
  # -----------------------------------------------------------
  
  ticket_data <- reactivePoll(
    intervalMillis = 30000,
    session        = session,
    checkFunc      = function() {
      # Only poll when the admin dashboard is actually visible.
      # Returning a fixed string keeps checkFunc's value constant
      # (never changes) so valueFunc is never triggered on the landing page.
      if (!isTRUE(auth$logged_in) || is.null(auth$role) || auth$role != "admin") {
        return("idle")
      }
      as.character(Sys.time())
    },
    valueFunc      = function() {
      tryCatch(
        load_tickets(),
        error = function(e) {
          showNotification(
            paste("Could not connect to the database:", conditionMessage(e)),
            type = "error",
            duration = NULL
          )
          data.frame()
        }
      )
    }
  )
  
  filtered_data <- reactive({
    data <- ticket_data()
    req(nrow(data) > 0)
    
    if (!is.null(input$region_filter) && input$region_filter != "All") {
      data <- data %>% filter(region == input$region_filter)
    }
    if (!is.null(input$status_filter) && input$status_filter != "All") {
      data <- data %>% filter(status == input$status_filter)
    }
    if (!is.null(input$urgency_filter) && input$urgency_filter != "All") {
      data <- data %>% filter(urgency == input$urgency_filter)
    }
    data
  })
  
  output$total_count <- renderText({
    tryCatch(nrow(filtered_data()), error = function(e) 0)
  })
  
  output$open_count <- renderText({
    tryCatch(filtered_data() %>% filter(status != "Resolved") %>% nrow(), error = function(e) 0)
  })
  
  output$urgent_count <- renderText({
    tryCatch(filtered_data() %>% filter(urgency == "High") %>% nrow(), error = function(e) 0)
  })
  
  output$safety_count <- renderText({
    tryCatch({
      data <- filtered_data()
      if (!"safety_flag" %in% names(data)) return(0)
      data %>% filter(safety_flag == "Yes") %>% nrow()
    }, error = function(e) 0)
  })
  
  output$region_plot <- renderEcharts4r({
    req(nrow(filtered_data()) > 0)
    filtered_data() %>%
      count(region) %>%
      arrange(desc(n)) %>%
      e_charts(region) %>%
      e_bar(n, name = "Count") %>%
      e_title("Tickets by Region") %>%
      e_tooltip(trigger = "axis") %>%
      e_legend(show = FALSE)
  })
  
  output$status_plot <- renderEcharts4r({
    req(nrow(filtered_data()) > 0)
    filtered_data() %>%
      count(status) %>%
      e_charts(status) %>%
      e_bar(n, name = "Count") %>%
      e_title("Tickets by Status") %>%
      e_tooltip(trigger = "axis") %>%
      e_legend(show = FALSE)
  })
  
  output$ticket_table <- renderDT({
    req(nrow(filtered_data()) >= 0)
    data <- filtered_data() %>% arrange(desc(created_at))
    
    display_cols <- intersect(
      c("ticket_id", "name", "phone", "email", "region", "time_window",
        "status", "urgency", "safety_flag", "technician", "description",
        "urgency_reason", "created_at"),
      names(data)
    )
    data <- data[, display_cols]
    
    dt <- datatable(
      data,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        autoWidth = TRUE,
        dom = "lfrtip"
      ),
      rownames = FALSE,
      class = "cell-border stripe nowrap compact"
    )
    
    if ("urgency" %in% names(data)) {
      dt <- dt %>% formatStyle(
        "urgency",
        backgroundColor = styleEqual(
          c("Low", "Medium", "High"),
          c("#dcfce7", "#fef9c3", "#fee2e2")
        ),
        fontWeight = "bold"
      )
    }
    
    if ("safety_flag" %in% names(data)) {
      dt <- dt %>% formatStyle(
        "safety_flag",
        target = "row",
        backgroundColor = styleEqual("Yes", "#fef2f2")
      )
    }
    
    dt
  })
  
  # -----------------------------------------------------------
  # TECHNICIAN DASHBOARD
  # -----------------------------------------------------------
  
  technician_tickets <- reactivePoll(
    intervalMillis = 30000,
    session        = session,
    checkFunc      = function() Sys.time(),
    valueFunc      = function() {
      req(auth$role == "technician")
      tryCatch(
        load_technician_tickets(auth$email),
        error = function(e) {
          showNotification(paste("Could not load your tickets:", conditionMessage(e)), type = "error")
          data.frame()
        }
      )
    }
  )
  
  output$tech_status_donut <- renderEcharts4r({
    req(auth$role == "technician")
    data <- technician_tickets()
    req(nrow(data) > 0)
    
    data %>%
      count(status) %>%
      e_charts(status) %>%
      e_pie(n, radius = c("50%", "70%")) %>%
      e_tooltip(trigger = "item")
  })
  
  output$tech_recent_activity <- renderUI({
    req(auth$role == "technician")
    data <- technician_tickets()
    
    if (nrow(data) == 0) {
      return(tags$p("No tickets assigned to you yet.", style = "color:#64748b;"))
    }
    
    recent <- head(data, 5)
    
    tagList(lapply(seq_len(nrow(recent)), function(i) {
      row <- recent[i, ]
      badge_color <- switch(row$status,
                            "new" = "#f59e0b", "New" = "#f59e0b",
                            "In Progress" = "#3b82f6",
                            "Resolved" = "#22c55e",
                            "#94a3b8"
      )
      tags$div(style = "padding: 10px 0; border-bottom: 1px solid #e2e8f0;",
               tags$div(style = paste0("display:inline-block; width:8px; height:8px; border-radius:50%; background:", badge_color, "; margin-right:8px;")),
               tags$strong(paste0("#", row$ticket_id)), " — ", row$region,
               tags$br(),
               tags$span(style = "color:#64748b; font-size: 12px;", paste(row$status, "•", row$urgency, "•", row$time_window))
      )
    }))
  })
  
  output$notif_badge <- renderText({
    req(auth$role == "technician")
    data <- technician_tickets()
    if (nrow(data) == 0) return(" 0")
    n_new <- sum(data$status %in% c("new", "New"))
    paste0(" ", n_new)
  })
  
  observeEvent(input$notif_bell, {
    req(auth$role == "technician")
    data <- technician_tickets()
    new_tickets <- data[data$status %in% c("new", "New"), , drop = FALSE]
    
    body <- if (nrow(new_tickets) == 0) {
      tags$p("No new tickets right now.")
    } else {
      tagList(lapply(seq_len(nrow(new_tickets)), function(i) {
        row <- new_tickets[i, ]
        tags$div(style = "padding: 8px 0; border-bottom: 1px solid #e2e8f0;",
                 tags$strong(paste0("#", row$ticket_id)), " — ", row$region, " (", row$urgency, ")"
        )
      }))
    }
    
    showModal(modalDialog(title = "New tickets", body, easyClose = TRUE))
  })
  
  # --- Profile: save email/phone ---
  observeEvent(input$save_profile_btn, {
    req(auth$role == "technician")
    tryCatch({
      update_technician_profile(auth$id, trimws(input$profile_email), trimws(input$profile_phone))
      auth$email <- trimws(input$profile_email)
      auth$phone <- trimws(input$profile_phone)
      output$profile_save_message <- renderUI(tags$p(style = "color:#16a34a;", "Saved."))
    }, error = function(e) {
      output$profile_save_message <- renderUI(tags$p(style = "color:#b91c1c;", paste("Could not save:", conditionMessage(e))))
    })
  })
  
  # --- Profile: change password (requires current password) ---
  observeEvent(input$save_password_btn, {
    req(auth$role == "technician")
    
    if (!verify_technician_password(auth$id, input$current_password)) {
      output$password_save_message <- renderUI(tags$p(style = "color:#b91c1c;", "Current password is incorrect."))
      return()
    }
    if (nchar(input$profile_new_password) < 6) {
      output$password_save_message <- renderUI(tags$p(style = "color:#b91c1c;", "New password must be at least 6 characters."))
      return()
    }
    if (input$profile_new_password != input$profile_confirm_password) {
      output$password_save_message <- renderUI(tags$p(style = "color:#b91c1c;", "New passwords don't match."))
      return()
    }
    
    tryCatch({
      update_technician_password(auth$id, input$profile_new_password)
      output$password_save_message <- renderUI(tags$p(style = "color:#16a34a;", "Password updated."))
    }, error = function(e) {
      output$password_save_message <- renderUI(tags$p(style = "color:#b91c1c;", paste("Could not update password:", conditionMessage(e))))
    })
  })
}

shinyApp(ui = ui, server = server)