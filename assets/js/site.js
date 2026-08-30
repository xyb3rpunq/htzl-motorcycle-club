/*!
 * HTZL Motorcycle Club - perilaku situs global.
 * Vanilla JavaScript, tanpa pustaka pihak ketiga.
 */
(function () {
  "use strict";

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var $ = function (sel, root) { return (root || document).querySelector(sel); };
  var $$ = function (sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); };

  /* ------------------------------------------------------------------ *
   * Tema terang/gelap
   * ------------------------------------------------------------------ */
  function initTheme() {
    var toggle = $("[data-theme-toggle]");
    if (!toggle) return;

    toggle.addEventListener("click", function () {
      var next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
      document.documentElement.dataset.theme = next;
      try { localStorage.setItem("htzl-theme", next); } catch (e) { /* mode privat */ }
      toggle.setAttribute("aria-pressed", String(next === "dark"));
    });
  }

  /* ------------------------------------------------------------------ *
   * Menu mobile
   * ------------------------------------------------------------------ */
  function initNav() {
    var toggle = $("[data-nav-toggle]");
    var nav = $("#site-nav");
    var scrim = $("[data-nav-scrim]");
    if (!toggle || !nav) return;

    function setOpen(open) {
      nav.dataset.open = String(open);
      toggle.setAttribute("aria-expanded", String(open));
      if (scrim) {
        scrim.dataset.open = String(open);
        scrim.hidden = !open;
      }
      document.body.style.overflow = open && window.innerWidth <= 900 ? "hidden" : "";
    }

    toggle.addEventListener("click", function () {
      setOpen(nav.dataset.open !== "true");
    });

    if (scrim) scrim.addEventListener("click", function () { setOpen(false); });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && nav.dataset.open === "true") {
        setOpen(false);
        toggle.focus();
      }
    });

    // Tutup drawer saat berpindah ke tata letak desktop.
    window.addEventListener("resize", function () {
      if (window.innerWidth > 900) setOpen(false);
    });
  }

  /* ------------------------------------------------------------------ *
   * Dropdown (produk dan pemilih bahasa)
   * ------------------------------------------------------------------ */
  function initDropdowns() {
    var dropdowns = $$("[data-dropdown]");
    if (!dropdowns.length) return;

    function closeAll(except) {
      dropdowns.forEach(function (dd) {
        if (dd === except) return;
        dd.dataset.open = "false";
        var btn = $("[data-dropdown-toggle]", dd);
        if (btn) btn.setAttribute("aria-expanded", "false");
      });
    }

    dropdowns.forEach(function (dd) {
      var btn = $("[data-dropdown-toggle]", dd);
      if (!btn) return;

      btn.addEventListener("click", function (event) {
        event.stopPropagation();
        var open = dd.dataset.open !== "true";
        closeAll(dd);
        dd.dataset.open = String(open);
        btn.setAttribute("aria-expanded", String(open));
      });
    });

    document.addEventListener("click", function () { closeAll(null); });
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") closeAll(null);
    });
  }

  /* ------------------------------------------------------------------ *
   * Hero slider berbasis scroll-snap.
   * Menggeser dengan jari sudah didukung browser secara native, jadi
   * JavaScript hanya mengurus tombol, titik indikator, dan putar otomatis.
   * ------------------------------------------------------------------ */
  function initHero() {
    var track = $("[data-hero-track]");
    if (!track) return;

    var slides = $$(".hero__slide", track);
    var dots = $$("[data-hero-dot]");
    var prev = $("[data-hero-prev]");
    var next = $("[data-hero-next]");
    var current = 0;
    var timer = null;

    function goTo(index, smooth) {
      current = (index + slides.length) % slides.length;
      track.scrollTo({
        left: slides[current].offsetLeft - track.offsetLeft,
        behavior: smooth === false || reduceMotion ? "auto" : "smooth"
      });
    }

    function syncDots() {
      dots.forEach(function (dot, i) {
        if (i === current) dot.setAttribute("aria-current", "true");
        else dot.removeAttribute("aria-current");
      });
    }

    // Slide aktif ditentukan dari posisi gulir sebenarnya, bukan tebakan.
    var ticking = false;
    track.addEventListener("scroll", function () {
      if (ticking) return;
      ticking = true;
      window.requestAnimationFrame(function () {
        var width = slides[0] ? slides[0].offsetWidth : 1;
        var index = Math.round(track.scrollLeft / width);
        if (index !== current && index >= 0 && index < slides.length) {
          current = index;
          syncDots();
        }
        ticking = false;
      });
    }, { passive: true });

    if (prev) prev.addEventListener("click", function () { goTo(current - 1); restart(); });
    if (next) next.addEventListener("click", function () { goTo(current + 1); restart(); });

    dots.forEach(function (dot, i) {
      dot.addEventListener("click", function () { goTo(i); restart(); });
    });

    track.addEventListener("keydown", function (event) {
      if (event.key === "ArrowLeft") { goTo(current - 1); restart(); }
      if (event.key === "ArrowRight") { goTo(current + 1); restart(); }
    });

    function start() {
      if (reduceMotion || slides.length < 2) return;
      stop();
      timer = window.setInterval(function () {
        if (document.hidden) return;
        goTo(current + 1);
      }, 6500);
    }
    function stop() { if (timer) { window.clearInterval(timer); timer = null; } }
    function restart() { stop(); start(); }

    var hero = track.closest(".hero");
    if (hero) {
      hero.addEventListener("mouseenter", stop);
      hero.addEventListener("mouseleave", start);
      hero.addEventListener("focusin", stop);
      hero.addEventListener("focusout", start);
    }
    document.addEventListener("visibilitychange", function () {
      if (document.hidden) stop(); else start();
    });

    syncDots();
    start();
  }

  /* ------------------------------------------------------------------ *
   * Animasi muncul saat digulir
   * ------------------------------------------------------------------ */
  function initReveal() {
    var targets = $$(".reveal");
    if (!targets.length) return;

    if (reduceMotion || !("IntersectionObserver" in window)) {
      targets.forEach(function (el) { el.dataset.visible = "true"; });
      return;
    }

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.dataset.visible = "true";
        observer.unobserve(entry.target);
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });

    targets.forEach(function (el) { observer.observe(el); });
  }

  /* ------------------------------------------------------------------ *
   * Lightbox galeri
   * ------------------------------------------------------------------ */
  function initLightbox() {
    var dialog = $("#lightbox");
    var gallery = $("[data-gallery]");
    if (!dialog || !gallery || typeof dialog.showModal !== "function") return;

    var items = $$(".gallery-item", gallery);
    var img = $("[data-lightbox-img]", dialog);
    var caption = $("[data-lightbox-caption]", dialog);
    var index = 0;

    function show(i) {
      index = (i + items.length) % items.length;
      var item = items[index];
      img.src = item.dataset.full;
      img.alt = item.dataset.caption;
      caption.textContent = item.dataset.caption;
    }

    items.forEach(function (item, i) {
      item.addEventListener("click", function () {
        show(i);
        dialog.showModal();
      });
    });

    var prev = $("[data-lightbox-prev]", dialog);
    var next = $("[data-lightbox-next]", dialog);
    if (prev) prev.addEventListener("click", function () { show(index - 1); });
    if (next) next.addEventListener("click", function () { show(index + 1); });

    dialog.addEventListener("keydown", function (event) {
      if (event.key === "ArrowLeft") show(index - 1);
      if (event.key === "ArrowRight") show(index + 1);
    });

    dialog.addEventListener("close", function () {
      if (items[index]) items[index].focus();
    });

    initDialogDismiss(dialog);
  }

  /* ------------------------------------------------------------------ *
   * Perilaku dialog bersama: tombol tutup dan klik di luar isi
   * ------------------------------------------------------------------ */
  function initDialogDismiss(dialog) {
    $$("[data-dialog-close]", dialog).forEach(function (btn) {
      btn.addEventListener("click", function () { dialog.close(); });
    });

    dialog.addEventListener("click", function (event) {
      if (event.target === dialog) dialog.close();
    });
  }

  /* ------------------------------------------------------------------ *
   * Notifikasi ringkas
   * ------------------------------------------------------------------ */
  var toastTimer = null;
  function toast(message) {
    var el = $("[data-toast]");
    if (!el) return;
    var text = $("[data-toast-text]", el);
    if (text) text.textContent = message;
    el.dataset.show = "true";
    if (toastTimer) window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(function () { el.dataset.show = "false"; }, 3600);
  }

  /* ------------------------------------------------------------------ *
   * Antarmuka bersama untuk berkas skrip lain
   * ------------------------------------------------------------------ */
  window.HTZL = {
    $: $,
    $$: $$,
    toast: toast,
    initDialogDismiss: initDialogDismiss,
    reduceMotion: reduceMotion
  };

  function init() {
    initTheme();
    initNav();
    initDropdowns();
    initHero();
    initReveal();
    initLightbox();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
