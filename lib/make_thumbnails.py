# -*- coding: utf-8 -*-
"""Buat varian kecil dari tiap foto katalog.

Kartu di halaman katalog hanya menampilkan gambar selebar 244 sampai 424 piksel,
sementara berkas sumbernya 630 sampai 900 piksel. Tanpa varian kecil, setiap
kartu mengunduh berkas penuh yang jauh lebih besar daripada yang dibutuhkan.

Berkas hasil skrip ini dipakai lewat atribut srcset; peramban yang memilih
ukuran mana yang diunduh, berdasarkan lebar tampil dan kerapatan layarnya.

    rake photos:thumbs
"""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIRS = ["assets/img/heritage", "assets/img/bikes"]
WIDTHS = [384, 640]

# Anggaran byte per varian. Gunanya varian adalah menjadi ringan, jadi kalau
# sebuah foto terlalu ramai untuk muat pada kualitas awal, kualitasnyalah yang
# diturunkan, bukan anggarannya yang dinaikkan.
BUDGET = {384: 25 * 1024, 640: 60 * 1024}
QUALITY_STEPS = [76, 70, 64, 58, 52]


def variants(path):
    """Hasilkan varian yang lebih kecil dari berkas aslinya saja."""
    made = []
    with Image.open(path) as im:
        source_w, source_h = im.size
        for width in WIDTHS:
            if width >= source_w:
                continue
            dest = "%s-%d.webp" % (os.path.splitext(path)[0], width)
            height = int(round(width * source_h / float(source_w)))
            small = im.convert("RGB").resize((width, height), Image.LANCZOS)

            for quality in QUALITY_STEPS:
                small.save(dest, "WEBP", quality=quality, method=6)
                if os.path.getsize(dest) <= BUDGET[width]:
                    break

            made.append((dest, os.path.getsize(dest)))
    return made


def main():
    total_src = total_thumb = 0
    count = 0

    for folder in DIRS:
        pattern = os.path.join(ROOT, folder, "*.webp")
        for path in sorted(glob.glob(pattern)):
            # Lewati berkas yang memang varian. Pencocokan harus tepat ke daftar
            # lebar; sebagian slug berakhir angka, misalnya "...-model-1".
            stem = os.path.splitext(os.path.basename(path))[0]
            if any(stem.endswith("-%d" % w) for w in WIDTHS):
                continue
            total_src += os.path.getsize(path)
            for _, size in variants(path):
                total_thumb += size
                count += 1

    print("%d varian dibuat" % count)
    print("berkas penuh : %.1f MB" % (total_src / 1048576.0))
    print("varian        : %.1f MB" % (total_thumb / 1048576.0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
