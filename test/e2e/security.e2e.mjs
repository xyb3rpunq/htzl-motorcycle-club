// Membuktikan Content-Security-Policy benar-benar ditegakkan peramban.
//
// Memeriksa isi metanya saja tidak cukup: kebijakan yang salah tulis diabaikan
// tanpa suara, dan halaman tetap terlihat baik-baik saja. Satu-satunya bukti
// adalah mencoba melakukan hal yang seharusnya dilarang.
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

const HALAMAN = ["/", "/catalog/", "/heritage/", "/gallery/", "/reserve/", "/kawasaki/", "/404.html", "/ja/catalog/"];

describe("Content-Security-Policy", () => {
  test("skrip inline yang disuntik tidak berjalan", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.eval(`(() => {
      window.__disuntik = false;
      const sc = document.createElement("script");
      sc.textContent = "window.__disuntik = true";
      document.head.appendChild(sc);
    })()`);

    assert.equal(await page.eval("window.__disuntik"), false,
                 "skrip inline asing berhasil berjalan, kebijakan tidak ditegakkan");
  });

  test("sumber daya dari host lain ditolak", async () => {
    await page.goto(`${BASE}/catalog/`);
    const hasil = await page.eval(`new Promise((selesai) => {
      const gambar = new Image();
      gambar.onerror = () => selesai("ditolak");
      gambar.onload = () => selesai("dimuat");
      gambar.src = "https://example.com/tidak-ada.png";
      setTimeout(() => selesai("tidak terjawab"), 4000);
    })`);

    assert.equal(hasil, "ditolak");
  });

  test("skrip inline situs sendiri tetap berjalan", async () => {
    await page.goto(`${BASE}/catalog/`);

    // Skrip pemulih tema berjalan sebelum halaman digambar; kalau kebijakan
    // memblokirnya, penanda no-js tidak pernah dilepas.
    assert.equal(await page.eval(`document.documentElement.classList.contains("no-js")`), false,
                 "skrip inline situs sendiri ikut terblokir");
    assert.match(await page.eval("document.documentElement.dataset.theme"), /light|dark/);
  });

  test("halaman 404 dengan dua skrip inline tetap berfungsi", async () => {
    await page.goto(`${BASE}/404.html`);

    assert.equal(await page.eval(`document.documentElement.classList.contains("no-js")`), false);
    assert.deepEqual(page.konsol, []);
  });

  test("tidak ada halaman yang memunculkan galat akibat kebijakan", async () => {
    const bermasalah = [];
    for (const path of HALAMAN) {
      await page.goto(BASE + path);
      await page.eval(`document.querySelector("[data-theme-toggle]")?.click()`).catch(() => {});
      if (page.konsol.length) bermasalah.push(`${path}: ${JSON.stringify(page.konsol).slice(0, 120)}`);
    }

    assert.deepEqual(bermasalah, []);
  });
});
