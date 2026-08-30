# frozen_string_literal: true

require "yaml"
require_relative "heritage"

module HTZL
  # Sumber tunggal katalog HTZL Motorcycle Club.
  #
  # Modul ini berperan seperti gabungan model + seeds di Rails: semua data
  # produk dibangun di sini secara deterministik (seed acak tetap), lalu
  # di-dump ke _data/catalog.yml supaya Jekyll bisa merender seluruh katalog
  # jadi HTML statis saat build. Tidak ada satu pun fungsi di sini yang
  # menyentuh jaringan atau waktu sistem, jadi hasilnya selalu reproducible.
  module Catalog
    SEED = 20_161_230 # tanggal berdiri HTZL, dipakai biar build selalu sama

    CATEGORIES = {
      "motor"    => { label: "Motor",              icon: "motorcycle", blurb: "Unit kendaraan siap kirim" },
      "apparel"  => { label: "Apparel & Gear",     icon: "helmet",     blurb: "Perlengkapan berkendara" },
      "part"     => { label: "Sparepart & Performa", icon: "piston",   blurb: "Komponen dan upgrade" },
      "oli"      => { label: "Oli & Perawatan",    icon: "oil",        blurb: "Pelumas dan cairan" },
      "aksesori" => { label: "Aksesori & Touring", icon: "topbox",     blurb: "Penunjang perjalanan jauh" },
      "layanan"  => { label: "Layanan Bengkel",    icon: "wrench",     blurb: "Servis oleh teknisi resmi" },
      "heritage" => { label: "Koleksi Heritage",   icon: "heritage",   blurb: "Harley-Davidson 1903 sampai kini" }
    }.freeze

    # --- Model motor dasar (spesifikasi diambil dari situs HTZL versi 2022) ---
    BIKES = [
      { name: "Kawasaki x56",         brand: "Kawasaki", type: "Superbike",     price: 45_000_000,
        cc: 1_362, hp: 165, nm: 194, seat: 785, image: "kawasaki-x56" },
      { name: "Kawasaki x57",         brand: "Kawasaki", type: "Sport Naked",   price: 55_000_000,
        cc: 1_367, hp: 168, nm: 187, seat: 790, image: "kawasaki-x57" },
      { name: "Kawasaki Black Sun",   brand: "Kawasaki", type: "Sport Naked",   price: 50_000_000,
        cc: 1_300, hp: 160, nm: 127, seat: 755, image: "kawasaki-black-sun" },
      { name: "Kawasaki Cross950",    brand: "Kawasaki", type: "Supermoto",     price: 44_000_000,
        cc: 937,   hp: 114, nm: 96,  seat: 870, image: "kawasaki-cross950" },
      { name: "Kawasaki Monster-21",  brand: "Kawasaki", type: "Sport Naked",   price: 60_000_000,
        cc: 1_262, hp: 162, nm: 192, seat: 780, image: "kawasaki-monster21" },
      { name: "Kawasaki 21SF",        brand: "Kawasaki", type: "Sport Naked",   price: 65_000_000,
        cc: 1_300, hp: 165, nm: 190, seat: 820, image: "kawasaki-21sf" },
      { name: "Vixian XF262",         brand: "Vixian",   type: "Sport Naked",   price: 45_000_000,
        cc: 1_113, hp: 214, nm: 124, seat: 835, image: "vixian-xf262" },
      { name: "Vixian CF300",         brand: "Vixian",   type: "Supermoto",     price: 40_000_000,
        cc: 1_158, hp: 170, nm: 208, seat: 860, image: "vixian-cf300" },
      { name: "Vixian Lumiere160",    brand: "Vixian",   type: "Sport Naked",   price: 46_000_000,
        cc: 1_154, hp: 168, nm: 130, seat: 836, image: "vixian-lumiere160" },
      { name: "Vixian MT-1260",       brand: "Vixian",   type: "Adventure",     price: 70_000_000,
        cc: 1_260, hp: 170, nm: 200, seat: 830, image: "vixian-mt1260" },
      { name: "Vixian MT-V4",         brand: "Vixian",   type: "Adventure",     price: 65_000_000,
        cc: 1_200, hp: 170, nm: 198, seat: 840, image: "vixian-mtv4" },
      { name: "Vixian SP01",          brand: "Vixian",   type: "Superbike",     price: 77_000_000,
        cc: 1_345, hp: 180, nm: 200, seat: 850, image: "vixian-sp01" }
    ].freeze

    # Tiap model dijual dalam tiga trim, persis seperti dealer sungguhan.
    TRIMS = [
      { suffix: "",    label: "Standard", mult: 1.00, hp_add: 0,  note: "Trim dasar dengan fitur harian lengkap." },
      { suffix: " S",  label: "S",        mult: 1.14, hp_add: 8,  note: "Suspensi Ohlins, quickshifter dua arah, dan velg forged." },
      { suffix: " SP", label: "SP",       mult: 1.28, hp_add: 15, note: "Paket balap: rem Brembo Stylema, bodi serat karbon, mode Track." }
    ].freeze

    COLORS = ["Midnight Black", "Racing Red", "Pearl White", "Matte Grey", "Racing Blue"].freeze

    # --- Item non-kendaraan: [nama, subkategori, harga, ikon, spesifikasi] ---
    APPAREL = [
      ["Helm Full Face HTZL Aero R1",     "Helm",        3_450_000, "helmet",   { "Sertifikasi" => "SNI, DOT, ECE 22.06", "Bahan" => "Fiberglass komposit", "Berat" => "1.450 g", "Visor" => "Pinlock anti-embun" }],
      ["Helm Full Face HTZL Aero R1 Carbon", "Helm",     6_200_000, "helmet",   { "Sertifikasi" => "DOT, ECE 22.06, FIM", "Bahan" => "Serat karbon 3K", "Berat" => "1.180 g", "Visor" => "Photochromic" }],
      ["Helm Modular HTZL Voyager",       "Helm",        4_100_000, "helmet",   { "Sertifikasi" => "SNI, ECE 22.06", "Bahan" => "Polikarbonat", "Berat" => "1.680 g", "Fitur" => "Sun visor internal" }],
      ["Helm Retro HTZL Classic 70",      "Helm",        1_750_000, "helmet",   { "Sertifikasi" => "SNI", "Bahan" => "ABS injeksi", "Berat" => "1.150 g", "Fitur" => "Bubble visor lepas-pasang" }],
      ["Helm Adventure HTZL Trail X",     "Helm",        4_850_000, "helmet",   { "Sertifikasi" => "DOT, ECE 22.06", "Bahan" => "Tri-composite", "Berat" => "1.520 g", "Fitur" => "Peak visor aerodinamis" }],
      ["Jaket Kulit HTZL Rider Pro",      "Jaket",       4_900_000, "jacket",   { "Bahan" => "Kulit sapi 1,2 mm", "Protektor" => "CE Level 2 bahu, siku, punggung", "Ventilasi" => "Perforasi dada", "Ukuran" => "S sampai 3XL" }],
      ["Jaket Tekstil HTZL Tourer 4S",    "Jaket",       3_250_000, "jacket",   { "Bahan" => "Cordura 600D", "Protektor" => "CE Level 1", "Cuaca" => "Waterproof 10.000 mm", "Lapisan" => "Thermal lepas-pasang" }],
      ["Jaket Mesh HTZL Urban Air",       "Jaket",       1_890_000, "jacket",   { "Bahan" => "Mesh poliester", "Protektor" => "CE Level 1 bahu & siku", "Ventilasi" => "Full mesh panel", "Ukuran" => "S sampai 2XL" }],
      ["Jaket Balap HTZL Track One",      "Jaket",       7_400_000, "jacket",   { "Bahan" => "Kulit kanguru", "Protektor" => "CE Level 2 + speed hump", "Fitur" => "Slider bahu titanium", "Jahitan" => "Triple stitch aramid" }],
      ["Rompi Airbag HTZL Guardian",      "Jaket",      11_500_000, "protector",{ "Sistem" => "Airbag elektronik", "Sensor" => "9 sumbu, 1.000 Hz", "Baterai" => "25 jam pakai", "Reload" => "Bisa dipakai ulang" }],
      ["Sarung Tangan Kulit HTZL Grip S", "Sarung Tangan", 890_000, "gloves",   { "Bahan" => "Kulit kambing", "Protektor" => "Knuckle TPU", "Fitur" => "Touchscreen ready", "Ukuran" => "S sampai XXL" }],
      ["Sarung Tangan Balap HTZL Apex",   "Sarung Tangan", 1_950_000, "gloves", { "Bahan" => "Kulit kanguru", "Protektor" => "Carbon knuckle + palm slider", "Sertifikasi" => "CE KP2", "Manset" => "Gauntlet panjang" }],
      ["Sarung Tangan Musim Hujan HTZL Aqua", "Sarung Tangan", 720_000, "gloves", { "Bahan" => "Softshell laminasi", "Cuaca" => "Waterproof + windproof", "Fitur" => "Wiper visor di jempol", "Ukuran" => "M sampai XL" }],
      ["Sarung Tangan Harian HTZL Daily", "Sarung Tangan", 385_000, "gloves",   { "Bahan" => "Sintetis + mesh", "Protektor" => "Padding EVA", "Fitur" => "Touchscreen ready", "Ukuran" => "S sampai XL" }],
      ["Sepatu Riding HTZL Boot GP",      "Sepatu",      3_700_000, "boots",    { "Bahan" => "Microfiber + TPU", "Protektor" => "Ankle brace, toe slider", "Sertifikasi" => "CE EN 13634", "Sol" => "Anti-slip racing" }],
      ["Sepatu Touring HTZL Roadster",    "Sepatu",      2_450_000, "boots",    { "Bahan" => "Kulit full grain", "Cuaca" => "Membran waterproof", "Protektor" => "Shin plate", "Sol" => "Vibram" }],
      ["Sepatu Harian HTZL City Ride",    "Sepatu",      1_150_000, "boots",    { "Bahan" => "Suede + kanvas", "Protektor" => "Ankle padding", "Gaya" => "Sneaker riding", "Sol" => "Karet gum" }],
      ["Sepatu Adventure HTZL Terra",     "Sepatu",      4_300_000, "boots",    { "Bahan" => "Kulit + poliuretan", "Protektor" => "Buckle aluminium 4 titik", "Tinggi" => "Mid-calf", "Sol" => "Enduro block" }],
      ["Celana Riding HTZL Kevlar Jeans", "Celana",      1_680_000, "pants",    { "Bahan" => "Denim 13 oz + aramid", "Protektor" => "CE Level 1 lutut & pinggul", "Abrasi" => "4,2 detik AA", "Ukuran" => "28 sampai 40" }],
      ["Celana Touring HTZL Storm Pant",  "Celana",      2_150_000, "pants",    { "Bahan" => "Cordura 500D", "Cuaca" => "Waterproof + thermal liner", "Protektor" => "CE Level 1", "Ventilasi" => "Zip paha" }],
      ["Celana Balap HTZL Leather Trk",   "Celana",      3_900_000, "pants",    { "Bahan" => "Kulit sapi 1,3 mm", "Protektor" => "CE Level 2 + knee slider", "Fitur" => "Panel stretch aksordion", "Zipper" => "Sambung ke jaket" }],
      ["Body Protector HTZL Shell Vest",  "Protektor",   1_450_000, "protector",{ "Cakupan" => "Dada, punggung, bahu", "Sertifikasi" => "CE Level 2", "Bahan" => "Poliuretan ventilasi", "Berat" => "980 g" }],
      ["Back Protector HTZL Spine L2",    "Protektor",     980_000, "protector",{ "Cakupan" => "Tulang belakang penuh", "Sertifikasi" => "CE Level 2", "Bahan" => "Memory foam", "Fitur" => "Sabuk pinggang elastis" }],
      ["Knee Protector HTZL Guard K2",    "Protektor",     540_000, "protector",{ "Cakupan" => "Lutut & tulang kering", "Sertifikasi" => "CE Level 1", "Bahan" => "TPU + EVA", "Pengikat" => "Dua strap velcro" }],
      ["Balaclava HTZL Coolmax",          "Aksesori Diri", 165_000, "mask",     { "Bahan" => "Coolmax breathable", "Fitur" => "Anti-bau, cepat kering", "Ukuran" => "All size", "Isi" => "2 pcs" }],
      ["Masker Riding HTZL Filter N95",   "Aksesori Diri", 210_000, "mask",     { "Filter" => "N95 lima lapis", "Fitur" => "Katup buang udara", "Isi" => "1 masker + 5 filter", "Ukuran" => "M dan L" }]
    ].freeze

    PARTS = [
      ["Knalpot Slip-on HTZL SC Titan",   "Knalpot",     6_800_000, "exhaust",  { "Bahan" => "Titanium grade 2", "Bobot" => "Turun 2,4 kg", "Suara" => "98 dB", "Kompatibel" => "Sport 1.000-1.400 cc" }],
      ["Knalpot Full System HTZL RaceLine", "Knalpot",  14_500_000, "exhaust",  { "Bahan" => "Titanium + end cap karbon", "Gain" => "+7,5 hp", "Bobot" => "Turun 5,1 kg", "Catatan" => "Khusus sirkuit" }],
      ["Knalpot Slip-on HTZL Carbon Pro", "Knalpot",     8_900_000, "exhaust",  { "Bahan" => "Serat karbon", "Bobot" => "Turun 3,0 kg", "Suara" => "101 dB", "Fitur" => "DB killer lepas-pasang" }],
      ["Header Pipe HTZL Stainless 2-1",  "Knalpot",     4_200_000, "exhaust",  { "Bahan" => "Stainless 304", "Diameter" => "51 mm", "Gain" => "+3,2 hp", "Finishing" => "Heat-treated" }],
      ["DB Killer HTZL Silent Insert",    "Knalpot",       450_000, "exhaust",  { "Bahan" => "Stainless", "Reduksi" => "-8 dB", "Pasang" => "Baut tunggal", "Kompatibel" => "Slip-on HTZL" }],
      ["Ban Depan HTZL Sport 120/70-17",  "Ban",         1_650_000, "tire",     { "Ukuran" => "120/70 ZR17", "Kompon" => "Dual compound", "Pola" => "Sport touring", "Indeks" => "58W" }],
      ["Ban Belakang HTZL Sport 190/55-17", "Ban",       2_450_000, "tire",     { "Ukuran" => "190/55 ZR17", "Kompon" => "Dual compound", "Pola" => "Sport touring", "Indeks" => "75W" }],
      ["Ban Depan HTZL Track 120/70-17",  "Ban",         2_100_000, "tire",     { "Ukuran" => "120/70 ZR17", "Kompon" => "Soft racing", "Pola" => "Slick beralur", "Catatan" => "Butuh tyre warmer" }],
      ["Ban Belakang HTZL Track 200/55-17", "Ban",       3_150_000, "tire",     { "Ukuran" => "200/55 ZR17", "Kompon" => "Soft racing", "Pola" => "Slick beralur", "Catatan" => "Khusus sirkuit" }],
      ["Ban Adventure HTZL Terra 150/70-17", "Ban",      2_050_000, "tire",     { "Ukuran" => "150/70 R17", "Rasio" => "50 aspal / 50 tanah", "Konstruksi" => "Radial", "Indeks" => "69V" }],
      ["Ban Hujan HTZL Aqua 180/55-17",   "Ban",         2_300_000, "tire",     { "Ukuran" => "180/55 ZR17", "Kompon" => "Wet racing", "Alur" => "Buang air 32 l/detik", "Indeks" => "73W" }],
      ["Kampas Rem Depan HTZL Sinter HH", "Rem",           720_000, "brake",    { "Material" => "Sintered HH", "Suhu Kerja" => "sampai 700 C", "Isi" => "Sepasang (2 kaliper)", "Kompatibel" => "Brembo M4/M50" }],
      ["Kampas Rem Belakang HTZL Sinter", "Rem",           380_000, "brake",    { "Material" => "Sintered", "Suhu Kerja" => "sampai 600 C", "Isi" => "1 set", "Kompatibel" => "Kaliper 1 piston" }],
      ["Kampas Rem Organik HTZL Street",  "Rem",           295_000, "brake",    { "Material" => "Organik", "Karakter" => "Senyap, minim debu", "Isi" => "1 set", "Pemakaian" => "Harian" }],
      ["Master Rem Radial HTZL RCS19",    "Rem",         5_400_000, "brake",    { "Tipe" => "Radial 19 mm", "Fitur" => "Rasio bisa disetel", "Bahan" => "Aluminium CNC", "Selang" => "Braided ikut" }],
      ["Cakram Depan HTZL Float 330mm",   "Rem",         3_850_000, "disc",     { "Diameter" => "330 mm", "Tipe" => "Floating dua bagian", "Bahan" => "Stainless + carrier aluminium", "Isi" => "1 pcs" }],
      ["Cakram Belakang HTZL 245mm",      "Rem",         1_250_000, "disc",     { "Diameter" => "245 mm", "Tipe" => "Fixed", "Bahan" => "Stainless 420", "Isi" => "1 pcs" }],
      ["Selang Rem Braided HTZL Steel",   "Rem",           980_000, "brake",    { "Bahan" => "Teflon + jalinan baja", "Panjang" => "Custom per model", "Fitting" => "Aluminium anodize", "Isi" => "Set depan" }],
      ["Rantai HTZL X-Ring 525",          "Rantai & Gir",  1_150_000, "chain",  { "Tipe" => "X-Ring", "Ukuran" => "525", "Sambungan" => "120 mata", "Beban Putus" => "4.100 kgf" }],
      ["Gir Depan HTZL Steel 15T",        "Rantai & Gir",    285_000, "chain",  { "Bahan" => "Baja karbon", "Mata Gigi" => "15T", "Ukuran" => "525", "Finishing" => "Nikel" }],
      ["Gir Belakang HTZL Alloy 45T",     "Rantai & Gir",    690_000, "chain",  { "Bahan" => "Aluminium 7075", "Mata Gigi" => "45T", "Ukuran" => "525", "Bobot" => "480 g" }],
      ["Filter Udara HTZL Flow K&N",      "Filter",          890_000, "filter", { "Tipe" => "Cotton gauze", "Umur" => "Cuci ulang, 80.000 km", "Gain" => "+2,1 hp", "Isi" => "1 pcs" }],
      ["Filter Oli HTZL Spin-on",         "Filter",          145_000, "filter", { "Tipe" => "Spin-on", "Filtrasi" => "20 mikron", "Bypass" => "Katup 1,0 bar", "Isi" => "1 pcs" }],
      ["Filter Bensin HTZL Inline",       "Filter",          210_000, "filter", { "Tipe" => "Inline", "Filtrasi" => "10 mikron", "Bahan" => "Aluminium", "Isi" => "1 pcs" }],
      ["Filter Udara HTZL Foam Enduro",   "Filter",          320_000, "filter", { "Tipe" => "Foam dua lapis", "Pemakaian" => "Off-road berdebu", "Umur" => "Cuci ulang", "Isi" => "2 pcs" }],
      ["Busi Iridium HTZL Spark IX",      "Pengapian",       165_000, "spark",  { "Elektroda" => "Iridium 0,6 mm", "Umur" => "40.000 km", "Isi" => "1 pcs", "Gap" => "0,8 mm" }],
      ["Coil Pengapian HTZL HotSpark",    "Pengapian",       850_000, "spark",  { "Output" => "45 kV", "Bahan" => "Epoxy tahan panas", "Isi" => "1 pcs", "Kompatibel" => "Mesin 2 dan 4 silinder" }],
      ["Shock Belakang HTZL Ohlins TTX",  "Suspensi",     12_800_000, "suspension", { "Tipe" => "Twin tube TTX36", "Setelan" => "Preload, rebound, compression", "Per" => "Bisa ganti rate", "Reservoir" => "Piggyback" }],
      ["Cartridge Depan HTZL NIX30",      "Suspensi",     14_200_000, "suspension", { "Tipe" => "Cartridge kit", "Diameter" => "30 mm piston", "Setelan" => "Compression & rebound terpisah", "Isi" => "Sepasang" }],
      ["Steering Damper HTZL Stabil SD",  "Suspensi",      4_600_000, "suspension", { "Tipe" => "Rotary", "Setelan" => "18 klik", "Bahan" => "Aluminium CNC", "Bracket" => "Model spesifik" }]
    ].freeze

    OILS = [
      ["Oli Mesin HTZL Racing 10W-40 Full Sintetik", "Oli Mesin", 285_000, "oil", { "Viskositas" => "10W-40", "Standar" => "JASO MA2, API SN", "Isi" => "1 liter", "Interval" => "6.000 km" }],
      ["Oli Mesin HTZL Street 15W-50 Semi Sintetik", "Oli Mesin", 165_000, "oil", { "Viskositas" => "15W-50", "Standar" => "JASO MA2, API SL", "Isi" => "1 liter", "Interval" => "4.000 km" }],
      ["Oli Mesin HTZL Track 5W-40 Ester",     "Oli Mesin", 425_000, "oil", { "Viskositas" => "5W-40", "Basis" => "Ester racing", "Isi" => "1 liter", "Interval" => "2.500 km" }],
      ["Paket Oli Mesin HTZL Racing 4 Liter",  "Oli Mesin", 1_050_000, "oil", { "Viskositas" => "10W-40", "Isi" => "4 liter", "Bonus" => "Filter oli", "Hemat" => "Rp 190.000" }],
      ["Oli Gardan HTZL Gear 80W-90",          "Oli Mesin", 95_000, "oil",  { "Viskositas" => "80W-90", "Standar" => "API GL-5", "Isi" => "120 ml", "Interval" => "10.000 km" }],
      ["Minyak Rem HTZL DOT 4 Racing",         "Cairan",   135_000, "fluid", { "Spesifikasi" => "DOT 4", "Titik Didih" => "310 C kering", "Isi" => "500 ml", "Interval" => "2 tahun" }],
      ["Minyak Rem HTZL DOT 5.1",              "Cairan",   175_000, "fluid", { "Spesifikasi" => "DOT 5.1", "Titik Didih" => "270 C basah", "Isi" => "500 ml", "Catatan" => "Aman untuk ABS" }],
      ["Coolant HTZL Cool Blue Siap Pakai",    "Cairan",    95_000, "fluid", { "Tipe" => "Ethylene glycol pra-campur", "Proteksi" => "-15 C sampai 129 C", "Isi" => "1 liter", "Interval" => "2 tahun" }],
      ["Coolant HTZL Track Waterless",         "Cairan",   320_000, "fluid", { "Tipe" => "Waterless", "Proteksi" => "Titik didih 180 C", "Isi" => "1 liter", "Catatan" => "Nol korosi" }],
      ["Chain Lube HTZL Wax Dry",              "Perawatan", 125_000, "lube", { "Tipe" => "Wax kering", "Cocok" => "O/X-ring", "Isi" => "400 ml", "Kelebihan" => "Tidak menarik debu" }],
      ["Chain Cleaner HTZL Degreaser",         "Perawatan",  98_000, "lube", { "Tipe" => "Pelarut cepat kering", "Cocok" => "Semua rantai", "Isi" => "500 ml", "Bonus" => "Sikat 3 sisi" }],
      ["Poles Bodi HTZL Gloss Ceramic",        "Perawatan", 245_000, "polish", { "Tipe" => "Sealant keramik", "Daya Tahan" => "6 bulan", "Isi" => "250 ml", "Aplikasi" => "Lap aplikator ikut" }],
      ["Pembersih Helm HTZL Visor Clean",      "Perawatan",  75_000, "polish", { "Tipe" => "Busa anti-kabut", "Aman" => "Untuk visor berlapis", "Isi" => "200 ml", "Bonus" => "Microfiber" }],
      ["Shampo Motor HTZL Foam Wash",          "Perawatan",  88_000, "polish", { "Tipe" => "pH netral", "Busa" => "Cocok snow foam", "Isi" => "1 liter", "Takaran" => "1:100" }]
    ].freeze

    ACCESSORIES = [
      ["Top Box HTZL Trunk 45L",          "Bagasi",     3_200_000, "topbox",   { "Kapasitas" => "45 liter", "Bahan" => "Poliuretan cetak", "Muat" => "Dua helm full face", "Kunci" => "Satu kunci dengan motor" }],
      ["Side Pannier HTZL Alu 35L Set",   "Bagasi",     7_800_000, "topbox",   { "Kapasitas" => "35 liter per sisi", "Bahan" => "Aluminium 1,5 mm", "Kunci" => "Silinder anti-bor", "Isi" => "Sepasang + bracket" }],
      ["Tank Bag HTZL Magnet 18L",        "Bagasi",     1_450_000, "topbox",   { "Kapasitas" => "18 liter, bisa mengembang", "Pemasangan" => "Magnet + strap", "Fitur" => "Jendela peta, rain cover", "Bahan" => "Cordura 1680D" }],
      ["Tail Bag HTZL Roll 25L",          "Bagasi",       890_000, "topbox",   { "Kapasitas" => "25 liter", "Tipe" => "Roll-top waterproof", "Pemasangan" => "Empat strap", "Bahan" => "Tarpaulin TPU" }],
      ["Windshield HTZL Touring Tinggi",  "Pelindung",  1_950_000, "windshield", { "Bahan" => "Akrilik 4 mm", "Tinggi" => "+120 mm dari standar", "Setelan" => "Tiga posisi", "Efek" => "Turbulensi berkurang" }],
      ["Windshield HTZL Sport Bubble",    "Pelindung",  1_150_000, "windshield", { "Bahan" => "Polikarbonat 3 mm", "Model" => "Double bubble", "Warna" => "Smoke gelap", "Efek" => "Aerodinamis tunduk" }],
      ["Crash Bar HTZL Engine Guard",     "Pelindung",  2_650_000, "crashbar", { "Bahan" => "Pipa baja 25 mm", "Finishing" => "Powder coat hitam", "Proteksi" => "Blok mesin & radiator", "Isi" => "Sepasang" }],
      ["Frame Slider HTZL Impact",        "Pelindung",    950_000, "crashbar", { "Bahan" => "Delrin + baut baja", "Proteksi" => "Rangka & fairing", "Pemasangan" => "Baut mesin bawaan", "Isi" => "Sepasang" }],
      ["Handguard HTZL Storm",            "Pelindung",    780_000, "handguard", { "Bahan" => "Aluminium + plastik", "Proteksi" => "Angin, hujan, benturan", "Pemasangan" => "Bar-end + clamp", "Isi" => "Sepasang" }],
      ["Radiator Guard HTZL Mesh",        "Pelindung",    620_000, "crashbar", { "Bahan" => "Aluminium laser cut", "Fungsi" => "Tahan kerikil", "Aliran Udara" => "Turun kurang dari 3 persen", "Isi" => "1 pcs" }],
      ["USB Charger HTZL Power 30W",      "Elektronik",   350_000, "usb",      { "Output" => "USB-C 30W PD + USB-A 18W", "Tahan Air" => "IP67", "Pemasangan" => "Stang atau dashboard", "Proteksi" => "Cut-off tegangan rendah" }],
      ["Phone Holder HTZL Lock Grip",     "Elektronik",   425_000, "phone",    { "Ukuran HP" => "4,7 sampai 7 inci", "Peredam" => "Anti-getar bola karet", "Pemasangan" => "Stang 22-32 mm", "Kunci" => "Latch pengaman" }],
      ["Action Cam Mount HTZL Rig",       "Elektronik",   295_000, "phone",    { "Kompatibel" => "GoPro dan sejenis", "Titik Pasang" => "Helm, stang, spion", "Bahan" => "Aluminium + karet", "Isi" => "3 adaptor" }],
      ["Cover Motor HTZL Shield Outdoor", "Perlindungan", 465_000, "cover",    { "Bahan" => "Poliester 210D lapis PU", "Cuaca" => "Anti-UV & anti-air", "Ukuran" => "L dan XL", "Fitur" => "Lubang kunci gembok" }],
      ["Gembok Cakram HTZL Alarm 110dB",  "Perlindungan", 585_000, "cover",    { "Alarm" => "110 dB, sensor getar", "Pin" => "Diameter 7 mm", "Baterai" => "CR2 tahan 1 tahun", "Bonus" => "Kabel pengingat" }]
    ].freeze

    SERVICES = [
      ["Servis Berkala 4.000 km",     "Servis Rutin",   450_000, "wrench", { "Durasi" => "90 menit", "Cakupan" => "Ganti oli, cek 32 titik", "Garansi" => "30 hari", "Suku Cadang" => "Oli HTZL Street" }],
      ["Servis Berkala 12.000 km",    "Servis Rutin",   950_000, "wrench", { "Durasi" => "3 jam", "Cakupan" => "Oli, filter, busi, sinkronisasi throttle", "Garansi" => "30 hari", "Suku Cadang" => "Termasuk" }],
      ["Servis Besar 24.000 km",      "Servis Rutin", 2_450_000, "wrench", { "Durasi" => "6 jam", "Cakupan" => "Setel klep, ganti coolant, rantai keteng", "Garansi" => "60 hari", "Booking" => "Wajib janji temu" }],
      ["Ganti Oli Ekspres",           "Servis Rutin",   185_000, "wrench", { "Durasi" => "30 menit", "Cakupan" => "Oli + filter, jasa saja", "Antre" => "Tanpa janji temu", "Catatan" => "Oli beli terpisah" }],
      ["Tune-up Performa Dyno",       "Performa",     1_850_000, "dyno",   { "Durasi" => "4 jam", "Cakupan" => "3 run dyno + laporan grafik", "Hasil" => "Peta AFR optimal", "Garansi" => "Cek ulang 1x gratis" }],
      ["Remap ECU Stage 1",           "Performa",     3_400_000, "dyno",   { "Durasi" => "5 jam", "Gain" => "+8 sampai 12 hp", "Cakupan" => "Flash ECU + validasi dyno", "Catatan" => "Knalpot aftermarket disarankan" }],
      ["Balancing & Spooring Roda",   "Kaki-kaki",      325_000, "wheel",  { "Durasi" => "60 menit", "Cakupan" => "Dua roda + cek run-out", "Alat" => "Balancer statis presisi", "Garansi" => "14 hari" }],
      ["Pasang Ban (Sepasang)",       "Kaki-kaki",      285_000, "wheel",  { "Durasi" => "75 menit", "Cakupan" => "Bongkar, pasang, balancing", "Catatan" => "Ban beli terpisah", "Bonus" => "Cek tekanan gratis" }],
      ["Setel Suspensi Sesuai Bobot", "Kaki-kaki",      650_000, "wheel",  { "Durasi" => "2 jam", "Cakupan" => "Sag depan-belakang, damping", "Hasil" => "Lembar setelan tertulis", "Garansi" => "Revisi 1x gratis" }],
      ["Detailing Keramik Full Body", "Perawatan",    1_650_000, "polish", { "Durasi" => "8 jam", "Cakupan" => "Dekontaminasi, poles, coating", "Daya Tahan" => "12 bulan", "Garansi" => "Cuci ulang gratis 1x" }]
    ].freeze

    BADGES = ["Terlaris", "Baru", "Stok Terbatas", nil, nil, nil].freeze

    class << self
      # Bangun seluruh katalog. Mengembalikan array hash siap dump ke YAML.
      def build
        rng = Random.new(SEED)
        items = []
        items.concat(build_bikes(rng))
        items.concat(build_simple(APPAREL,     "apparel",  "HTZL Apparel", rng))
        items.concat(build_simple(PARTS,       "part",     "HTZL Performance", rng))
        items.concat(build_simple(OILS,        "oli",      "HTZL Lubricants", rng))
        items.concat(build_simple(ACCESSORIES, "aksesori", "HTZL Touring", rng))
        items.concat(build_simple(SERVICES,    "layanan",  "HTZL Service Center", rng))
        items.concat(build_heritage(rng))
        items.each_with_index { |item, i| item["sku"] = format("HTZ-%s-%03d", item["category"][0, 3].upcase, i + 1) }
        items
      end

      # Ubah angka jadi format rupiah Indonesia: 45000000 -> "Rp 45.000.000"
      def rupiah(value)
        return "-" if value.nil?

        digits = value.to_i.abs.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
        "#{value.to_i.negative? ? '-' : ''}Rp #{digits}"
      end

      # Ubah teks bebas jadi slug URL-safe: "Kawasaki x56 SP" -> "kawasaki-x56-sp"
      def slugify(text)
        text.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
      end

      # Ringkas hash spesifikasi jadi satu baris untuk kartu produk.
      def spec_summary(specs, limit = 3)
        return "" if specs.nil? || specs.empty?

        specs.to_a.first(limit).map { |k, v| "#{k}: #{v}" }.join(" | ")
      end

      # Artwork hasil lib/generate_art.rb. Nil bila berkasnya belum dibuat,
      # sehingga kartu jatuh kembali memakai ikon kategori.
      def art_path(slug)
        rel = "/assets/img/products/#{slug}.svg"
        File.exist?(File.expand_path("../..#{rel}", __dir__)) ? rel : nil
      end

      # Kredit foto hasil lib/fetch_heritage_photos.py, diindeks per slug.
      # Berkas ini boleh belum ada: unit tanpa foto akan memakai ikon kategori.
      def photo_credits
        @photo_credits ||=
          begin
            path = File.expand_path("../../_data/photo_credits.yml", __dir__)
            rows = File.exist?(path) ? (YAML.load_file(path) || []) : []
            rows.each_with_object({}) { |row, acc| acc[row["slug"]] = row }
          end
      end

      # Rentang harga dipakai untuk filter cepat di sisi klien.
      def price_band(price)
        case price
        when 0...500_000              then "under-500k"
        when 500_000...2_000_000      then "500k-2jt"
        when 2_000_000...10_000_000   then "2jt-10jt"
        when 10_000_000...50_000_000  then "10jt-50jt"
        when 50_000_000...500_000_000 then "50jt-500jt"
        else "di-atas-500jt"
        end
      end

      # Statistik ringkas untuk ditampilkan di halaman katalog.
      def stats(items)
        by_category = Hash.new(0)
        items.each { |i| by_category[i["category"]] += 1 }
        prices = items.map { |i| i["price"] }
        {
          "total"      => items.length,
          "categories" => by_category,
          "min_price"  => prices.min,
          "max_price"  => prices.max
        }
      end

      private

      def build_bikes(rng)
        BIKES.flat_map do |bike|
          TRIMS.map do |trim|
            name  = "#{bike[:name]}#{trim[:suffix]}"
            price = ((bike[:price] * trim[:mult]) / 500_000.0).round * 500_000
            hp    = bike[:hp] + trim[:hp_add]
            discount = rng.rand(100) < 22
            {
              "name"           => name,
              "slug"           => slugify(name),
              "category"       => "motor",
              "category_label" => CATEGORIES["motor"][:label],
              "subcategory"    => bike[:type],
              "brand"          => bike[:brand],
              "price"          => price,
              "price_old"      => discount ? (price * 1.12 / 500_000.0).round * 500_000 : nil,
              "price_band"     => price_band(price),
              "badge"          => discount ? "Diskon" : BADGES[rng.rand(BADGES.length)],
              "stock"          => rng.rand(1..9),
              "rating"         => (4.2 + rng.rand(8) / 10.0).round(1),
              "image"          => "/assets/img/bikes/#{bike[:image]}.webp",
              "icon"           => "motorcycle",
              "blurb_type"     => "bike",
              "trim"           => trim[:label],
              "cc"             => bike[:cc],
              "blurb"          => "#{bike[:type]} #{bike[:cc]} cc. #{trim[:note]}",
              "specs"          => {
                "Mesin"          => "#{format_thousand(bike[:cc])} cc",
                "Tenaga"         => "#{hp} hp",
                "Torsi"          => "#{bike[:nm]} Nm",
                "Tinggi Jok"     => "#{bike[:seat]} mm",
                "Trim"           => trim[:label],
                "Pilihan Warna"  => COLORS.first(3 + rng.rand(3)).join(", ")
              }
            }
          end
        end
      end

      # Koleksi Harley-Davidson, diurutkan dari unit tertua. Foto diambil dari
      # Wikimedia Commons oleh lib/fetch_photos.rb; unit tanpa foto berlisensi
      # bebas memakai artwork yang dibuat lib/generate_art.rb.
      def build_heritage(rng)
        HTZL::Heritage::UNITS.map do |year, name, era, cc, hp, frame, rarity, price, query|
          full_name = "Harley-Davidson #{year} #{name}"
          slug = slugify(full_name)
          sub = HTZL::Heritage.subcategory(era)
          credit = photo_credits[slug]
          {
            "name"           => full_name,
            "slug"           => slug,
            "category"       => "heritage",
            "category_label" => CATEGORIES["heritage"][:label],
            "subcategory"    => sub,
            "brand"          => "Harley-Davidson",
            "price"          => price,
            "price_old"      => nil,
            "price_band"     => price_band(price),
            "badge"          => rarity == "Museum" || rarity == "Ikonik" ? "Koleksi Langka" : BADGES[rng.rand(BADGES.length)],
            "stock"          => rarity == "Museum" ? 1 : rng.rand(1..3),
            "rating"         => (4.5 + rng.rand(6) / 10.0).round(1),
            "image"          => (credit && credit["file"]) || art_path(slug),
            "credit"         => credit && credit.reject { |k, _| %w[slug file].include?(k) },
            "icon"           => "heritage",
            "blurb_type"     => "generic",
            "trim"           => nil,
            "cc"             => cc,
            "year"           => year,
            "photo_query"    => query,
            "blurb"          => "#{sub}. #{full_name} bermesin #{format_thousand(cc)} cc.",
            "specs"          => {
              "Tahun"       => year.to_s,
              "Mesin"       => "#{format_thousand(cc)} cc",
              "Tenaga"      => "#{hp} hp",
              "Tipe"        => era,
              "Rangka"      => frame,
              "Kelangkaan"  => rarity
            }
          }
        end
      end

      def build_simple(rows, category, brand, rng)
        rows.map do |name, subcategory, price, icon, specs|
          discount = rng.rand(100) < 25
          slug = slugify(name)
          {
            "name"           => name,
            "slug"           => slug,
            "category"       => category,
            "category_label" => CATEGORIES[category][:label],
            "subcategory"    => subcategory,
            "brand"          => brand,
            "price"          => price,
            "price_old"      => discount ? (price * 1.18 / 5_000.0).round * 5_000 : nil,
            "price_band"     => price_band(price),
            "badge"          => discount ? "Diskon" : BADGES[rng.rand(BADGES.length)],
            "stock"          => category == "layanan" ? 99 : rng.rand(3..40),
            "rating"         => (4.1 + rng.rand(9) / 10.0).round(1),
            "image"          => art_path(slug),
            "icon"           => icon,
            "blurb_type"     => "generic",
            "trim"           => nil,
            "cc"             => nil,
            "blurb"          => "#{subcategory} resmi HTZL. #{spec_summary(specs, 2)}.",
            "specs"          => specs
          }
        end
      end

      def format_thousand(value)
        value.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
      end
    end
  end
end
