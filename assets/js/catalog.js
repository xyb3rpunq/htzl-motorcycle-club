/*!
 * HTZL Motorcycle Club - penyaringan, pengurutan, dan detail katalog.
 * Semua kartu sudah dirender saat build, jadi penyaringan hanya menyembunyikan
 * elemen di DOM: tidak ada permintaan jaringan dan tidak ada jeda.
 */
(function () {
  "use strict";

  var $ = window.HTZL.$;
  var $$ = window.HTZL.$$;

  var grid = $("[data-grid]");
  if (!grid) return;

  var cards = $$("[data-item]", grid);
  var emptyState = $("[data-empty]");
  var countEl = $("[data-result-count]");
  var searchInput = $("[data-search]");
  var brandSelect = $("[data-filter-brand]");
  var priceSelect = $("[data-filter-price]");
  var sortSelect = $("[data-sort]");

  var state = { q: "", category: "", brand: "", band: "", trim: "", sort: "relevant", view: "grid" };
  var originalOrder = cards.slice();

  /* ---------------------------------------------------------------- *
   * Membaca dan menulis keadaan ke URL supaya tautan bisa dibagikan
   * ---------------------------------------------------------------- */
  function readUrl() {
    var params = new URLSearchParams(window.location.search);
    state.q = params.get("q") || "";
    state.category = params.get("category") || "";
    state.brand = params.get("brand") || "";
    state.band = params.get("price") || "";
    state.trim = params.get("trim") || "";
    state.sort = params.get("sort") || "relevant";
    state.view = params.get("view") === "list" ? "list" : "grid";
  }

  function writeUrl() {
    var params = new URLSearchParams();
    if (state.q) params.set("q", state.q);
    if (state.category) params.set("category", state.category);
    if (state.brand) params.set("brand", state.brand);
    if (state.band) params.set("price", state.band);
    if (state.trim) params.set("trim", state.trim);
    if (state.sort !== "relevant") params.set("sort", state.sort);
    if (state.view !== "grid") params.set("view", state.view);

    var query = params.toString();
    var url = window.location.pathname + (query ? "?" + query : "");
    window.history.replaceState(null, "", url);
  }

  /* ---------------------------------------------------------------- *
   * Penyaringan
   * ---------------------------------------------------------------- */
  function matches(card) {
    if (state.category && card.dataset.category !== state.category) return false;
    if (state.brand && card.dataset.brand !== state.brand) return false;
    if (state.band && card.dataset.band !== state.band) return false;
    if (state.trim && card.dataset.name.indexOf(" " + state.trim) === -1 && state.trim !== "Standard") return false;
    if (state.trim === "Standard" && /\s(S|SP)$/.test(card.dataset.name)) return false;

    if (state.q) {
      var needles = state.q.toLowerCase().split(/\s+/).filter(Boolean);
      var haystack = card.dataset.search;
      for (var i = 0; i < needles.length; i++) {
        if (haystack.indexOf(needles[i]) === -1) return false;
      }
    }
    return true;
  }

  function sortCards(visible) {
    var sorted = visible.slice();
    switch (state.sort) {
      case "price_asc":
        sorted.sort(function (a, b) { return Number(a.dataset.price) - Number(b.dataset.price); });
        break;
      case "price_desc":
        sorted.sort(function (a, b) { return Number(b.dataset.price) - Number(a.dataset.price); });
        break;
      case "name":
        sorted.sort(function (a, b) { return a.dataset.name.localeCompare(b.dataset.name); });
        break;
      case "rating":
        sorted.sort(function (a, b) { return Number(b.dataset.rating) - Number(a.dataset.rating); });
        break;
      default:
        sorted.sort(function (a, b) {
          return originalOrder.indexOf(a) - originalOrder.indexOf(b);
        });
    }
    return sorted;
  }

  function apply() {
    var visible = [];
    cards.forEach(function (card) {
      var ok = matches(card);
      card.hidden = !ok;
      if (ok) visible.push(card);
    });

    // Susun ulang sekali lewat DocumentFragment agar tidak memicu banyak reflow.
    var fragment = document.createDocumentFragment();
    sortCards(visible).forEach(function (card) { fragment.appendChild(card); });
    grid.appendChild(fragment);

    if (countEl) countEl.textContent = String(visible.length);
    if (emptyState) emptyState.dataset.show = visible.length === 0 ? "true" : "false";
    grid.dataset.view = state.view;
    writeUrl();
  }

  /* ---------------------------------------------------------------- *
   * Menyelaraskan kontrol dengan keadaan
   * ---------------------------------------------------------------- */
  function syncControls() {
    if (searchInput) searchInput.value = state.q;
    if (brandSelect) brandSelect.value = state.brand;
    if (priceSelect) priceSelect.value = state.band;
    if (sortSelect) sortSelect.value = state.sort;

    $$("[data-category]").forEach(function (chip) {
      chip.setAttribute("aria-pressed", String(chip.dataset.category === state.category));
    });
    $$("[data-trim]").forEach(function (chip) {
      chip.setAttribute("aria-pressed", String(chip.dataset.trim === state.trim));
    });
    $$("[data-view]").forEach(function (btn) {
      btn.setAttribute("aria-pressed", String(btn.dataset.view === state.view));
    });
  }

  /* ---------------------------------------------------------------- *
   * Peristiwa
   * ---------------------------------------------------------------- */
  var debounceTimer = null;
  function debounce(fn, wait) {
    return function () {
      if (debounceTimer) window.clearTimeout(debounceTimer);
      debounceTimer = window.setTimeout(fn, wait);
    };
  }

  if (searchInput) {
    searchInput.addEventListener("input", debounce(function () {
      state.q = searchInput.value.trim();
      apply();
    }, 140));
  }

  var clearBtn = $("[data-search-clear]");
  if (clearBtn && searchInput) {
    clearBtn.addEventListener("click", function () {
      searchInput.value = "";
      state.q = "";
      searchInput.focus();
      apply();
    });
  }

  if (brandSelect) {
    brandSelect.addEventListener("change", function () { state.brand = brandSelect.value; apply(); });
  }
  if (priceSelect) {
    priceSelect.addEventListener("change", function () { state.band = priceSelect.value; apply(); });
  }
  if (sortSelect) {
    sortSelect.addEventListener("change", function () { state.sort = sortSelect.value; apply(); });
  }

  $$("[data-category]").forEach(function (chip) {
    chip.addEventListener("click", function () {
      state.category = chip.dataset.category;
      syncControls();
      apply();
    });
  });

  $$("[data-trim]").forEach(function (chip) {
    chip.addEventListener("click", function () {
      state.trim = state.trim === chip.dataset.trim ? "" : chip.dataset.trim;
      syncControls();
      apply();
    });
  });

  $$("[data-view]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      state.view = btn.dataset.view;
      syncControls();
      apply();
    });
  });

  $$("[data-reset]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      state = { q: "", category: "", brand: "", band: "", trim: "", sort: "relevant", view: state.view };
      syncControls();
      apply();
      if (searchInput) searchInput.focus();
    });
  });

  /* ---------------------------------------------------------------- *
   * Dialog detail produk
   * ---------------------------------------------------------------- */
  var dialog = $("#product-dialog");
  if (dialog && typeof dialog.showModal === "function") {
    var body = $("[data-dialog-body]", dialog);
    var lastTrigger = null;

    grid.addEventListener("click", function (event) {
      var button = event.target.closest("[data-detail]");
      if (!button) return;

      var card = button.closest("[data-item]");
      var template = $("[data-detail-content]", card);
      if (!template) return;

      lastTrigger = button;
      body.replaceChildren(template.content.cloneNode(true));
      dialog.showModal();
      body.scrollTop = 0;
    });

    dialog.addEventListener("close", function () {
      body.replaceChildren();
      if (lastTrigger) lastTrigger.focus();
    });

    window.HTZL.initDialogDismiss(dialog);
  }

  readUrl();
  syncControls();
  apply();
})();
