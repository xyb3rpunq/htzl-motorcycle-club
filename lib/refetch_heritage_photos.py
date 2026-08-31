# -*- coding: utf-8 -*-
"""Ambil ulang foto heritage pada resolusi lebih tinggi.

Berbeda dari lib/fetch_heritage_photos.py yang mencari foto baru, skrip ini
mengunduh ulang berkas yang persis sama seperti yang sudah tercatat di
_data/photo_credits.yml. Atribusi karena itu tidak berubah sama sekali; yang
berubah hanya ketajamannya.

Alasannya: gambar pada dialog detail ditampilkan selebar 698 sampai 743 piksel,
sementara sumbernya hanya 630 piksel, sehingga diperbesar melebihi resolusi
aslinya dan terlihat kabur.

    rake photos:hires
"""
import io
import os
import re
import sys
import time
import urllib.parse
import urllib.request

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CREDITS = os.path.join(ROOT, "_data", "photo_credits.yml")
OUT_DIR = os.path.join(ROOT, "assets", "img", "heritage")

UA = "HTZL-Portfolio/1.0 (https://github.com/xyb3rpunq/htzl-motorcycle-club; portfolio project)"
API = "https://commons.wikimedia.org/w/api.php"

TARGET_W = int(os.environ.get("HTZL_WIDTH", "1100"))
TARGET_RATIO = 630 / 390.0


def read_credits():
    """Baca slug dan judul berkas dari YAML sederhana buatan skrip sebelumnya."""
    rows, cur = [], {}
    for line in io.open(CREDITS, encoding="utf-8"):
        match = re.match(r'^-?\s*(\w+): "(.*)"\s*$', line)
        if not match:
            continue
        key, value = match.group(1), match.group(2).replace('\\"', '"')
        if key == "slug":
            if cur:
                rows.append(cur)
            cur = {}
        cur[key] = value
    if cur:
        rows.append(cur)
    return rows


def thumb_url(title, width):
    params = {
        "action": "query", "format": "json",
        "titles": "File:" + title,
        "prop": "imageinfo", "iiprop": "url|size", "iiurlwidth": str(width),
    }
    req = urllib.request.Request(API + "?" + urllib.parse.urlencode(params), headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=45) as resp:
        import json
        data = json.load(resp)
    pages = (data.get("query", {}).get("pages", {}) or {}).values()
    for page in pages:
        info = (page.get("imageinfo") or [{}])[0]
        if info.get("thumburl"):
            return info["thumburl"], info.get("width", 0)
    return None, 0


def save(raw, path, width):
    im = Image.open(io.BytesIO(raw)).convert("RGB")
    w, h = im.size
    if w / float(h) > TARGET_RATIO:
        nw = int(round(h * TARGET_RATIO))
        im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = int(round(w / TARGET_RATIO))
        im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    im = im.resize((width, int(round(width / TARGET_RATIO))), Image.LANCZOS)
    im.save(path, "WEBP", quality=78, method=6)
    return os.path.getsize(path)


def main():
    credits = read_credits()
    if not credits:
        print("Tidak ada kredit foto; jalankan `rake photos` lebih dulu.")
        return 1

    before = after = 0
    updated = 0

    for index, credit in enumerate(credits, 1):
        dest = os.path.join(OUT_DIR, credit["slug"] + ".webp")
        if os.path.exists(dest):
            before += os.path.getsize(dest)

        url, original_width = thumb_url(credit["title"], TARGET_W)
        if not url:
            print("[%3d/%d] tidak dapat URL: %s" % (index, len(credits), credit["slug"]))
            continue

        # Jangan memperbesar melampaui resolusi berkas aslinya.
        width = min(TARGET_W, original_width) if original_width else TARGET_W

        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as resp:
                raw = resp.read()
            size = save(raw, dest, width)
        except Exception as exc:
            print("[%3d/%d] gagal %s: %s" % (index, len(credits), credit["slug"], exc))
            continue

        after += size
        updated += 1
        print("[%3d/%d] %-46s %4d px  %3d KB" % (index, len(credits), credit["slug"][:46], width, size // 1024))
        time.sleep(0.2)

    print("\n%d foto diperbarui: %.1f MB -> %.1f MB" % (updated, before / 1048576.0, after / 1048576.0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
