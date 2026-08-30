# -*- coding: utf-8 -*-
"""Ambil foto Harley-Davidson berlisensi bebas dari Wikimedia Commons.

Tugas khusus pengembang, bukan bagian dari build. Hasilnya (gambar WebP dan
_data/photo_credits.yml) ikut disimpan di repositori sehingga CI tidak perlu
mengakses jaringan.

    rake photos

Hanya berkas dengan lisensi bebas yang diambil: domain publik, CC0, CC BY, dan
CC BY-SA. Nama pembuat, jenis lisensi, dan tautan sumber dicatat untuk tiap
gambar, lalu ditampilkan di halaman detail produk dan di NOTICE.md.
"""
import html
import io
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "img", "heritage")
CREDITS = os.path.join(ROOT, "_data", "photo_credits.yml")

UA = "HTZL-Portfolio/1.0 (https://github.com/xyb3rpunq/htzl-motorcycle-club; portfolio project)"
API = "https://commons.wikimedia.org/w/api.php"

# Hanya lisensi yang mengizinkan penggunaan ulang dengan atribusi.
ALLOWED = re.compile(r"^(public domain|cc0|cc by(-sa)? \d)", re.I)
BLOCKED = re.compile(r"(non-?commercial|nc\b|nd\b|fair use|copyright)", re.I)

TARGET_W, TARGET_H = 630, 390


def call(params):
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=45) as resp:
        return json.load(resp)


def strip_html(value):
    text = re.sub(r"<[^>]+>", "", value or "")
    return html.unescape(text).strip().replace("\n", " ")[:120]


def search(term, limit=8):
    """Cari berkas gambar dan kembalikan kandidat berlisensi bebas."""
    try:
        data = call({
            "action": "query", "format": "json",
            "generator": "search", "gsrsearch": "filetype:bitmap " + term,
            "gsrnamespace": 6, "gsrlimit": limit,
            "prop": "imageinfo",
            "iiprop": "url|extmetadata|size|mime",
            "iiurlwidth": 1000,
        })
    except Exception as exc:  # jaringan bermasalah, lanjut ke unit berikutnya
        print("    ! gagal mencari: %s" % exc)
        return []

    out = []
    for page in (data.get("query", {}).get("pages", {}) or {}).values():
        info = (page.get("imageinfo") or [{}])[0]
        meta = info.get("extmetadata", {}) or {}
        license_name = (meta.get("LicenseShortName", {}) or {}).get("value", "")
        if not ALLOWED.match(license_name) or BLOCKED.search(license_name):
            continue
        if (info.get("width") or 0) < 800:
            continue
        if info.get("mime", "") not in ("image/jpeg", "image/png"):
            continue
        out.append({
            "title": page["title"],
            "thumb": info.get("thumburl"),
            "page": info.get("descriptionurl"),
            "license": license_name,
            "license_url": (meta.get("LicenseUrl", {}) or {}).get("value", ""),
            "author": strip_html((meta.get("Artist", {}) or {}).get("value", "")),
        })
    return out


def score(candidate, year, name):
    """Utamakan berkas yang judulnya menyebut tahun atau nama model."""
    title = candidate["title"].lower()
    points = 0
    if str(year) in title:
        points += 5
    for word in re.findall(r"[a-z0-9]{4,}", name.lower()):
        if word in title:
            points += 2
    if "museum" in title:
        points += 1
    return points


def download(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def save_webp(raw, path):
    im = Image.open(io.BytesIO(raw))
    im = im.convert("RGB")
    target = TARGET_W / float(TARGET_H)
    w, h = im.size
    if w / float(h) > target:
        nw = int(round(h * target))
        im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = int(round(w / target))
        im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    im = im.resize((TARGET_W, TARGET_H), Image.LANCZOS)
    im.save(path, "WEBP", quality=78, method=6)
    return os.path.getsize(path)


def yaml_quote(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    sys.path.insert(0, os.path.join(ROOT, "lib"))
    units = json.loads(os.environ["HTZL_UNITS"])

    os.makedirs(OUT_DIR, exist_ok=True)
    credits = []
    found = 0

    for index, unit in enumerate(units, 1):
        slug, year, name, query = unit["slug"], unit["year"], unit["name"], unit["query"]
        dest = os.path.join(OUT_DIR, slug + ".webp")
        candidates = search(query)
        if not candidates:
            print("[%3d/%d] tidak ada foto bebas: %s" % (index, len(units), name))
            time.sleep(0.25)
            continue

        best = sorted(candidates, key=lambda c: -score(c, year, name))[0]
        try:
            size = save_webp(download(best["thumb"]), dest)
        except Exception as exc:
            print("[%3d/%d] gagal unduh %s: %s" % (index, len(units), name, exc))
            time.sleep(0.25)
            continue

        found += 1
        credits.append({
            "slug": slug,
            "file": "/assets/img/heritage/%s.webp" % slug,
            "title": best["title"].replace("File:", ""),
            "author": best["author"] or "Wikimedia Commons",
            "license": best["license"],
            "license_url": best["license_url"],
            "source": best["page"],
        })
        print("[%3d/%d] %-46s %-16s %d KB" % (index, len(units), slug[:46], best["license"], size // 1024))
        time.sleep(0.25)

    with io.open(CREDITS, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# DIBUAT OTOMATIS oleh lib/fetch_heritage_photos.py - jangan diedit manual.\n")
        fh.write("# Atribusi wajib untuk gambar berlisensi Creative Commons.\n")
        for c in credits:
            fh.write("- slug: %s\n" % yaml_quote(c["slug"]))
            fh.write("  file: %s\n" % yaml_quote(c["file"]))
            fh.write("  title: %s\n" % yaml_quote(c["title"]))
            fh.write("  author: %s\n" % yaml_quote(c["author"]))
            fh.write("  license: %s\n" % yaml_quote(c["license"]))
            fh.write("  license_url: %s\n" % yaml_quote(c["license_url"]))
            fh.write("  source: %s\n" % yaml_quote(c["source"]))

    print("\nselesai: %d foto berlisensi bebas dari %d unit" % (found, len(units)))


if __name__ == "__main__":
    main()
