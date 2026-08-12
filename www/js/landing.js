// PulseGrid landing page: hero videos, headline animation, scroll reveal
window.PulseGrid = window.PulseGrid || {};

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
    if (!switchTimer) scheduleNextSwitch(active);
    document.removeEventListener('click', kickstart);
  }, { once: true });
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
  var header = document.querySelector('.reg-header');
  if (!header || header.dataset.navScrollInit === '1') return;
  header.dataset.navScrollInit = '1';

  window.addEventListener('scroll', function () {
    if (window.scrollY > 30) {
      header.classList.add('nav-scrolled');
    } else {
      header.classList.remove('nav-scrolled');
    }
  }, { passive: true });
};
