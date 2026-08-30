# frozen_string_literal: true

module HTZL
  # Koleksi Heritage: 100 unit Harley-Davidson diurutkan dari yang tertua
  # (1903) sampai era Milwaukee-Eight. Data model, tahun, dan generasi mesin
  # mengikuti sejarah produk yang sebenarnya; harga adalah angka contoh untuk
  # keperluan portofolio.
  #
  # Kolom `query` dipakai lib/fetch_photos.rb untuk mencari foto berlisensi
  # bebas di Wikimedia Commons.
  module Heritage
    # [tahun, nama, era mesin, cc, hp, rangka, kelangkaan, harga, query Commons]
    UNITS = [
      [1903, "Model 1 Serial Number One", "Atmospheric IOE", 405, 3, "Rigid loop", "Museum", 4_500_000_000, "Harley-Davidson 1903 Serial Number One"],
      [1905, "Model 2", "Atmospheric IOE", 440, 3, "Rigid loop", "Museum", 3_200_000_000, "Harley-Davidson 1905 motorcycle"],
      [1906, "Model 3 Silent Gray Fellow", "Atmospheric IOE", 440, 4, "Rigid loop", "Museum", 2_900_000_000, "Harley-Davidson Silent Gray Fellow"],
      [1907, "Model 4", "Atmospheric IOE", 440, 4, "Rigid loop", "Museum", 2_600_000_000, "Harley-Davidson 1907 motorcycle"],
      [1908, "Model 5", "Atmospheric IOE", 494, 4, "Rigid loop", "Museum", 2_400_000_000, "Harley-Davidson 1908 motorcycle"],
      [1909, "Model 5D V-Twin", "F-Head V-Twin", 811, 7, "Rigid loop", "Museum", 3_800_000_000, "Harley-Davidson 1909 V-twin"],
      [1911, "Model 7D", "F-Head V-Twin", 811, 7, "Rigid loop", "Sangat langka", 1_800_000_000, "Harley-Davidson 1911 motorcycle"],
      [1912, "Model X8A", "F-Head Single", 494, 5, "Rigid, Ful-Floteing seat", "Sangat langka", 1_450_000_000, "Harley-Davidson 1912 motorcycle"],
      [1913, "Model 9A", "F-Head Single", 565, 5, "Rigid loop", "Sangat langka", 1_300_000_000, "Harley-Davidson 1913 motorcycle"],
      [1914, "Model 10F", "F-Head V-Twin", 989, 11, "Rigid, dua kecepatan", "Sangat langka", 1_500_000_000, "Harley-Davidson 1914 motorcycle"],
      [1915, "Model 11F", "F-Head V-Twin", 989, 11, "Rigid, tiga kecepatan", "Sangat langka", 1_400_000_000, "Harley-Davidson 1915 motorcycle"],
      [1916, "Model 16J", "F-Head V-Twin", 989, 11, "Rigid loop", "Sangat langka", 1_250_000_000, "Harley-Davidson 1916 motorcycle"],
      [1917, "Model 17F", "F-Head V-Twin", 989, 16, "Rigid loop", "Sangat langka", 1_200_000_000, "Harley-Davidson 1917 motorcycle"],
      [1918, "Model 18J Perang Dunia I", "F-Head V-Twin", 989, 16, "Rigid loop", "Sangat langka", 1_350_000_000, "Harley-Davidson World War I motorcycle"],
      [1919, "Model W Sport Twin", "Flat Twin", 584, 6, "Rigid, mesin memanjang", "Sangat langka", 1_100_000_000, "Harley-Davidson Sport Twin"],
      [1920, "Model 20J", "F-Head V-Twin", 989, 16, "Rigid loop", "Langka", 950_000_000, "Harley-Davidson 1920 motorcycle"],
      [1921, "Model 21JD", "F-Head V-Twin", 1_213, 18, "Rigid loop", "Langka", 1_050_000_000, "Harley-Davidson 1921 motorcycle"],
      [1922, "Model 22FD", "F-Head V-Twin", 1_213, 18, "Rigid loop", "Langka", 900_000_000, "Harley-Davidson 1922 motorcycle"],
      [1923, "Model 23JD", "F-Head V-Twin", 1_213, 18, "Rigid loop", "Langka", 880_000_000, "Harley-Davidson 1923 motorcycle"],
      [1924, "Model 24FD", "F-Head V-Twin", 1_213, 18, "Rigid, piston aluminium", "Langka", 860_000_000, "Harley-Davidson 1924 motorcycle"],
      [1925, "Model 25JD", "F-Head V-Twin", 1_213, 24, "Rigid, rangka rendah", "Langka", 840_000_000, "Harley-Davidson 1925 motorcycle"],
      [1926, "Model A Peashooter", "Flathead Single", 346, 12, "Rigid ringan", "Langka", 780_000_000, "Harley-Davidson Peashooter"],
      [1927, "Model BA", "OHV Single", 346, 12, "Rigid ringan", "Langka", 720_000_000, "Harley-Davidson 1927 motorcycle"],
      [1928, "Model JDH Two-Cam", "F-Head V-Twin", 1_213, 29, "Rigid, rem depan", "Sangat langka", 1_600_000_000, "Harley-Davidson JDH Two Cam"],
      [1929, "Model D Flathead 45", "Flathead V-Twin", 737, 15, "Rigid loop", "Langka", 650_000_000, "Harley-Davidson Model D 1929"],
      [1930, "Model VL", "Flathead V-Twin", 1_213, 30, "Rigid, rangka baru", "Langka", 700_000_000, "Harley-Davidson Model VL"],
      [1932, "Model G Servi-Car", "Flathead V-Twin", 737, 15, "Roda tiga", "Langka", 550_000_000, "Harley-Davidson Servi-Car"],
      [1933, "Model VLD Art Deco", "Flathead V-Twin", 1_213, 36, "Rigid, livery Art Deco", "Sangat langka", 950_000_000, "Harley-Davidson 1933 motorcycle"],
      [1935, "Model RL 45", "Flathead V-Twin", 737, 18, "Rigid loop", "Langka", 580_000_000, "Harley-Davidson 1935 motorcycle"],
      [1936, "Model EL Knucklehead", "Knucklehead", 989, 40, "Rigid, tangki teardrop", "Ikonik", 2_200_000_000, "Harley-Davidson EL Knucklehead 1936"],
      [1937, "Model ULH", "Flathead V-Twin", 1_311, 34, "Rigid loop", "Langka", 640_000_000, "Harley-Davidson 1937 motorcycle"],
      [1938, "Model EL", "Knucklehead", 989, 40, "Rigid loop", "Ikonik", 1_500_000_000, "Harley-Davidson 1938 Knucklehead"],
      [1939, "Model WLD Sport Solo", "Flathead V-Twin", 737, 22, "Rigid loop", "Langka", 520_000_000, "Harley-Davidson WLD"],
      [1940, "Model WLA Militer", "Flathead V-Twin", 737, 23, "Rigid, dudukan senapan", "Ikonik", 620_000_000, "Harley-Davidson WLA"],
      [1941, "Model FL Knucklehead 74", "Knucklehead", 1_213, 48, "Rigid loop", "Ikonik", 1_400_000_000, "Harley-Davidson 1941 FL Knucklehead"],
      [1942, "Model XA Shaft Drive", "Flat Twin", 739, 23, "Rigid, gardan poros", "Sangat langka", 1_100_000_000, "Harley-Davidson XA"],
      [1943, "Model WLC Kanada", "Flathead V-Twin", 737, 23, "Rigid militer", "Langka", 560_000_000, "Harley-Davidson WLC"],
      [1945, "Model WL Pascaperang", "Flathead V-Twin", 737, 23, "Rigid loop", "Langka", 480_000_000, "Harley-Davidson WL 1945"],
      [1946, "Model FL", "Knucklehead", 1_213, 48, "Rigid loop", "Ikonik", 1_250_000_000, "Harley-Davidson 1946 Knucklehead"],
      [1947, "Model WL Sport Solo", "Flathead V-Twin", 737, 23, "Rigid loop", "Langka", 470_000_000, "Harley-Davidson 1947 WL"],
      [1948, "Model FL Panhead", "Panhead", 1_213, 50, "Rigid, garpu Springer", "Ikonik", 1_100_000_000, "Harley-Davidson 1948 Panhead"],
      [1949, "Model FL Hydra-Glide", "Panhead", 1_213, 55, "Rigid, garpu teleskopik", "Ikonik", 980_000_000, "Harley-Davidson Hydra-Glide"],
      [1950, "Model EL Panhead 61", "Panhead", 989, 50, "Rigid loop", "Langka", 850_000_000, "Harley-Davidson 1950 Panhead"],
      [1952, "Model K", "Flathead V-Twin", 737, 30, "Swingarm, transmisi unit", "Langka", 520_000_000, "Harley-Davidson Model K"],
      [1953, "Model FL 50th Anniversary", "Panhead", 1_213, 55, "Rigid loop", "Ikonik", 920_000_000, "Harley-Davidson 1953 Panhead"],
      [1954, "Model KH", "Flathead V-Twin", 883, 38, "Swingarm", "Langka", 540_000_000, "Harley-Davidson Model KH"],
      [1955, "Model KHK", "Flathead V-Twin", 883, 42, "Swingarm", "Langka", 580_000_000, "Harley-Davidson KHK"],
      [1956, "Model FLH Panhead", "Panhead", 1_213, 60, "Swingarm", "Ikonik", 780_000_000, "Harley-Davidson 1956 FLH"],
      [1957, "Sportster XL", "Ironhead Sportster", 883, 40, "Swingarm", "Ikonik", 620_000_000, "Harley-Davidson Sportster 1957"],
      [1958, "Duo-Glide FLH", "Panhead", 1_213, 60, "Swingarm, suspensi ganda", "Ikonik", 720_000_000, "Harley-Davidson Duo-Glide"],
      [1959, "Sportster XLCH", "Ironhead Sportster", 883, 45, "Swingarm", "Ikonik", 580_000_000, "Harley-Davidson XLCH"],
      [1960, "Topper Skuter", "Two-Stroke Single", 165, 9, "Rangka skuter", "Sangat langka", 340_000_000, "Harley-Davidson Topper"],
      [1961, "Sprint C", "OHV Single", 246, 18, "Swingarm", "Langka", 260_000_000, "Harley-Davidson Sprint"],
      [1962, "Duo-Glide FL", "Panhead", 1_213, 55, "Swingarm", "Langka", 650_000_000, "Harley-Davidson 1962 Duo-Glide"],
      [1963, "Panhead FLH", "Panhead", 1_213, 60, "Swingarm", "Langka", 680_000_000, "Harley-Davidson 1963 FLH"],
      [1964, "Servi-Car GE", "Flathead V-Twin", 737, 22, "Roda tiga", "Langka", 380_000_000, "Harley-Davidson Servi-Car GE"],
      [1965, "Electra Glide FLH", "Panhead", 1_213, 60, "Swingarm, starter elektrik", "Ikonik", 850_000_000, "Harley-Davidson Electra Glide 1965"],
      [1966, "Electra Glide Shovelhead", "Shovelhead", 1_208, 60, "Swingarm", "Ikonik", 620_000_000, "Harley-Davidson Shovelhead"],
      [1967, "Sportster XLH", "Ironhead Sportster", 883, 45, "Swingarm", "Langka", 420_000_000, "Harley-Davidson XLH 1967"],
      [1968, "Sportster XLCH 900", "Ironhead Sportster", 883, 48, "Swingarm", "Langka", 440_000_000, "Harley-Davidson XLCH 1968"],
      [1969, "Electra Glide FLH Shovelhead", "Shovelhead", 1_208, 65, "Swingarm", "Langka", 560_000_000, "Harley-Davidson 1969 Electra Glide"],
      [1970, "Sportster XLH 900", "Ironhead Sportster", 883, 50, "Swingarm", "Langka", 400_000_000, "Harley-Davidson Sportster 1970"],
      [1971, "Super Glide FX", "Shovelhead", 1_208, 65, "Swingarm, buritan boat-tail", "Ikonik", 580_000_000, "Harley-Davidson Super Glide FX"],
      [1972, "Sportster XLH 1000", "Ironhead Sportster", 998, 61, "Swingarm", "Langka", 380_000_000, "Harley-Davidson XLH 1000"],
      [1973, "Super Glide FX 1200", "Shovelhead", 1_208, 65, "Swingarm", "Langka", 440_000_000, "Harley-Davidson FX 1973"],
      [1974, "Sportster XLCH 1000", "Ironhead Sportster", 998, 61, "Swingarm", "Langka", 360_000_000, "Harley-Davidson XLCH 1000"],
      [1975, "Super Glide FXE", "Shovelhead", 1_208, 65, "Swingarm, starter elektrik", "Umum", 340_000_000, "Harley-Davidson FXE"],
      [1976, "Liberty Edition FLH", "Shovelhead", 1_208, 65, "Swingarm", "Langka", 480_000_000, "Harley-Davidson Liberty Edition"],
      [1977, "Low Rider FXS", "Shovelhead", 1_208, 65, "Swingarm, jok rendah", "Ikonik", 420_000_000, "Harley-Davidson Low Rider FXS"],
      [1977, "Cafe Racer XLCR", "Ironhead Sportster", 998, 61, "Swingarm, fairing cafe", "Sangat langka", 720_000_000, "Harley-Davidson XLCR"],
      [1978, "Electra Glide 75th Anniversary", "Shovelhead", 1_340, 65, "Swingarm", "Langka", 460_000_000, "Harley-Davidson 1978 Electra Glide"],
      [1979, "Fat Bob FXEF", "Shovelhead", 1_340, 65, "Swingarm, tangki ganda", "Langka", 400_000_000, "Harley-Davidson Fat Bob FXEF"],
      [1980, "Sturgis FXB", "Shovelhead", 1_340, 65, "Swingarm, penggerak sabuk", "Sangat langka", 620_000_000, "Harley-Davidson FXB Sturgis"],
      [1980, "Wide Glide FXWG", "Shovelhead", 1_340, 65, "Swingarm, garpu lebar", "Ikonik", 440_000_000, "Harley-Davidson Wide Glide"],
      [1980, "Tour Glide FLT", "Shovelhead", 1_340, 65, "Swingarm, fairing rangka", "Langka", 380_000_000, "Harley-Davidson Tour Glide"],
      [1983, "Low Glide FXRT", "Shovelhead", 1_340, 65, "Rangka FXR", "Langka", 340_000_000, "Harley-Davidson FXRT"],
      [1984, "Softail FXST", "Evolution", 1_340, 70, "Softail, kesan rigid", "Ikonik", 380_000_000, "Harley-Davidson FXST Softail"],
      [1985, "Low Rider FXSB", "Evolution", 1_340, 70, "Swingarm, penggerak sabuk", "Umum", 300_000_000, "Harley-Davidson FXSB"],
      [1986, "Heritage Softail FLST", "Evolution", 1_340, 70, "Softail retro", "Ikonik", 340_000_000, "Harley-Davidson Heritage Softail"],
      [1986, "Sportster XLH 883", "Evolution Sportster", 883, 53, "Swingarm", "Umum", 220_000_000, "Harley-Davidson Sportster 883"],
      [1987, "Low Rider Custom FXLR", "Evolution", 1_340, 70, "Swingarm", "Langka", 320_000_000, "Harley-Davidson FXLR"],
      [1988, "Springer Softail FXSTS", "Evolution", 1_340, 70, "Softail, garpu Springer", "Ikonik", 400_000_000, "Harley-Davidson Springer Softail"],
      [1988, "Electra Glide 85th Anniversary", "Evolution", 1_340, 70, "Swingarm", "Langka", 360_000_000, "Harley-Davidson 1988 Electra Glide"],
      [1989, "Ultra Classic Electra Glide", "Evolution", 1_340, 70, "Swingarm, tur lengkap", "Umum", 300_000_000, "Harley-Davidson Ultra Classic"],
      [1990, "Fat Boy FLSTF", "Evolution", 1_340, 70, "Softail, velg solid", "Ikonik", 460_000_000, "Harley-Davidson Fat Boy"],
      [1991, "Dyna Sturgis FXDB", "Evolution", 1_340, 70, "Rangka Dyna pertama", "Sangat langka", 420_000_000, "Harley-Davidson FXDB Sturgis"],
      [1992, "Bad Boy FXSTSB", "Evolution", 1_340, 70, "Softail, garpu Springer", "Langka", 380_000_000, "Harley-Davidson Bad Boy"],
      [1993, "Heritage Nostalgia FLSTN", "Evolution", 1_340, 70, "Softail, jok kulit sapi", "Sangat langka", 440_000_000, "Harley-Davidson FLSTN Nostalgia"],
      [1994, "Road King FLHR", "Evolution", 1_340, 70, "Swingarm, tur klasik", "Ikonik", 320_000_000, "Harley-Davidson Road King"],
      [1995, "Electra Glide FLHTCUI", "Evolution", 1_340, 70, "Swingarm, injeksi pertama", "Umum", 280_000_000, "Harley-Davidson Electra Glide Ultra"],
      [1996, "Dyna Wide Glide FXDWG", "Evolution", 1_340, 70, "Dyna, garpu lebar", "Umum", 290_000_000, "Harley-Davidson Dyna Wide Glide"],
      [1997, "Heritage Springer FLSTS", "Evolution", 1_340, 70, "Softail, garpu Springer", "Langka", 360_000_000, "Harley-Davidson Heritage Springer"],
      [1998, "Road Glide FLTR", "Evolution", 1_340, 70, "Swingarm, fairing shark-nose", "Umum", 300_000_000, "Harley-Davidson Road Glide"],
      [1999, "Dyna Super Glide Twin Cam 88", "Twin Cam 88", 1_450, 76, "Dyna", "Umum", 260_000_000, "Harley-Davidson Twin Cam 88"],
      [2001, "V-Rod VRSCA", "Revolution", 1_130, 115, "Rangka perimeter", "Ikonik", 340_000_000, "Harley-Davidson VRSC V-Rod"],
      [2006, "Street Rod VRSCR", "Revolution", 1_130, 120, "Rangka perimeter", "Sangat langka", 380_000_000, "Harley-Davidson Street Rod VRSCR"],
      [2008, "Rocker C FXCWC", "Twin Cam 96", 1_584, 78, "Softail, ban belakang 240", "Langka", 330_000_000, "Harley-Davidson Rocker"],
      [2011, "Blackline FXS", "Twin Cam 96", 1_584, 78, "Softail minimalis", "Langka", 310_000_000, "Harley-Davidson Blackline"],
      [2014, "Street 750 XG750", "Revolution X", 749, 60, "Rangka tubular", "Umum", 150_000_000, "Harley-Davidson Street 750"],
      [2017, "Road King Milwaukee-Eight FLHR", "Milwaukee-Eight", 1_745, 92, "Swingarm, tur klasik", "Umum", 420_000_000, "Harley-Davidson Milwaukee-Eight Road King"]
    ].freeze

    # Pengelompokan generasi mesin menjadi subkategori katalog.
    def self.subcategory(era)
      case era
      when /Atmospheric|F-Head/ then "Era Perintis"
      when /Flathead|Flat Twin/ then "Era Flathead"
      when /Knucklehead/        then "Era Knucklehead"
      when /Panhead/            then "Era Panhead"
      when /Shovelhead/         then "Era Shovelhead"
      when /Ironhead/           then "Era Ironhead"
      when /Evolution/          then "Era Evolution"
      when /Twin Cam/           then "Era Twin Cam"
      when /Revolution/         then "Era Revolution"
      when /Milwaukee/          then "Era Milwaukee-Eight"
      when /OHV Single|Two-Stroke/ then "Era Model Ringan"
      else "Era Lainnya"
      end
    end
  end
end
