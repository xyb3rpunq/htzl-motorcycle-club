// Uji tata letak di peramban sungguhan, lintas bahasa dan lebar layar.
//
// Cacat seperti panel tertutup yang tetap memakan ruang tidak terlihat oleh
// pemindai aksesibilitas maupun test yang membaca berkas: markupnya sah, dan
// yang salah adalah hasil perhitungan tata letaknya.
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

after(async () => { await page?.resetSize().catch(() => {}); page?.close(); situs?.close(); });

const HALAMAN = ["/", "/catalog/", "/heritage/", "/gallery/", "/reserve/", "/kawasaki/", "/vixian/"];
const BAHASA = ["", "/en", "/zh", "/ru", "/ja"];
const LEBAR = [320, 390, 768, 1440];

// Rentang yang memang digulir mendatar oleh desainnya sendiri.
const PENGUKUR = `(() => {
  const doc = document.documentElement;
  const bolehLewat = (el) => el.closest("[data-hero-track],.hero,.chips,.timeline,[data-grid],dialog") !== null;

  const terpotong = [];
  const lewatTepi = [];
  document.querySelectorAll("body *").forEach((el) => {
    const cs = getComputedStyle(el);
    if (cs.display === "none" || cs.visibility === "hidden") return;
    if (el.closest(".visually-hidden, .skip-link")) return;
    const r = el.getBoundingClientRect();
    if (!r.width || !r.height) return;

    let indukGulir = null;
    for (let n = el.parentElement; n; n = n.parentElement) {
      if (/auto|scroll/.test(getComputedStyle(n).overflowX)) { indukGulir = n; break; }
    }

    if (!/auto|scroll/.test(cs.overflowX) && !indukGulir &&
        el.scrollWidth - el.clientWidth > 1 && el.children.length === 0) {
      terpotong.push(el.tagName.toLowerCase() + " | " + (el.textContent || "").trim().slice(0, 24));
    }
    if (r.right > doc.clientWidth + 1 && cs.position !== "fixed" && !indukGulir && !bolehLewat(el)) {
      lewatTepi.push(el.tagName.toLowerCase() + "." + (el.className || "").toString().split(" ")[0]);
    }
  });

  return {
    luap: Math.max(0, doc.scrollWidth - doc.clientWidth),
    terpotong: [...new Set(terpotong)],
    lewatTepi: [...new Set(lewatTepi)],
  };
})()`;

describe("tata letak lintas bahasa dan lebar layar", () => {
  // Pengukurnya sendiri harus terbukti bisa menemukan cacat. Angka nol dari
  // alat yang tidak berfungsi tidak membuktikan apa pun.
  test("pengukur benar-benar mendeteksi luapan yang disengaja", async () => {
    await page.resize(390);
    await page.goto(`${BASE}/reserve/`);

    assert.equal((await page.eval(PENGUKUR)).luap, 0, "halaman ini seharusnya bersih");

    await page.eval(`(() => { const d = document.createElement("div");
      d.style.cssText = "width:1400px;height:20px"; document.querySelector("main").appendChild(d); })()`);

    assert.ok((await page.eval(PENGUKUR)).luap > 0, "pengukur gagal melihat luapan yang disengaja");
  });

  test("pengukur benar-benar mendeteksi teks yang terpotong", async () => {
    await page.resize(390);
    await page.goto(`${BASE}/reserve/`);
    await page.eval(`(() => { const el = document.createElement("p");
      el.style.cssText = "width:40px;overflow:hidden;white-space:nowrap";
      el.textContent = "teks yang jauh lebih panjang daripada kotaknya";
      document.querySelector("main").appendChild(el); })()`);

    assert.ok((await page.eval(PENGUKUR)).terpotong.length > 0);
  });

  for (const lebar of LEBAR) {
    test(`tidak ada halaman yang bisa digulir mendatar pada lebar ${lebar} px`, async () => {
      await page.resize(lebar);
      const gagal = [];
      for (const bahasa of BAHASA) {
        for (const halaman of HALAMAN) {
          await page.goto(`${BASE}${bahasa}${halaman}`);
          const r = await page.eval(PENGUKUR);
          if (r.luap > 0) gagal.push(`${bahasa || "/id"}${halaman}: luap ${r.luap} px`);
          if (r.terpotong.length) gagal.push(`${bahasa || "/id"}${halaman}: terpotong ${r.terpotong[0]}`);
          if (r.lewatTepi.length) gagal.push(`${bahasa || "/id"}${halaman}: lewat tepi ${r.lewatTepi[0]}`);
        }
      }

      assert.deepEqual(gagal, []);
    });
  }
});
