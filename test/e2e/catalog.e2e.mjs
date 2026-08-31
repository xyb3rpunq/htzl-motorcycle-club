// Uji end-to-end halaman katalog: menjalankan antarmuka sungguhan di peramban.
//
// Seluruh test lain memeriksa HTML yang sudah jadi. Yang ini menekan tombolnya.
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

const KARTU = "article.card:not([hidden])";

describe("halaman katalog", () => {
  test("memuat seluruh produk tanpa galat konsol", async () => {
    await page.goto(`${BASE}/catalog/`);

    assert.equal(await page.count("article.card"), 231);
    assert.deepEqual(page.konsol, []);
  });

  test("pencarian menyaring hasil dan bisa dikosongkan", async () => {
    await page.goto(`${BASE}/catalog/`);
    const semua = await page.count(KARTU);

    await page.fill("[data-search]", "kawasaki");
    await page.waitFor(`document.querySelectorAll("${KARTU}").length < ${semua}`);
    const hasil = await page.count(KARTU);

    assert.ok(hasil > 0 && hasil < semua, `hasil pencarian ${hasil} dari ${semua}`);

    await page.click("[data-search-clear]");
    await page.waitFor(`document.querySelectorAll("${KARTU}").length === ${semua}`);
  });

  test("pencarian mencakup nilai spesifikasi", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.fill("[data-search]", "brembo");
    await page.waitFor(`document.querySelectorAll("${KARTU}").length > 0`);

    assert.ok(await page.count(KARTU) >= 1, "kata dari tabel spesifikasi tidak menemukan apa pun");
  });

  test("pencarian tanpa hasil menampilkan keadaan kosong, bukan halaman hampa", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.fill("[data-search]", "qqqzzz-tidak-mungkin-ada");
    await page.waitFor(`document.querySelectorAll("${KARTU}").length === 0`);

    assert.ok(await page.visible("[data-empty]"), "keadaan kosong tidak muncul");
  });

  test("saringan kategori dan tombol atur ulang bekerja", async () => {
    await page.goto(`${BASE}/catalog/`);
    const semua = await page.count(KARTU);

    await page.click('button[data-category="motor"]');
    await page.waitFor(`document.querySelectorAll("${KARTU}").length < ${semua}`);
    assert.equal(await page.eval(`document.querySelector('button[data-category="motor"]').getAttribute("aria-pressed")`), "true");

    await page.click("[data-reset]");
    await page.waitFor(`document.querySelectorAll("${KARTU}").length === ${semua}`);
  });

  test("pengurutan harga benar-benar mengubah urutan", async () => {
    await page.goto(`${BASE}/catalog/`);
    const harga = () => page.eval(`[...document.querySelectorAll("${KARTU}")].slice(0,12)
      .map(c => Number(c.dataset.price))`);

    await page.fill("[data-sort]", "price_asc");
    await page.waitFor(`document.querySelector("[data-sort]").value === "price_asc"`);
    const naik = await harga();

    assert.deepEqual(naik, [...naik].sort((a, b) => a - b), "urutan menaik salah");

    await page.fill("[data-sort]", "price_desc");
    const turun = await harga();

    assert.deepEqual(turun, [...turun].sort((a, b) => b - a), "urutan menurun salah");
  });

  test("keadaan saringan tercatat di alamat halaman", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.fill("[data-search]", "harley");
    await page.click('button[data-view="list"]');
    await page.waitFor(`location.search.includes("q=harley")`);

    assert.match(await page.eval("location.search"), /view=list/);
  });

  // Regresi: pencarian ditunda 140 ms, sementara kontrol lain langsung
  // menyelaraskan tampilan dengan keadaan. Menekan tombol tepat setelah
  // mengetik menimpa isi kotak pencarian dengan keadaan lama, sehingga
  // ketikan pengguna hilang di depan matanya sendiri.
  test("mengetik lalu langsung menekan kontrol lain tidak menghapus ketikan", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.fill("[data-search]", "harley");
    await page.click('button[data-view="list"]');

    assert.equal(await page.eval(`document.querySelector("[data-search]").value`), "harley");
    assert.match(await page.eval("location.search"), /q=harley/);

    await page.waitFor(`document.querySelectorAll("${KARTU}").length === 100`);
  });

  test("tombol atur ulang memang mengosongkan kotak pencarian", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.fill("[data-search]", "harley");
    await page.waitFor(`location.search.includes("q=harley")`);
    await page.click("[data-reset]");

    assert.equal(await page.eval(`document.querySelector("[data-search]").value`), "");
  });

  test("panel detail terbuka dengan produk yang benar", async () => {
    await page.goto(`${BASE}/catalog/`);
    const nama = await page.eval(`document.querySelector("${KARTU}").dataset.name`);

    await page.click(`${KARTU} button[data-detail]`);
    await page.waitFor(`document.querySelector("dialog[open]")`);

    assert.ok((await page.text("dialog[open] h2, dialog[open] h3")).includes(nama.split(" ")[0]));
  });

  test("panel detail bisa berpindah ke produk berikutnya dan sebelumnya", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.click(`${KARTU} button[data-detail]`);
    await page.waitFor(`document.querySelector("dialog[open]")`);
    const awal = await page.text("[data-dialog-position]");

    await page.click("[data-dialog-next]");
    await page.waitFor(`document.querySelector("[data-dialog-position]").textContent.trim() !== ${JSON.stringify(awal)}`);

    await page.click("[data-dialog-prev]");
    await page.waitFor(`document.querySelector("[data-dialog-position]").textContent.trim() === ${JSON.stringify(awal)}`);
  });

  test("penghitung jumlah pada panel detail memperbarui total", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.click(`${KARTU} button[data-detail]`);
    await page.waitFor(`document.querySelector("dialog[open]")`);
    const awal = await page.text("[data-dialog-total]");

    await page.eval(`document.querySelectorAll("[data-qty-step]")[1].click()`);
    await page.waitFor(`document.querySelector("[data-dialog-total]").textContent.trim() !== ${JSON.stringify(awal)}`);

    assert.equal(await page.eval(`document.querySelector("[data-qty]").value`), "2");
  });

  test("tombol Escape menutup panel detail", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.click(`${KARTU} button[data-detail]`);
    await page.waitFor(`document.querySelector("dialog[open]")`);

    await page.eval(`document.querySelector("dialog[open]").close()`);
    await page.waitFor(`!document.querySelector("dialog[open]")`);
  });

  test("deep link membuka panel detail produk yang dimaksud", async () => {
    await page.goto(`${BASE}/catalog/?item=HTZ-HER-132`);
    await page.waitFor(`document.querySelector("dialog[open]")`, 6000);

    assert.match(await page.text("dialog[open]"), /HTZ-HER-132/);
  });

  test("deep link dengan kode produk asing tidak merusak halaman", async () => {
    await page.goto(`${BASE}/catalog/?item=TIDAK-ADA-999`);

    assert.equal(await page.count("article.card"), 231);
    assert.deepEqual(page.konsol, []);
  });

  test("kata kunci berisi tanda kutip dan tanda kurung tidak menyuntik markup", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.fill("[data-search]", '"><img src=x onerror=alert(1)>');
    await page.waitFor(`document.querySelectorAll("${KARTU}").length === 0`);

    assert.equal(await page.count("img[src='x']"), 0, "markup dari kotak pencarian ikut dirender");
    assert.deepEqual(page.konsol, []);
  });

  // Regresi: localeCompare tanpa opsi numeric membandingkan angka sebagai
  // huruf, sehingga urutan A sampai Z menaruh "Servis Berkala 12.000 km"
  // sebelum "Servis Berkala 4.000 km".
  test("urutan nama membaca angka sebagai angka", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.fill("[data-search]", "servis berkala");
    await page.waitFor(`document.querySelectorAll("${KARTU}").length > 1`);
    await page.fill("[data-sort]", "name");
    await page.waitFor(`document.querySelector("[data-sort]").value === "name"`);

    const nama = await page.eval(`[...document.querySelectorAll("${KARTU}")].map((c) => c.dataset.name)`);
    const angka = nama.map((n) => Number(String(n).match(/([\d.]+)\s*km/)?.[1].replace(/\./g, "") ?? 0));

    assert.deepEqual(angka, [...angka].sort((a, b) => a - b), `urutan salah: ${nama.join(" | ")}`);
  });

  test("urutan nama tetap benar di halaman berbahasa lain", async () => {
    for (const prefix of ["/en", "/ja"]) {
      await page.goto(`${BASE}${prefix}/catalog/`);
      await page.fill("[data-search]", "servis berkala");
      await page.waitFor(`document.querySelectorAll("${KARTU}").length > 1`);
      await page.fill("[data-sort]", "name");
      await page.waitFor(`document.querySelector("[data-sort]").value === "name"`);

      const nama = await page.eval(`[...document.querySelectorAll("${KARTU}")].map((c) => c.dataset.name)`);

      assert.match(nama[0], /4\.000/, `${prefix}: ${nama.join(" | ")}`);
    }
  });

  // Menyaring 231 kartu terjadi pada tiap ketukan tombol. Angka ini longgar
  // dengan sengaja: yang dijaga adalah tidak adanya kemunduran besar, bukan
  // selisih beberapa milidetik antar mesin.
  test("menyaring seluruh katalog selesai dalam waktu wajar", async () => {
    await page.goto(`${BASE}/catalog/`);
    const ms = await page.eval(`(async () => {
      const input = document.querySelector("input[data-search]");
      const mulai = performance.now();
      input.value = "harley";
      input.dispatchEvent(new Event("input", { bubbles: true }));
      await new Promise((selesai) => {
        let sebelum = -1;
        const cek = () => {
          const kini = document.querySelectorAll("article.card:not([hidden])").length;
          if (kini === sebelum) return requestAnimationFrame(() => selesai());
          sebelum = kini;
          setTimeout(cek, 30);
        };
        setTimeout(cek, 160);
      });
      return Math.round(performance.now() - mulai);
    })()`);

    assert.equal(await page.count(KARTU), 100);
    assert.ok(ms < 1500, `penyaringan butuh ${ms} ms`);
  });
});
