// PulseGrid auth: login loading state and error feedback
window.PulseGrid = window.PulseGrid || {};

PulseGrid.initAuth = function () {
  if (PulseGrid._authInit) return;
  PulseGrid._authInit = true;

  $(document).on('click', '#login_btn', function (e) {
    var $btn = $(this);
    if ($btn.prop('disabled') || $btn.hasClass('is-loading')) {
      e.preventDefault();
      e.stopImmediatePropagation();
      return false;
    }
    PulseGrid.setLoginLoading(true);
  });

  $(document).on('keydown', '#login_email, #login_password', function (e) {
    if (e.key === 'Enter') {
      e.preventDefault();
      $('#login_btn').trigger('click');
    }
  });

  $(document).on('shown.bs.modal', function () {
    PulseGrid.clearLoginFeedback();
    PulseGrid.setLoginLoading(false);
  });

  $(document).on('mouseenter focusin', '#nav_login_btn, #hero_login_btn, #cta_login_btn', function () {
    if (window.Shiny && Shiny.setInputValue) {
      Shiny.setInputValue('login_prewarm', Date.now(), { priority: 'event' });
    }
  });
};

PulseGrid.setLoginLoading = function (loading) {
  var $btn = $('#login_btn');
  if (!$btn.length) return;

  if (loading) {
    $btn.prop('disabled', true).addClass('is-loading');
    PulseGrid.showLoginLoading();
  } else {
    $btn.prop('disabled', false).removeClass('is-loading');
  }
};

PulseGrid.showLoginLoading = function () {
  var $fb = $('#login-feedback');
  if (!$fb.length) return;

  $fb.html(
    '<div class="auth-loading">' +
      '<span class="auth-spinner" aria-hidden="true"></span>' +
      '<span>Signing in, please wait…</span>' +
    '</div>'
  );
};

PulseGrid.showLoginError = function (message) {
  var $fb = $('#login-feedback');
  if (!$fb.length) return;

  var safe = $('<div>').text(message || 'Sign in failed.').html();
  $fb.html(
    '<div class="auth-error" role="alert">' +
      '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true">' +
        '<path d="M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14zm0 1A8 8 0 1 1 8 0a8 8 0 0 1 0 16z"/>' +
        '<path d="M7.002 11a1 1 0 1 1 2 0 1 1 0 0 1-2 0zM7.1 4.995a.905.905 0 1 1 1.8 0l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 4.995z"/>' +
      '</svg>' +
      '<span>' + safe + '</span>' +
    '</div>'
  );
};

PulseGrid.clearLoginFeedback = function () {
  $('#login-feedback').empty();
};

$(document).on('shiny:connected', function () {
  PulseGrid.initAuth();

  Shiny.addCustomMessageHandler('loginComplete', function (msg) {
    if (msg && msg.success) {
      PulseGrid.setLoginLoading(false);
      PulseGrid.clearLoginFeedback();
      return;
    }

    PulseGrid.setLoginLoading(false);
    if (msg && msg.error) {
      PulseGrid.showLoginError(msg.error);
    }
  });
});
