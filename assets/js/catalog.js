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

  var state = { q: "", category: "", sub: "", brand: "", band: "", trim: "", sort: "relevant", view: "grid" };
  var originalOrder = cards.slice();

  /* ---------------------------------------------------------------- *
   * Membaca dan menulis keadaan ke URL supaya tautan bisa dibagikan
   * ---------------------------------------------------------------- */
  function readUrl() {
    var params = new URLSearchParams(window.location.search);
    state.q = params.get("q") || "";
    state.category = params.get("category") || "";
    state.sub = params.get("sub") || "";
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
    if (state.sub) params.set("sub", state.sub);
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
    if (state.sub && card.dataset.sub !== state.sub) return false;
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
      // Menyentuh `hidden` selalu membatalkan gaya elemen, jadi hanya diubah
      // kalau nilainya memang berbeda.
      if (card.hidden === ok) card.hidden = !ok;
      if (ok) visible.push(card);
    });

    var sorted = sortCards(visible);

    // Saat halaman baru dimuat tanpa penyaringan, urutan di DOM sudah benar
    // karena server merendernya begitu. Memindahkan 231 kartu ke tempat yang
    // sama persis hanya membuang waktu utas utama.
    if (orderChanged(sorted)) {
      var fragment = document.createDocumentFragment();
      sorted.forEach(function (card) { fragment.appendChild(card); });
      grid.appendChild(fragment);
    }

    if (countEl) countEl.textContent = String(visible.length);
    if (emptyState) emptyState.dataset.show = visible.length === 0 ? "true" : "false";
    grid.dataset.view = state.view;
    writeUrl();
  }

  // Bandingkan urutan yang diinginkan dengan anak-anak grid yang terlihat.
  function orderChanged(sorted) {
    var child = grid.firstElementChild;
    var i = 0;

    while (child) {
      if (!child.hidden) {
        if (child !== sorted[i]) return true;
        i++;
      }
      child = child.nextElementSibling;
    }
    return i !== sorted.length;
  }

  /* ---------------------------------------------------------------- *
   * Menyelaraskan kontrol dengan keadaan
   *
   * Selektor sengaja dibatasi ke <button>. Kartu produk juga membawa
   * data-category dan grid membawa data-view, sehingga selektor atribut
   * telanjang akan menempelkan aria-pressed ke ratusan elemen yang tidak
   * boleh memilikinya.
   * ---------------------------------------------------------------- */
  function syncControls() {
    if (searchInput) searchInput.value = state.q;
    if (brandSelect) brandSelect.value = state.brand;
    if (priceSelect) priceSelect.value = state.band;
    if (sortSelect) sortSelect.value = state.sort;

    $$("button[data-category]").forEach(function (chip) {
      chip.setAttribute("aria-pressed", String(chip.dataset.category === state.category));
    });
    $$("button[data-subcategory]").forEach(function (chip) {
      chip.setAttribute("aria-pressed", String(chip.dataset.subcategory === state.sub));
    });
    $$("button[data-trim]").forEach(function (chip) {
      chip.setAttribute("aria-pressed", String(chip.dataset.trim === state.trim));
    });
    $$("button[data-view]").forEach(function (btn) {
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

  $$("button[data-category]").forEach(function (chip) {
    chip.addEventListener("click", function () {
      state.category = chip.dataset.category;
      syncControls();
      apply();
    });
  });

  $$("button[data-subcategory]").forEach(function (chip) {
    chip.addEventListener("click", function () {
      state.sub = state.sub === chip.dataset.subcategory ? "" : chip.dataset.subcategory;
      syncControls();
      apply();
    });
  });

  $$("button[data-trim]").forEach(function (chip) {
    chip.addEventListener("click", function () {
      state.trim = state.trim === chip.dataset.trim ? "" : chip.dataset.trim;
      syncControls();
      apply();
    });
  });

  $$("button[data-view]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      state.view = btn.dataset.view;
      syncControls();
      apply();
    });
  });

  $$("[data-reset]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      state = { q: "", category: "", sub: "", brand: "", band: "", trim: "", sort: "relevant", view: state.view };
      syncControls();
      apply();
      if (searchInput) searchInput.focus();
    });
  });

  /* ---------------------------------------------------------------- *
   * Dialog detail produk
   *
   * Bar bawah (jumlah, total, tombol pesan) dan navigasi antarproduk hidup
   * di luar isi yang disalin, sehingga tombol pesan selalu terjangkau dan
   * pengunjung bisa berpindah produk tanpa menutup dialog.
   * ---------------------------------------------------------------- */
  var dialog = $("#product-dialog");

  if (dialog && typeof dialog.showModal === "function") {
    var body = $("[data-dialog-body]", dialog);
    var qtyInput = $("[data-qty]", dialog);
    var totalEl = $("[data-dialog-total]", dialog);
    var orderLink = $("[data-dialog-order]", dialog);
    var positionEl = $("[data-dialog-position]", dialog);
    var prevBtn = $("[data-dialog-prev]", dialog);
    var nextBtn = $("[data-dialog-next]", dialog);
    var copyBtn = $("[data-dialog-copy]", dialog);
    var dd = dialog.dataset;

    var lastTrigger = null;
    var currentCard = null;

    function rupiah(value) {
      var n = Math.round(Number(value) || 0);
      return "Rp " + String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    }

    // Hanya kartu yang lolos saringan yang bisa dijelajahi dengan panah.
    function visibleCards() {
      return cards.filter(function (card) { return !card.hidden; });
    }

    function itemUrl(card) {
      return window.location.origin + window.location.pathname + "?item=" + encodeURIComponent(card.dataset.sku);
    }

    function refreshTotals() {
      if (!currentCard) return;
      var qty = Math.min(99, Math.max(1, parseInt(qtyInput.value, 10) || 1));
      qtyInput.value = qty;

      var price = Number(currentCard.dataset.price) || 0;
      totalEl.textContent = rupiah(price * qty);

      var lines = [
        dd.waIntro,
        "",
        currentCard.dataset.name + " (" + currentCard.dataset.sku + ")",
        dd.labelQty + ": " + qty,
        dd.labelTotal + ": " + rupiah(price * qty),
        "",
        itemUrl(currentCard)
      ];
      orderLink.href = "https://wa.me/" + String(dd.wa).replace(/\D/g, "") +
                       "?text=" + encodeURIComponent(lines.join("\n"));
    }

    // Data detail dikirim sekali sebagai JSON, bukan sebagai <template> di
    // tiap kartu. Pada halaman katalog cara lama menyumbang 55 persen berat
    // halaman, padahal isinya tidak pernah tampil tanpa JavaScript.
    var details = {};
    var payload = document.getElementById("catalog-details");
    if (payload) {
      try {
        details = JSON.parse(payload.textContent);
      } catch (error) {
        details = {};
      }
    }

    function el(tag, className, text) {
      var node = document.createElement(tag);
      if (className) node.className = className;
      if (text != null) node.textContent = text;
      return node;
    }

    function icon(id) {
      var ns = "http://www.w3.org/2000/svg";
      var svg = document.createElementNS(ns, "svg");
      var use = document.createElementNS(ns, "use");
      use.setAttribute("href", "#" + id);
      svg.setAttribute("aria-hidden", "true");
      svg.appendChild(use);
      return svg;
    }

    function link(href, text) {
      var a = el("a", null, text);
      a.href = href;
      a.target = "_blank";
      a.rel = "noopener noreferrer";
      return a;
    }

    // Isi dialog disusun dengan API DOM, bukan innerHTML.
    function buildDetail(data) {
      var frag = document.createDocumentFragment();

      var media = el("div", "dialog__media");
      var img = el("img");
      img.src = data.i;
      img.alt = data.n;
      img.width = 630;
      img.height = 390;
      media.appendChild(img);
      frag.appendChild(media);

      var content = el("div", "dialog__content");

      var head = el("div");
      head.appendChild(el("p", "card__kicker", data.k));
      var title = el("h2", null, data.n);
      title.id = "detail-title";
      head.appendChild(title);
      var blurb = el("p", null, data.b);
      blurb.style.color = "var(--ink-2)";
      blurb.style.marginTop = ".4rem";
      head.appendChild(blurb);
      content.appendChild(head);

      var prices = el("div", "price-block");
      prices.appendChild(el("span", "now", data.p));
      if (data.o) prices.appendChild(el("span", "was", data.o));
      var rating = el("span", "rating");
      rating.appendChild(icon("i-star"));
      rating.appendChild(document.createTextNode(data.r));
      prices.appendChild(rating);
      prices.appendChild(el("span", "pill pill--" + data.st, data.s));
      content.appendChild(prices);

      var table = el("table", "spec-table");
      table.appendChild(el("caption", "visually-hidden", dd.labelSpecs + " " + data.n));
      var tbody = el("tbody");
      data.sp.forEach(function (pair) {
        var row = el("tr");
        var key = el("th", null, pair[0]);
        key.scope = "row";
        row.appendChild(key);
        row.appendChild(el("td", null, pair[1]));
        tbody.appendChild(row);
      });
      table.appendChild(tbody);
      content.appendChild(table);

      // Lisensi Creative Commons mensyaratkan atribusi ditampilkan.
      if (data.c) {
        var credit = el("p", "credit");
        credit.appendChild(document.createTextNode(dd.labelPhoto + ": "));
        credit.appendChild(link(data.c.u, data.c.t));
        credit.appendChild(document.createTextNode(" \u00b7 " + data.c.a + " \u00b7 "));
        credit.appendChild(link(data.c.lu || data.c.u, data.c.l));
        credit.appendChild(document.createTextNode(" \u00b7 Wikimedia Commons"));
        content.appendChild(credit);
      }

      frag.appendChild(content);
      return frag;
    }

    function show(card) {
      var data = details[card.dataset.sku];
      if (!data) return;

      currentCard = card;
      body.replaceChildren(buildDetail(data));
      body.scrollTop = 0;
      qtyInput.value = 1;

      var list = visibleCards();
      var index = list.indexOf(card);
      positionEl.textContent = (index + 1) + " " + dd.labelOf + " " + list.length;
      prevBtn.disabled = index <= 0;
      nextBtn.disabled = index < 0 || index >= list.length - 1;

      refreshTotals();
    }

    function step(delta) {
      var list = visibleCards();
      var index = list.indexOf(currentCard);
      var target = list[index + delta];
      if (target) show(target);
    }

    grid.addEventListener("click", function (event) {
      var button = event.target.closest("[data-detail]");
      if (!button) return;
      lastTrigger = button;
      show(button.closest("[data-item]"));
      dialog.showModal();
    });

    prevBtn.addEventListener("click", function () { step(-1); });
    nextBtn.addEventListener("click", function () { step(1); });

    dialog.addEventListener("keydown", function (event) {
      if (event.target === qtyInput) return;
      if (event.key === "ArrowLeft") { event.preventDefault(); step(-1); }
      if (event.key === "ArrowRight") { event.preventDefault(); step(1); }
    });

    $$("[data-qty-step]", dialog).forEach(function (button) {
      button.addEventListener("click", function () {
        qtyInput.value = (parseInt(qtyInput.value, 10) || 1) + Number(button.dataset.qtyStep);
        refreshTotals();
      });
    });

    qtyInput.addEventListener("input", refreshTotals);

    copyBtn.addEventListener("click", function () {
      if (!currentCard) return;
      var url = itemUrl(currentCard);
      var done = function () { window.HTZL.toast(dd.labelCopied); };

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(done, function () { window.prompt("", url); });
      } else {
        window.prompt("", url);
      }
    });

    dialog.addEventListener("close", function () {
      body.replaceChildren();
      currentCard = null;
      if (lastTrigger) lastTrigger.focus();
    });

    window.HTZL.initDialogDismiss(dialog);

    // Tautan dalam seperti ?item=HTZ-MOT-001 langsung membuka produknya.
    // Dipanggil langsung, bukan lewat requestAnimationFrame: peramban tidak
    // menjalankan rAF pada dokumen yang tidak terlihat, sehingga tautan yang
    // dibuka di tab latar tidak akan pernah menampilkan dialognya.
    var deepLink = new URLSearchParams(window.location.search).get("item");
    if (deepLink) {
      var target = cards.find(function (card) { return card.dataset.sku === deepLink; });
      if (target) {
        show(target);
        dialog.showModal();
      }
    }
  }

  readUrl();
  syncControls();
  apply();
})();
