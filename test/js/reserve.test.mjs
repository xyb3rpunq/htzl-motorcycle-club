/*
 * Test fungsi murni pada assets/js/reserve.js.
 *
 * Berkas itu adalah IIFE yang berhenti lebih awal bila formulir tidak ada di
 * halaman, tetapi objek validatornya sudah diekspor ke window sebelum
 * pemeriksaan tersebut. Jadi cukup sediakan window dan document tiruan, lalu
 * jalankan sumbernya apa adanya: tidak perlu bundler maupun peramban.
 *
 *   node --test test/js/
 */
import { test, describe, before } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import vm from "node:vm";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const FIXTURE = JSON.parse(readFileSync(join(ROOT, "test", "fixtures", "rupiah.json"), "utf8"));

let V;

before(() => {
  const sandbox = {
    window: { HTZL: { $: () => null, $$: () => [] } },
    document: { querySelector: () => null },
  };
  sandbox.globalThis = sandbox;
  vm.createContext(sandbox);
  vm.runInContext(readFileSync(join(ROOT, "assets", "js", "reserve.js"), "utf8"), sandbox);
  V = sandbox.window.HTZLReserve;
  assert.ok(V, "reserve.js harus mengekspor window.HTZLReserve");
});

describe("isFullName", () => {
  test("menerima nama dua kata atau lebih", () => {
    assert.equal(V.isFullName("Daniel Hutajulu"), true);
    assert.equal(V.isFullName("Daniel Parulian Hutajulu"), true);
    assert.equal(V.isFullName("  Daniel   Hutajulu  "), true, "spasi berlebih tidak boleh mengganggu");
  });

  test("menolak nama satu kata atau kosong", () => {
    assert.equal(V.isFullName("Daniel"), false);
    assert.equal(V.isFullName(""), false);
    assert.equal(V.isFullName("   "), false);
  });
});

describe("isDigitsOnly", () => {
  test("hanya menerima angka", () => {
    assert.equal(V.isDigitsOnly("081386159080"), true);
    assert.equal(V.isDigitsOnly("0813-8615-9080"), false);
    assert.equal(V.isDigitsOnly("+6281386159080"), false);
    assert.equal(V.isDigitsOnly("08a1"), false);
    assert.equal(V.isDigitsOnly(""), false);
  });
});

describe("hasPhoneLength", () => {
  test("menerima panjang nomor Indonesia yang wajar", () => {
    assert.equal(V.hasPhoneLength("081386159080"), true);
    assert.equal(V.hasPhoneLength("021234567"), true, "sembilan digit adalah batas bawah");
  });

  test("menolak yang terlalu pendek atau terlalu panjang", () => {
    assert.equal(V.hasPhoneLength("0812"), false);
    assert.equal(V.hasPhoneLength("0123456789012345678"), false);
  });
});

describe("isQuantity", () => {
  test("hanya menerima bilangan bulat 1 sampai 10", () => {
    assert.equal(V.isQuantity(1), true);
    assert.equal(V.isQuantity("10"), true);
    assert.equal(V.isQuantity(0), false);
    assert.equal(V.isQuantity(11), false);
    assert.equal(V.isQuantity(2.5), false);
    assert.equal(V.isQuantity("dua"), false);
  });
});

describe("isFilled", () => {
  test("menganggap spasi saja sebagai kosong", () => {
    assert.equal(V.isFilled("a"), true);
    assert.equal(V.isFilled("   "), false);
    assert.equal(V.isFilled(""), false);
  });
});

describe("rupiah", () => {
  // Kontrak lintas bahasa: Ruby memformat harga saat build, JavaScript
  // memformatnya lagi saat jumlah pesanan berubah. Keduanya membaca berkas
  // yang sama di test/fixtures/rupiah.json.
  for (const [input, expected] of FIXTURE.cases) {
    test(`${input} menjadi ${expected}`, () => {
      assert.equal(V.rupiah(input), expected);
    });
  }

  for (const [input, expected] of FIXTURE.negative) {
    test(`${input} menjadi ${expected}`, () => {
      assert.equal(V.rupiah(input), expected);
    });
  }

  test("nilai bukan angka diperlakukan sebagai nol", () => {
    assert.equal(V.rupiah("bukan angka"), "Rp 0");
    assert.equal(V.rupiah(null), "Rp 0");
  });
});

describe("buildWhatsAppUrl", () => {
  test("membersihkan nomor dan menyandi pesan", () => {
    const url = V.buildWhatsAppUrl("+62 813-8615-9080", ["Halo HTZL", "Model: Kawasaki x56"]);
    assert.ok(url.startsWith("https://wa.me/6281386159080?text="), "nomor harus jadi digit saja");
    assert.ok(!url.includes(" "), "spasi wajib tersandi");
    assert.ok(url.includes("%0A"), "pemisah baris wajib tersandi");
  });

  test("melewati baris kosong", () => {
    const url = V.buildWhatsAppUrl("6281", ["satu", "", null, "dua"]);
    assert.equal(decodeURIComponent(url.split("text=")[1]), "satu\ndua");
  });

  test("menyandi karakter non-Latin", () => {
    const url = V.buildWhatsAppUrl("6281", ["Здравствуйте"]);
    assert.ok(url.includes("%D0%97"), "huruf Kiril harus tersandi UTF-8");
  });
});
