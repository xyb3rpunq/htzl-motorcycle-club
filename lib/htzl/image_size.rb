# frozen_string_literal: true

module HTZL
  # Membaca dimensi berkas gambar langsung dari header, tanpa pustaka gambar.
  #
  # Dipakai saat build agar atribut width dan height di HTML memuat ukuran yang
  # sebenarnya. Ukuran foto heritage tidak seragam karena sebagian berkas asli
  # di Wikimedia Commons lebih kecil dari lebar yang diminta, jadi menuliskan
  # satu angka tetap untuk semuanya akan salah.
  module ImageSize
    module_function

    def read(path)
      return nil unless File.exist?(path)

      case File.extname(path).downcase
      when ".svg"  then svg(path)
      when ".webp" then webp(path)
      end
    end

    # SVG menyimpan ukurannya sebagai atribut biasa di elemen pembuka.
    def svg(path)
      head = File.read(path, 500, encoding: "utf-8")
      width = head[/width="(\d+)"/, 1]
      height = head[/height="(\d+)"/, 1]
      width && height ? [width.to_i, height.to_i] : nil
    end

    # WebP punya tiga bentuk header. Ketiganya menyimpan ukuran di tempat yang
    # berbeda, jadi jenis chunk-nya diperiksa lebih dulu.
    #   VP8    lossy
    #   VP8L   lossless
    #   VP8X   extended, dipakai bila gambar punya kanal alfa
    def webp(path)
      data = File.binread(path, 32)
      return nil unless data && data.bytesize >= 30
      return nil unless data[0, 4] == "RIFF" && data[8, 4] == "WEBP"

      case data[12, 4]
      when "VP8 " then lossy(data)
      when "VP8L" then lossless(data)
      when "VP8X" then extended(data)
      end
    end

    # Tanda sinkronisasi 0x9d 0x01 0x2a diikuti lebar dan tinggi 14 bit.
    def lossy(data)
      return nil unless data[23, 3].unpack("C3") == [0x9d, 0x01, 0x2a]

      width, height = data[26, 4].unpack("v2")
      [width & 0x3fff, height & 0x3fff]
    end

    # Empat byte setelah tanda 0x2f memuat lebar dan tinggi, masing-masing
    # 14 bit dan disimpan dikurangi satu.
    def lossless(data)
      return nil unless data[20, 1].unpack1("C") == 0x2f

      bits = data[21, 4].unpack1("V")
      [(bits & 0x3fff) + 1, ((bits >> 14) & 0x3fff) + 1]
    end

    # Ukuran kanvas disimpan sebagai dua bilangan 24 bit little-endian,
    # keduanya dikurangi satu.
    def extended(data)
      [triple(data, 24) + 1, triple(data, 27) + 1]
    end

    def triple(data, offset)
      low, mid, high = data[offset, 3].unpack("C3")
      low | (mid << 8) | (high << 16)
    end
  end
end
