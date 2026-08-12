// PulseGrid dashboard: mobile sidebar + profile dropdown
(function () {
  function initDashboardMobile() {
    var shell = document.querySelector('.dashboard-shell');
    if (!shell || shell.dataset.mobileInit === '1') return;
    shell.dataset.mobileInit = '1';

    var menuBtn = document.getElementById('dashboard_menu_btn');
    var backdrop = shell.querySelector('.sidebar-backdrop');

    function closeSidebar() { shell.classList.remove('sidebar-open'); }

    if (menuBtn) {
      menuBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        shell.classList.toggle('sidebar-open');
      });
    }
    if (backdrop) {
      backdrop.addEventListener('click', closeSidebar);
    }

    shell.querySelectorAll('.custom-sidebar .nav-item').forEach(function (item) {
      item.addEventListener('click', closeSidebar);
    });

    document.querySelectorAll('.admin-profile-container').forEach(function (container) {
      var trigger = container.querySelector('.admin-profile-trigger');
      if (!trigger || trigger.dataset.bound === '1') return;
      trigger.dataset.bound = '1';
      trigger.addEventListener('click', function (e) {
        e.stopPropagation();
        var open = container.classList.contains('dropdown-open');
        document.querySelectorAll('.admin-profile-container').forEach(function (c) {
          c.classList.remove('dropdown-open');
        });
        if (!open) container.classList.add('dropdown-open');
      });
    });

    document.addEventListener('click', function () {
      document.querySelectorAll('.admin-profile-container').forEach(function (c) {
        c.classList.remove('dropdown-open');
      });
    });
  }

  initDashboardMobile();
  document.addEventListener('shiny:connected', initDashboardMobile);
  if (window.jQuery) {
    jQuery(document).on('shiny:value', function (event) {
      if (event.name === 'page') setTimeout(initDashboardMobile, 50);
    });
  }
})();
