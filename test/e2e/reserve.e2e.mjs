// Uji end-to-end formulir reservasi.
//
// Formulir ini tidak mengirim ke server mana pun: ia menyusun pesan WhatsApp.
// Karena itu satu-satunya cara membuktikan validasinya benar adalah dengan
// benar-benar mengisinya di peramban.
import { test, before, after, describe } from "node:test";
import assert from "node:assert/strict";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { serve, launch } from "./driver.mjs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
let situs, page, BASE;

before(async () => {
  situs = await serve(join(ROOT, "_preview"));
  page = await launch();
  BASE = situs.base;
});

after(() => { page?.close(); situs?.close(); });

const isiValid = async () => {
  await page.eval(`(()=>{const s=document.querySelector("#f-brand");
    s.selectedIndex=1; s.dispatchEvent(new Event("change",{bubbles:true}));})()`);
  await page.waitFor(`document.querySelector("#f-model").options.length > 1`);
  await page.eval(`(()=>{const s=document.querySelector("#f-model");
    s.selectedIndex=1; s.dispatchEvent(new Event("change",{bubbles:true}));})()`);
  // Warna berupa grup radio, dan pilihannya mengikuti model yang dipilih.
  await page.waitFor(`document.querySelector('input[name="color"]')`);
  await page.eval(`(()=>{const r=document.querySelector('input[name="color"]');
    r.checked = true; r.dispatchEvent(new Event("change",{bubbles:true}));})()`);
  await page.fill("#f-name", "Daniel Hutajulu");
  await page.fill("#f-phone", "081386159080");
  await page.fill("#f-address", "Jl. Gatot Subroto Kav. 21, Jakarta Selatan");
  await page.fill("#f-qty", "2");
};

const galat = (field) => page.text(`#e-${field}`);

describe("formulir reservasi", () => {
  test("halaman termuat tanpa galat konsol", async () => {
    await page.goto(`${BASE}/reserve/`);

    assert.deepEqual(page.konsol, []);
    assert.ok(await page.visible("form[data-reserve-form]"));
  });

  test("mengirim formulir kosong memunculkan galat, bukan memuat ulang halaman", async () => {
    await page.goto(`${BASE}/reserve/`);
    const alamat = await page.eval("location.href");

    await page.click('button[type="submit"]');
    await page.waitFor(`document.querySelector('[data-field="name"][data-invalid="true"]')`);

    assert.equal(await page.eval("location.href"), alamat, "halaman termuat ulang dan isian hilang");
    assert.ok((await galat("name")).length > 0);
  });

  test("nama satu kata ditolak", async () => {
    await page.goto(`${BASE}/reserve/`);
    await isiValid();
    await page.fill("#f-name", "Daniel");
    await page.click('button[type="submit"]');
    await page.waitFor(`document.querySelector('[data-field="name"][data-invalid="true"]')`);

    assert.ok((await galat("name")).length > 0);
  });

  test("nomor telepon berisi huruf ditolak", async () => {
    await page.goto(`${BASE}/reserve/`);
    await isiValid();
    await page.fill("#f-phone", "08a1b2c3");
    await page.click('button[type="submit"]');
    await page.waitFor(`document.querySelector('[data-field="phone"][data-invalid="true"]')`);

    assert.ok((await galat("phone")).length > 0);
  });

  test("nomor telepon terlalu pendek ditolak", async () => {
    await page.goto(`${BASE}/reserve/`);
    await isiValid();
    await page.fill("#f-phone", "0812");
    await page.click('button[type="submit"]');
    await page.waitFor(`document.querySelector('[data-field="phone"][data-invalid="true"]')`);

    assert.ok((await galat("phone")).length > 0);
  });

  test("jumlah di luar batas ditolak", async () => {
    await page.goto(`${BASE}/reserve/`);
    await isiValid();
    await page.fill("#f-qty", "99");
    await page.click('button[type="submit"]');
    await page.waitFor(`document.querySelector('[data-field="qty"][data-invalid="true"]')`);

    assert.ok((await galat("qty")).length > 0);
  });

  test("memilih model memperbarui ringkasan pesanan", async () => {
    await page.goto(`${BASE}/reserve/`);
    const sebelum = await page.text("[data-summary-total]");

    await isiValid();
    await page.waitFor(`document.querySelector("[data-summary-total]").textContent.trim() !== ${JSON.stringify(sebelum)}`);

    assert.match(await page.text("[data-summary-model]"), /\S/);
    assert.match(await page.text("[data-summary-total]"), /Rp/);
    assert.equal(await page.text("[data-summary-qty]"), "2");
  });

  test("isian yang benar menghasilkan tautan WhatsApp berisi data pesanan", async () => {
    await page.goto(`${BASE}/reserve/`);
    await isiValid();
    await page.click('button[type="submit"]');
    await page.waitFor(`document.querySelector("[data-success-panel]:not([hidden])")`);

    const href = await page.eval(`document.querySelector("[data-wa-link]").href`);

    assert.match(href, /^https:\/\/wa\.me\/6281386159080\?text=/);
    const pesan = decodeURIComponent(href.split("text=")[1]);

    assert.match(pesan, /Daniel Hutajulu/);
    assert.match(pesan, /081386159080/);
    assert.match(pesan, /Jakarta Selatan/);
    assert.deepEqual(page.konsol, []);
  });

  test("galat hilang setelah kolomnya diperbaiki", async () => {
    await page.goto(`${BASE}/reserve/`);
    await page.click('button[type="submit"]');
    await page.waitFor(`document.querySelector('[data-field="name"][data-invalid="true"]')`);

    await isiValid();
    await page.click('button[type="submit"]');
    await page.waitFor(`!document.querySelector('[data-field="name"][data-invalid="true"]')`);

    assert.equal(await galat("name"), "");
  });
});
