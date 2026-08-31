# -*- coding: utf-8 -*-
"""Buat varian ukuran untuk tiap gambar yang ditampilkan responsif.

Dua kelompok gambar, dua kebutuhan berbeda.

Kartu katalog hanya menampilkan gambar selebar 244 sampai 424 piksel, sementara
berkas sumbernya 630 sampai 900 piksel. Hero dan banner sebaliknya: berkasnya
1280 sampai 1600 piksel dan dikirim utuh bahkan ke layar 390 piksel.

Berkas hasil skrip ini dipakai lewat atribut srcset; peramban yang memilih
ukuran mana yang diunduh, berdasarkan lebar tampil dan kerapatan layarnya.

    rake photos:thumbs
"""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Tiap kelompok: pola berkas, lebar varian, dan anggaran byte per lebar.
# Kualitas diturunkan sampai muat anggaran, karena gunanya varian adalah
# menjadi ringan; kalau anggarannya yang dinaikkan, varian kehilangan makna.
GROUPS = [
    {
        "label": "kartu",
        "globs": ["assets/img/heritage/*.webp", "assets/img/bikes/*.webp"],
        "budget": {384: 25 * 1024, 640: 60 * 1024},
        "quality": [76, 70, 64, 58, 52],
    },
    {
        "label": "hero dan banner",
        "globs": [
            "assets/img/hero/*.webp",
            "assets/img/banner-*.webp",
            "assets/img/about.webp",
            "assets/img/gallery/museum-hall.webp",
        ],
        "budget": {640: 60 * 1024, 960: 110 * 1024, 1280: 180 * 1024},
        # Hero tampil selebar layar, jadi cacat kompresi lebih mudah terlihat.
        "quality": [80, 74, 68, 62, 56],
    },
]

ALL_WIDTHS = sorted({w for g in GROUPS for w in g["budget"]})


def is_variant(path):
    """Berkas yang memang varian, bukan sumber.

    Pencocokan harus tepat ke daftar lebar; sebagian slug berakhir angka,
    misalnya "harley-davidson-1905-model-2".
    """
    stem = os.path.splitext(os.path.basename(path))[0]
    return any(stem.endswith("-%d" % w) for w in ALL_WIDTHS)


def variants(path, budget, quality_steps):
    made = []
    with Image.open(path) as im:
        source_w, source_h = im.size
        for width in sorted(budget):
            if width >= source_w:
                continue
            dest = "%s-%d.webp" % (os.path.splitext(path)[0], width)
            height = int(round(width * source_h / float(source_w)))
            small = im.convert("RGB").resize((width, height), Image.LANCZOS)

            for quality in quality_steps:
                small.save(dest, "WEBP", quality=quality, method=6)
                if os.path.getsize(dest) <= budget[width]:
                    break

            made.append((dest, os.path.getsize(dest)))
    return made


def main():
    grand_src = grand_var = grand_count = 0

    for group in GROUPS:
        paths = []
        for pattern in group["globs"]:
            paths.extend(glob.glob(os.path.join(ROOT, pattern)))
        paths = sorted(p for p in set(paths) if not is_variant(p))

        src = var = count = 0
        for path in paths:
            src += os.path.getsize(path)
            for _, size in variants(path, group["budget"], group["quality"]):
                var += size
                count += 1

        print("%-16s %3d sumber -> %3d varian   %5.1f MB -> %5.1f MB" % (
            group["label"], len(paths), count, src / 1048576.0, var / 1048576.0))
        grand_src += src
        grand_var += var
        grand_count += count

    print("%-16s %19d varian   %5.1f MB -> %5.1f MB" % (
        "total", grand_count, grand_src / 1048576.0, grand_var / 1048576.0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
