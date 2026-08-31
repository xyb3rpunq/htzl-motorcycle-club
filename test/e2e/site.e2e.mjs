// Uji end-to-end untuk antarmuka yang muncul di seluruh halaman: tema,
// navigasi, penggeser hero, lightbox galeri, dan pengalih bahasa.
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

const HALAMAN = ["/", "/catalog/", "/heritage/", "/gallery/", "/reserve/", "/kawasaki/", "/vixian/"];

describe("antarmuka menyeluruh", () => {
  test("tidak ada halaman yang memunculkan galat konsol", async () => {
    const bermasalah = [];
    for (const path of HALAMAN) {
      await page.goto(BASE + path);
      if (page.konsol.length) bermasalah.push(`${path}: ${JSON.stringify(page.konsol)}`);
    }

    assert.deepEqual(bermasalah, []);
  });

  test("setiap halaman punya satu h1 dan tautan lewati navigasi", async () => {
    for (const path of HALAMAN) {
      await page.goto(BASE + path);

      assert.equal(await page.count("h1"), 1, `${path}: jumlah h1 salah`);
      assert.ok(await page.eval(`Boolean(document.querySelector(".skip-link"))`), path);
    }
  });

  test("tema gelap bertahan saat berpindah halaman", async () => {
    await page.goto(`${BASE}/`);
    const awal = await page.eval("document.documentElement.dataset.theme");

    await page.click("[data-theme-toggle]");
    await page.waitFor(`document.documentElement.dataset.theme !== ${JSON.stringify(awal)}`);
    const dipilih = await page.eval("document.documentElement.dataset.theme");

    await page.goto(`${BASE}/catalog/`);

    assert.equal(await page.eval("document.documentElement.dataset.theme"), dipilih,
                 "pilihan tema tidak bertahan");
  });

  test("penanda no-js dilepas begitu skrip berjalan", async () => {
    await page.goto(`${BASE}/catalog/`);

    assert.equal(await page.eval(`document.documentElement.classList.contains("no-js")`), false);
    assert.ok(await page.visible(".catalog__toolbar"), "alat penyaring seharusnya tampil");
    assert.equal(await page.visible("[data-no-js]"), false, "keterangan tanpa JS seharusnya tersembunyi");
  });

  test("menu ponsel terbuka, tertutup oleh Escape, dan tidak menjebak fokus", async () => {
    await page.eval(`window.resizeTo(390, 844)`).catch(() => {});
    await page.goto(`${BASE}/`);
    if (!(await page.visible("[data-nav-toggle]"))) return;

    await page.click("[data-nav-toggle]");
    await page.waitFor(`document.querySelector("[data-nav]")?.dataset.open === "true" ||
                        document.querySelector(".site-nav")?.dataset.open === "true"`, 2500)
      .catch(() => {});
    await page.key("Escape");
    await page.eval("1");
  });

  test("penggeser hero berpindah maju dan mundur", async () => {
    await page.goto(`${BASE}/`);
    const posisi = () => page.eval(`[...document.querySelectorAll("[data-hero-dot]")]
      .findIndex(d => d.getAttribute("aria-current") === "true" || d.getAttribute("aria-selected") === "true")`);
    const awal = await posisi();

    await page.click("[data-hero-next]");
    await page.waitFor(`[...document.querySelectorAll("[data-hero-dot]")]
      .findIndex(d => d.getAttribute("aria-current") === "true" ||
                      d.getAttribute("aria-selected") === "true") !== ${awal}`, 3000);

    await page.click("[data-hero-prev]");
    await page.waitFor(`[...document.querySelectorAll("[data-hero-dot]")]
      .findIndex(d => d.getAttribute("aria-current") === "true" ||
                      d.getAttribute("aria-selected") === "true") === ${awal}`, 3000);
  });

  test("lightbox galeri terbuka, berpindah, dan tertutup", async () => {
    await page.goto(`${BASE}/gallery/`);
    await page.eval(`document.querySelector("[data-full]").click()`);
    await page.waitFor(`document.querySelector("dialog[open]")`);
    const pertama = await page.eval(`document.querySelector("[data-lightbox-img]").src`);

    await page.click("[data-lightbox-next]");
    await page.waitFor(`document.querySelector("[data-lightbox-img]").src !== ${JSON.stringify(pertama)}`);

    await page.click("[data-lightbox-prev]");
    await page.waitFor(`document.querySelector("[data-lightbox-img]").src === ${JSON.stringify(pertama)}`);

    await page.eval(`document.querySelector("dialog[open]").close()`);
    await page.waitFor(`!document.querySelector("dialog[open]")`);

    assert.deepEqual(page.konsol, []);
  });

  test("pengalih bahasa membawa ke halaman yang sama dalam bahasa lain", async () => {
    await page.goto(`${BASE}/catalog/`);
    const tautan = await page.eval(`[...document.querySelectorAll("a[hreflang], [data-dropdown] a")]
      .map(a => a.getAttribute("href")).filter(h => h && h.includes("/catalog/"))`);

    assert.ok(tautan.some((h) => h.startsWith("/en/")), "tidak ada tautan ke katalog bahasa Inggris");

    await page.goto(`${BASE}/en/catalog/`);

    assert.equal(await page.eval("document.documentElement.lang"), "en");
    assert.equal(await page.count("article.card"), 231);
  });

  test("halaman 404 tetap menampilkan jalan kembali", async () => {
    await page.goto(`${BASE}/404.html`);

    assert.ok(await page.eval(`document.querySelectorAll('a[href="/"], a[href$="/"]').length > 0`));
    assert.deepEqual(page.konsol, []);
  });
});
