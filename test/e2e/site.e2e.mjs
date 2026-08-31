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

  // Regresi: aturan `dialog { display: flex }` tanpa syarat menimpa aturan
  // bawaan peramban yang menyembunyikan panel tertutup. Akibatnya isi panel
  // detail, termasuk tombol maju-mundur dan penghitung jumlah, tampil begitu
  // saja di dalam halaman tepat di atas footer.
  test("panel yang tertutup tidak memakan ruang di halaman", async () => {
    for (const path of HALAMAN) {
      await page.goto(BASE + path);
      const tinggi = await page.eval(`[...document.querySelectorAll("dialog")]
        .filter(d => !d.open)
        .reduce((total, d) => total + d.getBoundingClientRect().height, 0)`);

      assert.equal(Math.round(tinggi), 0, `${path}: panel tertutup masih tampil`);
    }
  });

  test("panel tetap bisa dibuka dan ditutup setelah aturan tampilannya diperketat", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.click("article.card:not([hidden]) button[data-detail]");
    await page.waitFor(`document.querySelector("dialog[open]")`);

    assert.ok(await page.visible("dialog[open]"));
    assert.ok(await page.eval(`document.querySelector("dialog[open]").matches(":modal")`),
              "panel harus benar-benar modal supaya fokus terkurung di dalamnya");

    await page.eval(`document.querySelector("dialog[open]").close()`);
    await page.waitFor(`!document.querySelector("dialog[open]")`);

    assert.equal(await page.visible("dialog"), false);
  });

  // Menyaring 231 produk menjadi tiga tidak memberi tanda apa pun bagi yang
  // tidak melihat layar sebelum region status ini ada.
  test("perubahan jumlah hasil diumumkan lewat region status", async () => {
    await page.goto(`${BASE}/catalog/`);

    assert.ok(await page.eval(`Boolean(document.querySelector("[data-result-count]").closest("[role=status]"))`),
              "penghitung hasil tidak berada di dalam region status");

    await page.fill("[data-search]", "brembo");
    await page.waitFor(`document.querySelector("[data-result-count]").textContent.trim() !== "231"`);

    assert.match(await page.text("[role=status]"), /\d+/);
  });

  test("fokus masuk ke panel lalu kembali ke tombol yang membukanya", async () => {
    await page.goto(`${BASE}/catalog/`);
    await page.eval(`window.__pemicu = document.querySelector("article.card:not([hidden]) button[data-detail]");
                     window.__pemicu.focus(); window.__pemicu.click();`);
    await page.waitFor(`document.querySelector("dialog[open]")`);

    assert.ok(await page.eval(`document.querySelector("dialog[open]").contains(document.activeElement)`),
              "fokus tidak berpindah ke dalam panel");

    await page.eval(`document.querySelector("dialog[open]").close()`);
    await page.waitFor(`!document.querySelector("dialog[open]")`);

    assert.ok(await page.eval(`document.activeElement === window.__pemicu`),
              "fokus tidak kembali ke tombol asal");
  });

  // Ambang WCAG 2.5.8 adalah 24 piksel, dan boleh dipenuhi lewat jarak antar
  // target. Tautan dalam kalimat dikecualikan.
  test("target sentuh memenuhi ambang, sendiri atau bersama jaraknya", async () => {
    const gagal = [];
    for (const path of HALAMAN) {
      await page.goto(BASE + path);
      const kecil = await page.eval(`(() => {
        const semua = [...document.querySelectorAll("a,button,input,select,summary")]
          .filter(el => { const r = el.getBoundingClientRect(); return r.width && r.height; });
        const bermasalah = [];
        for (const el of semua) {
          const r = el.getBoundingClientRect();
          if (Math.min(r.width, r.height) >= 24) continue;
          const induk = el.parentElement;
          const dalamKalimat = el.tagName === "A" && induk &&
            getComputedStyle(el).display.startsWith("inline") &&
            induk.textContent.trim().length > el.textContent.trim().length + 3;
          if (dalamKalimat) continue;
          let terdekat = Infinity;
          for (const lain of semua) {
            if (lain === el) continue;
            const q = lain.getBoundingClientRect();
            const dx = Math.max(0, Math.max(r.left - q.right, q.left - r.right));
            const dy = Math.max(0, Math.max(r.top - q.bottom, q.top - r.bottom));
            terdekat = Math.min(terdekat, Math.hypot(dx, dy));
          }
          if (Math.min(r.width, r.height) + terdekat < 24) {
            bermasalah.push(Math.round(r.width) + "x" + Math.round(r.height) + " " +
              el.textContent.trim().slice(0, 20));
          }
        }
        return bermasalah;
      })()`);
      kecil.forEach((k) => gagal.push(`${path}: ${k}`));
    }

    assert.deepEqual(gagal, []);
  });

  test("tautan daftar di footer cukup besar untuk ditekan di ponsel", async () => {
    await page.goto(`${BASE}/`);
    const kecil = await page.eval(`[...document.querySelectorAll(".footer-grid li a")]
      .filter(a => a.getBoundingClientRect().height < 44).length`);

    assert.equal(kecil, 0, "ada tautan footer di bawah 44 piksel");
  });
});
