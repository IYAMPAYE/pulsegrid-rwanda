// PulseGrid dashboard: sidebar toggle (desktop + mobile) + profile dropdown
(function () {
  function isMobileLayout() {
    return window.matchMedia('(max-width: 992px)').matches;
  }

  function getShell(el) {
    return el && el.closest ? el.closest('.dashboard-shell') : null;
  }

  function closeSidebar(shell) {
    if (!shell) return;
    shell.classList.remove('sidebar-open');
  }

  function toggleSidebar(shell) {
    if (!shell) return;
    if (isMobileLayout()) {
      shell.classList.toggle('sidebar-open');
      shell.classList.remove('sidebar-collapsed');
    } else {
      shell.classList.toggle('sidebar-collapsed');
      shell.classList.remove('sidebar-open');
    }
  }

  function initDashboardShell() {
    $(document)
      .off('click.dashboardMenu', '#dashboard_menu_btn')
      .on('click.dashboardMenu', '#dashboard_menu_btn', function (e) {
        e.preventDefault();
        e.stopPropagation();
        toggleSidebar(getShell(this));
      });

    $(document)
      .off('click.dashboardBackdrop', '.sidebar-backdrop')
      .on('click.dashboardBackdrop', '.sidebar-backdrop', function () {
        closeSidebar(getShell(this));
      });

    $(document)
      .off('click.dashboardNav', '.custom-sidebar .nav-item')
      .on('click.dashboardNav', '.custom-sidebar .nav-item', function () {
        if (isMobileLayout()) closeSidebar(getShell(this));
      });

    $(document)
      .off('click.adminNav', '.admin-nav-link')
      .on('click.adminNav', '.admin-nav-link', function () {
        document.querySelectorAll('.admin-nav-link').forEach(function (link) {
          link.classList.remove('active');
        });
        this.classList.add('active');
        if (isMobileLayout()) closeSidebar(getShell(this));
      });

    if (window.Shiny && !window.PulseGrid._adminNavHandler) {
      window.PulseGrid = window.PulseGrid || {};
      Shiny.addCustomMessageHandler('adminNavActive', function (msg) {
        if (!msg || !msg.section) return;
        document.querySelectorAll('.admin-nav-link').forEach(function (link) {
          link.classList.remove('active');
        });
        var map = {
          overview: 'admin_nav_overview',
          operations: 'admin_nav_operations',
          analytics: 'admin_nav_analytics',
          gis: 'admin_nav_gis'
        };
        var id = map[msg.section];
        if (id) {
          var el = document.getElementById(id);
          if (el) el.classList.add('active');
        }
      });
      window.PulseGrid._adminNavHandler = true;
    }

    $(document)
      .off('click.dashboardProfile', '.admin-profile-trigger')
      .on('click.dashboardProfile', '.admin-profile-trigger', function (e) {
        e.stopPropagation();
        var container = this.closest('.admin-profile-container');
        if (!container) return;
        var open = container.classList.contains('dropdown-open');
        document.querySelectorAll('.admin-profile-container').forEach(function (c) {
          c.classList.remove('dropdown-open');
        });
        if (!open) container.classList.add('dropdown-open');
      });

    $(document)
      .off('click.adminProfileMenu', '.admin-profile-dropdown .dropdown-link-item, .admin-profile-dropdown .dropdown-signout')
      .on('click.adminProfileMenu', '.admin-profile-dropdown .dropdown-link-item, .admin-profile-dropdown .dropdown-signout', function () {
        document.querySelectorAll('.admin-profile-container').forEach(function (c) {
          c.classList.remove('dropdown-open');
        });
      });

    $(document)
      .off('shown.bs.modal.teamConfig hidden.bs.modal.teamConfig')
      .on('shown.bs.modal.teamConfig', function (e) {
        var modal = e.target;
        if (!modal.querySelector('.admin-team-modal')) return;
        modal.classList.add('admin-team-modal-dialog');
        setTimeout(function () {
          $(window).trigger('resize');
          if ($.fn.dataTable) {
            $.fn.dataTable.tables({ visible: true, api: true }).columns.adjust().draw(false);
          }
        }, 120);
      })
      .on('hidden.bs.modal.teamConfig', function (e) {
        e.target.classList.remove('admin-team-modal-dialog');
      });

    $(document)
      .off('click.dashboardProfileClose')
      .on('click.dashboardProfileClose', function () {
        document.querySelectorAll('.admin-profile-container').forEach(function (c) {
          c.classList.remove('dropdown-open');
        });
      });

    $(window)
      .off('resize.dashboardShell')
      .on('resize.dashboardShell', function () {
        document.querySelectorAll('.dashboard-shell').forEach(function (shell) {
          if (!isMobileLayout()) {
            shell.classList.remove('sidebar-open');
          } else {
            shell.classList.remove('sidebar-collapsed');
          }
        });
      });
  }

  initDashboardShell();
  document.addEventListener('shiny:connected', initDashboardShell);
  if (window.jQuery) {
    jQuery(document).on('shiny:value', function (event) {
      if (event.name === 'page') setTimeout(initDashboardShell, 50);
    });
  }
})();
