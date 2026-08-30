/*!
 * HTZL Motorcycle Club - validasi dan ringkasan formulir reservasi.
 *
 * Fungsi validasi murni diekspor lewat window.HTZLReserve agar bisa diuji
 * terpisah dari DOM (lihat test/reserve_validation_test.rb).
 */
(function () {
  "use strict";

  /* ---------------------------------------------------------------- *
   * Fungsi murni: tidak menyentuh DOM, mudah diuji
   * ---------------------------------------------------------------- */
  var Validators = {
    // Nama wajib terdiri dari minimal dua kata yang bukan spasi kosong.
    isFullName: function (value) {
      return String(value).trim().split(/\s+/).filter(Boolean).length >= 2;
    },

    // Nomor telepon hanya boleh angka.
    isDigitsOnly: function (value) {
      return /^[0-9]+$/.test(String(value).trim());
    },

    // Panjang nomor Indonesia yang masuk akal.
    hasPhoneLength: function (value) {
      var digits = String(value).replace(/\D/g, "");
      return digits.length >= 9 && digits.length <= 15;
    },

    isFilled: function (value) {
      return String(value).trim().length > 0;
    },

    isQuantity: function (value) {
      var n = Number(value);
      return Number.isInteger(n) && n >= 1 && n <= 10;
    },

    // 45000000 -> "Rp 45.000.000"
    rupiah: function (value) {
      var n = Math.round(Number(value) || 0);
      var sign = n < 0 ? "-" : "";
      var digits = String(Math.abs(n)).replace(/\B(?=(\d{3})+(?!\d))/g, ".");
      return sign + "Rp " + digits;
    },

    // Bangun deep link WhatsApp dari ringkasan pesanan.
    buildWhatsAppUrl: function (number, lines) {
      var text = lines.filter(Boolean).join("\n");
      return "https://wa.me/" + String(number).replace(/\D/g, "") + "?text=" + encodeURIComponent(text);
    }
  };

  window.HTZLReserve = Validators;

  /* ---------------------------------------------------------------- *
   * Pengikatan ke DOM
   * ---------------------------------------------------------------- */
  var form = document.querySelector("[data-reserve-form]");
  if (!form) return;

  var $ = window.HTZL.$;
  var $$ = window.HTZL.$$;

  var d = form.dataset;
  var modelSelect = $("[data-model-select]", form);
  var brandSelect = form.elements.brand;
  var qtyInput = form.elements.qty;
  var successPanel = $("[data-success-panel]");
  var waLink = $("[data-wa-link]");

  var summary = {
    model: $("[data-summary-model]"),
    price: $("[data-summary-price]"),
    qty: $("[data-summary-qty]"),
    color: $("[data-summary-color]"),
    total: $("[data-summary-total]")
  };

  function setError(fieldName, message) {
    var field = form.querySelector('[data-field="' + fieldName + '"]');
    if (!field) return;
    var slot = field.querySelector(".error");
    field.dataset.invalid = message ? "true" : "false";
    if (slot) slot.textContent = message || "";
  }

  function selectedColor() {
    var checked = form.querySelector('input[name="color"]:checked');
    return checked ? checked.value : "";
  }

  function selectedModelOption() {
    if (!modelSelect || !modelSelect.value) return null;
    return modelSelect.options[modelSelect.selectedIndex] || null;
  }

  /* Tampilkan hanya model dari merek yang dipilih. */
  function filterModels() {
    if (!modelSelect || !brandSelect) return;
    var brand = brandSelect.value;
    var stillValid = false;

    $$("option", modelSelect).forEach(function (option) {
      if (!option.value) return;
      var show = !brand || option.dataset.brand === brand;
      option.hidden = !show;
      if (show && option.value === modelSelect.value) stillValid = true;
    });

    if (!stillValid) modelSelect.value = "";
    updateSummary();
  }

  function updateSummary() {
    var option = selectedModelOption();
    var qty = Number(qtyInput.value) || 1;
    var color = selectedColor();

    if (option) {
      var price = Number(option.dataset.price) || 0;
      summary.model.textContent = option.value;
      summary.price.textContent = Validators.rupiah(price);
      summary.total.textContent = Validators.rupiah(price * qty);
    } else {
      summary.model.textContent = d.emptyLabel;
      summary.price.textContent = "-";
      summary.total.textContent = "-";
    }
    summary.qty.textContent = String(qty);
    summary.color.textContent = color || "-";
  }

  function validate() {
    var ok = true;
    var values = {
      name: form.elements.name.value,
      phone: form.elements.phone.value,
      address: form.elements.address.value,
      brand: brandSelect.value,
      model: modelSelect ? modelSelect.value : "",
      qty: qtyInput.value,
      color: selectedColor()
    };

    ["name", "phone", "address", "brand", "model"].forEach(function (key) {
      setError(key, "");
      if (!Validators.isFilled(values[key])) {
        setError(key, d.errRequired);
        ok = false;
      }
    });

    if (ok && !Validators.isFullName(values.name)) { setError("name", d.errName); ok = false; }

    if (Validators.isFilled(values.phone)) {
      if (!Validators.isDigitsOnly(values.phone)) { setError("phone", d.errDigits); ok = false; }
      else if (!Validators.hasPhoneLength(values.phone)) { setError("phone", d.errLength); ok = false; }
    }

    setError("qty", "");
    if (!Validators.isQuantity(values.qty)) { setError("qty", d.errQty); ok = false; }

    setError("color", "");
    if (!Validators.isFilled(values.color)) { setError("color", d.errColor); ok = false; }

    return ok ? values : null;
  }

  form.addEventListener("submit", function (event) {
    event.preventDefault();
    var values = validate();

    if (!values) {
      var firstInvalid = form.querySelector('[data-invalid="true"]');
      if (firstInvalid) {
        var control = firstInvalid.querySelector("input, select, textarea");
        if (control) control.focus();
        firstInvalid.scrollIntoView({ behavior: window.HTZL.reduceMotion ? "auto" : "smooth", block: "center" });
      }
      return;
    }

    var option = selectedModelOption();
    var price = option ? Number(option.dataset.price) || 0 : 0;
    var qty = Number(values.qty);

    var lines = [
      d.waIntro,
      "",
      d.labelModel + ": " + values.model + (option && option.dataset.sku ? " (" + option.dataset.sku + ")" : ""),
      d.labelQty + ": " + qty,
      d.labelColor + ": " + values.color,
      d.labelTotal + ": " + Validators.rupiah(price * qty),
      "",
      d.labelName + ": " + values.name,
      d.labelPhone + ": " + values.phone,
      d.labelAddress + ": " + values.address
    ];

    if (waLink) waLink.href = Validators.buildWhatsAppUrl(d.wa, lines);
    if (successPanel) {
      successPanel.hidden = false;
      successPanel.scrollIntoView({ behavior: window.HTZL.reduceMotion ? "auto" : "smooth", block: "center" });
    }
    window.HTZL.toast(d.success);
  });

  // Bersihkan pesan galat begitu pengguna memperbaiki isian.
  form.addEventListener("input", function (event) {
    var field = event.target.closest("[data-field]");
    if (field && field.dataset.invalid === "true") field.dataset.invalid = "false";
    updateSummary();
  });

  form.addEventListener("change", function (event) {
    if (event.target === brandSelect) filterModels();
    updateSummary();
  });

  filterModels();
  updateSummary();
})();
