// PulseGrid landing page: hero videos, headline animation, scroll reveal
window.PulseGrid = window.PulseGrid || {};

PulseGrid.bootLanding = function () {
  if (!document.querySelector('.reg-hero')) return;
  PulseGrid.initLanding();
};

PulseGrid.initLanding = function () {
  PulseGrid.initLandingVideos();
  PulseGrid.initLandingHeadline();
  PulseGrid.initLandingScrollMotion();
  PulseGrid.initNavScroll();
};

PulseGrid.initLandingVideos = function () {
  var HERO_RATES = { 'hero-vid-1': 1.5, 'hero-vid-2': 1.5 };
  var FADE_MS = 900;

  var hero = document.querySelector('.reg-hero');
  var v1 = document.getElementById('hero-vid-1');
  var v2 = document.getElementById('hero-vid-2');
  if (!hero || !v1 || !v2) return;
  if (hero.dataset.videosInit === '1') return;
  hero.dataset.videosInit = '1';

  var videos = [v1, v2];
  var activeIdx = 0;
  var switching = false;
  var started = false;
  var switchTimer = null;

  videos.forEach(function (video) {
    video.muted = true;
    video.defaultMuted = true;
    video.playsInline = true;
    video.setAttribute('muted', '');
    video.setAttribute('playsinline', '');
    video.setAttribute('webkit-playsinline', '');
    video.preload = 'auto';
    video.loop = false;
    video.playbackRate = HERO_RATES[video.id] || 1;
    video.addEventListener('error', function () {
      var poster = document.querySelector('.reg-hero-poster');
      if (poster) poster.classList.remove('is-hidden');
    });
  });

  function getActive() { return videos[activeIdx]; }
  function getStandby() { return videos[1 - activeIdx]; }

  function safePlay(video) {
    if (!video) return Promise.resolve();
    var playPromise = video.play();
    if (playPromise && typeof playPromise.then === 'function') {
      return playPromise.catch(function () {});
    }
    return Promise.resolve();
  }

  function clearSwitchTimer() {
    if (switchTimer) {
      clearTimeout(switchTimer);
      switchTimer = null;
    }
  }

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

    safePlay(standby).then(function () {
      standby.classList.add('is-visible');
      active.classList.remove('is-visible');

      setTimeout(function () {
        active.pause();
        active.currentTime = 0;
        activeIdx = 1 - activeIdx;
        switching = false;
        scheduleNextSwitch(getActive());
      }, FADE_MS);
    }).catch(function () {
      switching = false;
      scheduleNextSwitch(getActive());
    });
  }

  videos.forEach(function (video) {
    video.addEventListener('ended', function () {
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
    safePlay(v1).then(function () {
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
    setTimeout(done, 4000);
  }

  v1.load();
  v2.load();
  waitForFirstFrame(v1, startPlayback);

  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) {
      var active = getActive();
      safePlay(active);
      scheduleNextSwitch(active);
    }
  });

  document.addEventListener('click', function kickstart() {
    var active = getActive();
    safePlay(active);
    if (!started) startPlayback();
    else if (!switchTimer) scheduleNextSwitch(active);
    document.removeEventListener('click', kickstart);
  }, { once: true });

  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          safePlay(getActive());
          if (!started) startPlayback();
          observer.disconnect();
        }
      });
    }, { threshold: 0.2 });
    observer.observe(hero);
  }
};

PulseGrid.initLandingHeadline = function () {
  var line1 = document.getElementById('figma-line-1');
  var line2 = document.getElementById('figma-line-2');
  var line3 = document.getElementById('figma-line-3');
  if (!line1 || !line2 || !line3) return;
  if (line1.dataset.headlineInit === '1') return;
  line1.dataset.headlineInit = '1';

  var phrases = [
    { l1: 'Power Problems?', l2: 'Report Them Once.', l3: "We'll Take It From Here." },
    { l1: 'Transformer Tripped?', l2: 'Instant Dispatch.', l3: 'Technicians On The Way.' },
    { l1: 'Grid Disruption?', l2: 'Real-Time Tracking.', l3: 'Restoration Guaranteed.' },
    { l1: 'Blackout in Area?', l2: 'One-Click Report.', l3: 'We Keep Rwanda Powered.' }
  ];
  var index = 0;

  setInterval(function () {
    index = (index + 1) % phrases.length;
    var next = phrases[index];

    line1.classList.add('swap-out');
    setTimeout(function () { line2.classList.add('swap-out'); }, 220);
    setTimeout(function () { line3.classList.add('swap-out'); }, 440);

    setTimeout(function () {
      line1.innerText = next.l1;
      line2.innerText = next.l2;
      line3.innerText = next.l3;

      line1.classList.remove('swap-out'); line1.classList.add('swap-in');
      line2.classList.remove('swap-out'); line2.classList.add('swap-in');
      line3.classList.remove('swap-out'); line3.classList.add('swap-in');

      requestAnimationFrame(function () {
        setTimeout(function () { line1.classList.remove('swap-in'); }, 80);
        setTimeout(function () { line2.classList.remove('swap-in'); }, 300);
        setTimeout(function () { line3.classList.remove('swap-in'); }, 520);
      });
    }, 850);
  }, 4600);
};

PulseGrid.initLandingScrollMotion = function () {
  var cards = document.querySelectorAll('.reg-card:not([data-scroll-init])');
  if (!cards.length) return;

  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add('scroll-animated');
      }
    });
  }, { threshold: 0.15 });

  cards.forEach(function (card) {
    card.dataset.scrollInit = '1';
    observer.observe(card);
  });
};

PulseGrid.initNavScroll = function () {
  if (!PulseGrid._navScrollBound) {
    PulseGrid._navScrollBound = true;
    window.addEventListener('scroll', function () {
      var header = document.querySelector('.reg-header');
      if (!header) return;
      if (window.scrollY > 30) header.classList.add('nav-scrolled');
      else header.classList.remove('nav-scrolled');
    }, { passive: true });
  }

  var header = document.querySelector('.reg-header');
  if (!header) return;
  if (window.scrollY > 30) header.classList.add('nav-scrolled');
  else header.classList.remove('nav-scrolled');
};

document.addEventListener('DOMContentLoaded', PulseGrid.bootLanding);
document.addEventListener('shiny:connected', PulseGrid.bootLanding);

if (window.jQuery) {
  jQuery(document).on('shiny:value', function (event) {
    if (event.name === 'page') {
      setTimeout(PulseGrid.bootLanding, 0);
    }
  });
}

// ── PulseGrid Chatbot Widget ────────────────────────────────────────────────
PulseGrid.initChat = function () {
  var widget  = document.getElementById('pg-chat-widget');
  var toggle  = document.getElementById('pg-chat-toggle');
  var closeBtn = document.getElementById('pg-chat-close');
  var window_ = document.getElementById('pg-chat-window');
  var msgs    = document.getElementById('pg-chat-messages');
  var typing  = document.getElementById('pg-chat-typing');
  var input   = document.getElementById('pg-chat-input');
  var sendBtn = document.getElementById('pg-chat-send');

  if (!widget || !toggle || !msgs || !input || !sendBtn) return;
  if (widget.dataset.chatInit === '1') return;
  widget.dataset.chatInit = '1';

  var isOpen = false;

  // ── open / close ──────────────────────────────────────────────
  function openChat() {
    isOpen = true;
    widget.classList.add('pg-chat-open');
    input.focus();
    scrollToBottom();
  }
  function closeChat() {
    isOpen = false;
    widget.classList.remove('pg-chat-open');
  }
  function toggleChat() { isOpen ? closeChat() : openChat(); }

  toggle.addEventListener('click', toggleChat);
  if (closeBtn) closeBtn.addEventListener('click', closeChat);

  // Close on ESC
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && isOpen) closeChat();
  });

  // ── scroll helpers ────────────────────────────────────────────
  function scrollToBottom() {
    msgs.scrollTop = msgs.scrollHeight;
  }

  // ── timestamp helper ──────────────────────────────────────────
  function nowLabel() {
    var d = new Date();
    var h = d.getHours(), m = d.getMinutes();
    return (h < 10 ? '0' : '') + h + ':' + (m < 10 ? '0' : '') + m;
  }

  // ── append a message bubble ───────────────────────────────────
  function appendMsg(text, role) {
    var row = document.createElement('div');
    row.className = 'pg-chat-msg pg-chat-msg-' + role;

    var bubble = document.createElement('div');
    bubble.className = 'pg-chat-bubble';
    bubble.textContent = text;

    var time = document.createElement('div');
    time.className = 'pg-chat-time';
    time.textContent = nowLabel();

    row.appendChild(bubble);
    row.appendChild(time);
    msgs.appendChild(row);
    scrollToBottom();
    return row;
  }

  // ── typing indicator ──────────────────────────────────────────
  function showTyping() {
    typing.classList.remove('pg-hidden');
    scrollToBottom();
  }
  function hideTyping() {
    typing.classList.add('pg-hidden');
  }

  // ── send message ──────────────────────────────────────────────
  function sendMessage(text) {
    text = (text || input.value).trim();
    if (!text) return;

    // Remove chips after first user message
    var chips = msgs.querySelector('.pg-chat-chips');
    if (chips) chips.remove();

    appendMsg(text, 'user');
    input.value = '';
    autoResizeInput();
    sendBtn.disabled = true;
    showTyping();

    // ── Send to Shiny backend ──────────────────────────────────
    // Your server.R / server_admin.R can observe input$pg_chat_message
    if (window.Shiny && Shiny.setInputValue) {
      Shiny.setInputValue('pg_chat_message', text, { priority: 'event' });
    }

    // ── Fallback: simple keyword responses (until backend replies) ──
    setTimeout(function () {
      hideTyping();
      var reply = PulseGrid.chatFallback(text);
      appendMsg(reply, 'bot');
      sendBtn.disabled = false;
    }, 900 + Math.random() * 600);
  }

  // ── auto-resize textarea ──────────────────────────────────────
  function autoResizeInput() {
    input.style.height = 'auto';
    input.style.height = Math.min(input.scrollHeight, 120) + 'px';
  }

  input.addEventListener('input', function () {
    autoResizeInput();
    sendBtn.disabled = input.value.trim() === '';
  });

  // Initial state: send button disabled
  sendBtn.disabled = true;

  // Send on button click
  sendBtn.addEventListener('click', function () { sendMessage(); });

  // Send on Enter (Shift+Enter = new line)
  input.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      if (!sendBtn.disabled) sendMessage();
    }
  });

  // ── Quick-reply chips ──────────────────────────────────────────
  msgs.addEventListener('click', function (e) {
    if (e.target.classList.contains('pg-chat-chip')) {
      sendMessage(e.target.textContent);
    }
  });

  // ── Receive bot reply from Shiny ──────────────────────────────
  // In your server.R, use:
  //   session$sendCustomMessage('pg_chat_reply', list(text = "Your reply here"))
  if (window.Shiny) {
    Shiny.addCustomMessageHandler('pg_chat_reply', function (data) {
      hideTyping();
      appendMsg(data.text, 'bot');
      sendBtn.disabled = false;
    });
  }
};

// ── Keyword fallback responses ────────────────────────────────────────────
PulseGrid.chatFallback = function (text) {
  var t = text.toLowerCase();
  if (/report|outage|power|electricity|blackout|light/.test(t)) {
    return '⚡ To report an outage, click the "Report an Outage" button on this page or visit our reporting form. You\'ll receive a unique ticket ID immediately.';
  }
  if (/track|ticket|status|id|check/.test(t)) {
    return '🔍 You can track your ticket by logging into the portal using the "Track My Report / Login" button above. Have your ticket ID ready.';
  }
  if (/safety|emergency|fire|spark|shock|smoke|danger/.test(t)) {
    return '🚨 SAFETY EMERGENCY — Please call REG Emergency Line immediately: +250 788 300 000. Do NOT touch any electrical equipment. Your report will be flagged as HIGH urgency automatically.';
  }
  if (/contact|phone|call|email|reg/.test(t)) {
    return '📞 Rwanda Energy Group (REG) contacts:\n• Emergency: +250 788 300 000\n• Customer care: +250 252 570 720\n• Email: info@reg.rw\n• Website: www.reg.rw';
  }
  if (/region|kigali|huye|musanze|rubavu|nyagatare/.test(t)) {
    return '📍 PulseGrid covers all five major regions: Kigali, Huye, Musanze, Rubavu, and Nyagatare. Select your region when submitting your report.';
  }
  if (/hello|hi|hey|bonjour|muraho/.test(t)) {
    return '👋 Hello! How can I assist you today? You can report an outage, track a ticket, or ask me anything about electricity services in Rwanda.';
  }
  return '🤖 Thank you for reaching out! For instant help or outage reporting, please click the "Report an Outage" button above or call REG Customer Care at +250 252 570 720.';
};


// Boot chatbot on page load and after Shiny re-renders
document.addEventListener('DOMContentLoaded', PulseGrid.initChat);
document.addEventListener('shiny:connected', PulseGrid.initChat);
if (window.jQuery) {
  jQuery(document).on('shiny:value', function (e) {
    if (e.name === 'page') setTimeout(PulseGrid.initChat, 0);
  });
}
// ── End Chatbot Widget ──────────────────────────────────────────────────────
