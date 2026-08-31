# Pemberitahuan Lisensi Pihak Ketiga

Repositori ini memakai beberapa aset yang tidak dilindungi lisensi MIT proyek.
Berkas ini merinci asal dan status lisensinya.

> Lisensi MIT di [LICENSE](LICENSE) berlaku untuk **kode** dalam repositori ini:
> seluruh berkas Ruby, CSS, JavaScript, templat Liquid, konfigurasi, dan test.
> Lisensi itu **tidak** berlaku untuk aset pihak ketiga (font dan gambar), yang
> dirinci di bawah.

## Ringkasan

| Komponen | Lisensi | Berlaku untuk |
|---|---|---|
| Kode proyek (Ruby, CSS, JS, Liquid, test) | MIT — lihat [LICENSE](LICENSE) | Seluruh berkas buatan sendiri |
| Font Arvo | SIL Open Font License 1.1 | `assets/fonts/arvo-700.woff2` |
| Ikon SVG | MIT (bagian dari proyek) | `_includes/icons.html` |
| Foto koleksi heritage | Domain publik / CC BY / CC BY-SA | `assets/img/heritage/**` |
| Artwork produk | MIT (bagian dari proyek) | `assets/img/products/**` |
| Gambar warisan tugas 2021 | Hak pemilik masing-masing | `assets/img/{bikes,gallery,hero,news}/**` |
| Nama merek | Milik pemegang merek | Teks di seluruh situs |

---

## 1. Kode proyek — MIT

Semua kode yang ditulis untuk proyek ini berlisensi MIT:

- `lib/**/*.rb` — generator katalog, filter, konfigurasi bahasa
- `_plugins/**/*.rb` — adapter Jekyll
- `test/**/*.rb` — test suite Minitest
- `assets/css/site.css`, `assets/js/*.js`
- `_layouts/**`, `_includes/**` (kecuali aset yang disebut di bawah)
- `Rakefile`, `Gemfile`, `_config.yml`, berkas alur kerja GitHub Actions

Bebas dipakai ulang, dimodifikasi, dan didistribusikan sesuai syarat MIT.

## 2. Font Arvo — SIL Open Font License 1.1

- **Berkas:** `assets/fonts/arvo-700.woff2`
- **Perancang:** Anton Koovit
- **Sumber:** [Google Fonts](https://fonts.google.com/specimen/Arvo)
- **Lisensi:** [SIL Open Font License 1.1](https://scripts.sil.org/OFL)

OFL mengizinkan penggunaan, penyalinan, penggabungan, dan distribusi ulang,
termasuk untuk keperluan komersial, selama font tidak dijual secara terpisah
dan berkas turunan tidak memakai nama font aslinya. Font di-host sendiri agar
situs tidak mengirim permintaan ke server pihak ketiga.

## 3. Ikon SVG — MIT

Seluruh ikon di `_includes/icons.html` digambar tangan untuk proyek ini dan
tercakup lisensi MIT proyek. Ikon merek dagang (WhatsApp, Instagram, Facebook,
X) merupakan penggambaran ulang sederhana yang dipakai hanya sebagai penunjuk
tautan; logo dan merek tersebut tetap milik pemiliknya masing-masing.

Ikon-ikon ini menggantikan tiga berkas PNG berukuran total 428 KB pada versi
2021 situs ini.

## 4. Gambar

Gambar di repositori ini berasal dari tiga sumber dengan status berbeda.

### 4a. Foto koleksi heritage — Wikimedia Commons (69 berkas)

Berkas di `assets/img/heritage/**` diambil dari Wikimedia Commons oleh
`lib/fetch_heritage_photos.py`, yang **hanya menerima lisensi bebas**: domain
publik, CC0, CC BY, dan CC BY-SA. Berkas berlisensi non-komersial atau tanpa
turunan ditolak otomatis.

| Lisensi | Jumlah |
|---|--:|
| CC BY-SA 4.0 | 48 |
| CC BY 2.0 | 7 |
| Public domain | 5 |
| CC BY-SA 3.0 | 5 |
| CC BY-SA 2.0 | 2 |
| CC BY 4.0 | 1 |
| CC BY-SA 2.0 de | 1 |

Foto-foto ini **tetap berada di bawah lisensinya masing-masing**, bukan lisensi
MIT proyek. Lisensi CC BY dan CC BY-SA mensyaratkan atribusi, dan itu dipenuhi
di dua tempat: di halaman detail tiap produk pada situs, dan pada daftar di
bawah. Data mentahnya ada di `_data/photo_credits.yml`.

Foto **tidak diberi watermark**. Menempelkan watermark pada karya orang lain
tidak menghapus hak cipta, berisiko dianggap mengklaim karya tersebut, dan
menutupi informasi kepemilikan merupakan pelanggaran tersendiri.

<details>
<summary>Daftar lengkap atribusi 69 foto</summary>

| Berkas | Pembuat | Lisensi | Sumber |
|---|---|---|---|
| Harley-Davidson Museum December 2023 39 (c. 1903 'Serial N | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_39_(c._1903_%27Serial_Number_One%27--Atmospheric-Valve_Single).jpg) |
| Four Lithuanian riflemen in uniforms and policemen behind. | unknown | [Public domain](https://commons.wikimedia.org/) | [sumber](https://commons.wikimedia.org/wiki/File:Four_Lithuanian_riflemen_in_uniforms_and_policemen_behind._Ignas_%C5%BDiniauskas_behind_the_steering_wheel,_1939.jpg) |
| 1911HarleyDavidson"SilentGrayFellow".jpg | DrReload | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:1911HarleyDavidson%22SilentGrayFellow%22.jpg) |
| Harley-Davidson Museum December 2023 45 (1907 Model 3--Atm | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_45_(1907_Model_3--Atmospheric-Valve_Single).jpg) |
| August Chelini on "Harley-Davison" motorcycle, Race at Tan | The San Francisco call | [Public domain](https://commons.wikimedia.org/) | [sumber](https://commons.wikimedia.org/wiki/File:August_Chelini_on_%22Harley-Davison%22_motorcycle,_Race_at_Tanforan_racetrack,_JULY_4,_1908.jpg) |
| Harley-Davidson Museum December 2023 01 (1911 Model 7-A--A | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_01_(1911_Model_7-A--Atmospheric-Valve_Single_and_1909_Model_5-D--Atmospheric-Valve_V-Twin).jpg) |
| Harley-Davidson Museum December 2023 01 (1911 Model 7-A--A | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_01_(1911_Model_7-A--Atmospheric-Valve_Single_and_1909_Model_5-D--Atmospheric-Valve_V-Twin).jpg) |
| Harley-Davidson Museum December 2023 05 (1912 Model X-8-A- | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_05_(1912_Model_X-8-A--Atmospheric-Valve_Single).jpg) |
| Harley-Davidson Museum December 2023 06 (1913 Model 9-E--F | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_06_(1913_Model_9-E--F-Head_V-Twin).jpg) |
| Harley-Davidson US Mail side-car (circa 1914).jpg | Ed Bierman | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_US_Mail_side-car_(circa_1914).jpg) |
| Harley-Davidson Museum December 2023 07 (1915 Model 11-J-- | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_07_(1915_Model_11-J--F-Head_V-Twin).jpg) |
| Harley-Davidson Museum December 2023 53 (1916 Model J with | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_53_(1916_Model_J_with_Package_Truck--F-Head_V-Twin).jpg) |
| Harley Davidson Modell J, 1917.jpg | Zweiradmuseum Neckarsulm | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley_Davidson_Modell_J,_1917.jpg) |
| Motor Vehicles - In Use - Harley Davidson motorcycles, som | Unknown authorUnknown author or not prov | [Public domain](https://commons.wikimedia.org/) | [sumber](https://commons.wikimedia.org/wiki/File:Motor_Vehicles_-_In_Use_-_Harley_Davidson_motorcycles,_some_with_side_cars_on_the_road_manufactured_by_the_Harley_Davidson_Co.,_Milwaukee,_Wis._For_the_War_Department_-_NARA_-_45504463.jpg) |
| 1919 Harley-Davidson Model W Sport Twin (1) - The Art of t | Daniel Hartwig from New Haven, CT, USA | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | [sumber](https://commons.wikimedia.org/wiki/File:1919_Harley-Davidson_Model_W_Sport_Twin_(1)_-_The_Art_of_the_Motorcycle_-_Memphis.jpg) |
| Harley-Davidson Museum December 2023 13 (1920 Sport Model- | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_13_(1920_Sport_Model--Opposed_Twin).jpg) |
| Harley-Davidson Sport 558 cc 1921.jpg | Lars-Göran Lindgren Sweden | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Sport_558_cc_1921.jpg) |
| Jimmy Murphy, winner of 500-mile auto race at Indianapolis | Miscellaneous Items in High Demand, PPOC | [Public domain](https://commons.wikimedia.org/) | [sumber](https://commons.wikimedia.org/wiki/File:Jimmy_Murphy,_winner_of_500-mile_auto_race_at_Indianapolis,_Ind.,_May_30,_1922,_and_Ernie_Olson,_mechanic,_seated_on_Harley-Davidson_motorcycle_and_in_sidecar_LCCN2003671078.jpg) |
| Harley-Davidson Museum December 2023 10 (1923 Model JDCA-- | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_10_(1923_Model_JDCA--F-Head_V-Twin).jpg) |
| Harley-Davidson Museum April 2024 08 (Mama Tried- Bringing | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_April_2024_08_(Mama_Tried-_Bringing_it_Together--1929_FHAC_with_1924_FLXI_side_car).jpg) |
| Harley-Davidson Museum December 2023 49 (1925 JDCB--F-Head | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_49_(1925_JDCB--F-Head_V-Twin).jpg) |
| Harley-Davidson Pearshooter 1926.jpg | Lars-Göran Lindgren Sweden | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Pearshooter_1926.jpg) |
| Harley-Davidson Museum February 2024 40 (Clubs and Competi | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_February_2024_40_(Clubs_and_Competition--1927_Model_S_%27Peashooter%27--OHV_Single).jpg) |
| Harley-Davidson Museum December 2023 51 (1932 Model G Serv | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_51_(1932_Model_G_Servi-Car--Side-Valve_V-Twin).jpg) |
| Harley-Davidson Museum December 2023 19 (1933 VLD with 193 | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_19_(1933_VLD_with_1934_LT_Sidecar--Side-Valve_V-Twin).jpg) |
| Harley-Davidson Museum December 2023 20 (1935 Model R--Sid | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_20_(1935_Model_R--Side-Valve_V-Twin).jpg) |
| Harley-Davidson Museum December 2023 22 (1937 UH--Side-Val | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_22_(1937_UH--Side-Valve_V-Twin).jpg) |
| Harley-Davidson Museum December 2023 25 (1938 WLD--Side-Va | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_25_(1938_WLD--Side-Valve_V-Twin).jpg) |
| Harley-Davidson Museum December 2023 59 (1942 WLA--Side-Va | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_59_(1942_WLA--Side-Valve_V-Twin).jpg) |
| Harley-Davidson Museum December 2023 32 (1942 XA--Opposed  | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_December_2023_32_(1942_XA--Opposed_Twin).jpg) |
| 1942 Harley Davidson WLC Custom (6401211421).jpg | Tony Hisgett from Birmingham, UK | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | [sumber](https://commons.wikimedia.org/wiki/File:1942_Harley_Davidson_WLC_Custom_(6401211421).jpg) |
| 1946 Harley Knucklehead bobber (6842571943).jpg | Dave_S. from Witney, England | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | [sumber](https://commons.wikimedia.org/wiki/File:1946_Harley_Knucklehead_bobber_(6842571943).jpg) |
| Harley-Davidson-WL.jpg | Liftarn | [CC BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0/) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson-WL.jpg) |
| Harley-Davidson Museum February 2024 12 (Engine Room--Panh | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_February_2024_12_(Engine_Room--Panhead,_1948-65).jpg) |
| Harley-Davidson Museum April 2024 27 (1949 FL Hydra-Glide- | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_April_2024_27_(1949_FL_Hydra-Glide--OHV_V-Twin).jpg) |
| Harley Davidson 1200 Panhead 1950 (14130218107).jpg | order_242 from Chile | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley_Davidson_1200_Panhead_1950_(14130218107).jpg) |
| Harley-Davidson Museum May 2024 05 (Challenge and Opportun | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_May_2024_05_(Challenge_and_Opportunity--1957_XL_Sportster--OHV_V-Twin).jpg) |
| Harley-Davidson Museum February 2024 23 (Engine Room--Iron | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_February_2024_23_(Engine_Room--Ironhead_Sportster,_1957-85).jpg) |
| 1958 Harley Davidson Duo Glide - Haynes International Moto | Glen Bowman from Newcastle, England | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | [sumber](https://commons.wikimedia.org/wiki/File:1958_Harley_Davidson_Duo_Glide_-_Haynes_International_Motor_Museum_-_Sparkford,_Yeovil,_Somerset_(9649535456).jpg) |
| Harley-Davidson XLCH Sportster 1969.jpg | Dick Thompson | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_XLCH_Sportster_1969.jpg) |
| Harley-Davidson Museum May 2024 13 (The AMF Years--1960 Mo | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_May_2024_13_(The_AMF_Years--1960_Model_A_Topper--Horizontal_Two-Cycle_Single).jpg) |
| Harley-Davidson Museum February 2024 20 (Engine Room--Spri | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_February_2024_20_(Engine_Room--Sprint,_1961-72).jpg) |
| Harley063.jpg | Jean-Luc 2005 at German Wikipedia | [CC BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0/) | [sumber](https://commons.wikimedia.org/wiki/File:Harley063.jpg) |
| Harley-Davidson Museum April 2024 38 (1971 GE Servi-Car Po | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_April_2024_38_(1971_GE_Servi-Car_Police--Side-Valve_V-Twin).jpg) |
| Harley-Davidson Museum February 2024 13 (Engine Room--Shov | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_February_2024_13_(Engine_Room--Shovelhead,_1966-84).jpg) |
| Harley-Davidson Museum April 2024 26 (1971 FX Super Glide- | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_April_2024_26_(1971_FX_Super_Glide--OHV_V-Twin).jpg) |
| Harley-Davidson Museum April 2024 41 (1976 FLH-1200 Libert | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_April_2024_41_(1976_FLH-1200_Liberty_Edition--OHV_V-Twin).jpg) |
| Harley-Davidson Museum April 2024 36 (1977 XLCR-1000 Cafe  | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_April_2024_36_(1977_XLCR-1000_Cafe_Racer--OHV_V-Twin).jpg) |
| Harley-Davidson Museum April 2024 42 (1977 FXS Low Rider-- | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_April_2024_42_(1977_FXS_Low_Rider--OHV_V-Twin).jpg) |
| Harley-Davidson Road Glide (MSP15).JPG | Jakub "Flyz1" Maciejewski | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Road_Glide_(MSP15).JPG) |
| Harley-Davidson Museum April 2024 43 (1980 FXWG Wide Glide | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_April_2024_43_(1980_FXWG_Wide_Glide--OHV_V-Twin).jpg) |
| Fxstc1998.jpg | Wikimedia Commons | [Public domain](https://commons.wikimedia.org/) | [sumber](https://commons.wikimedia.org/wiki/File:Fxstc1998.jpg) |
| Harley-Davidson Softail Breakout FXSB103, Motor (2015-08-2 | Lothar Spurzem | [CC BY-SA 2.0 de](https://creativecommons.org/licenses/by-sa/2.0/de/deed.en) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Softail_Breakout_FXSB103,_Motor_(2015-08-25_Sp).jpg) |
| Harley-Davidson Museum May 2024 18 (1993 FLSTN Heritage So | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_May_2024_18_(1993_FLSTN_Heritage_Softail_Nostalgia--OHV_V-Twin).jpg) |
| Harley-Davidson 883 Sportster red.jpg | Addvisor | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_883_Sportster_red.jpg) |
| 1989 Harley Davidson Softail Springer.jpg | bluescast | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | [sumber](https://commons.wikimedia.org/wiki/File:1989_Harley_Davidson_Softail_Springer.jpg) |
| Harley Davidson Electra Glide Ultra Classic.jpg | LKM13 | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley_Davidson_Electra_Glide_Ultra_Classic.jpg) |
| Harley-Davidson Museum May 2024 17 (1990 FLSTF Fat Boy--OH | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_May_2024_17_(1990_FLSTF_Fat_Boy--OHV_V-Twin).jpg) |
| Harley-Davidson Museum May 2024 18 (1993 FLSTN Heritage So | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_May_2024_18_(1993_FLSTN_Heritage_Softail_Nostalgia--OHV_V-Twin).jpg) |
| Harley-Davidson Museum May 2024 22 (2001 FLHRCI Road King  | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_May_2024_22_(2001_FLHRCI_Road_King_Classic--OHV_V-Twin).jpg) |
| Harley-Davidson Electra Glide dashboard.jpg | Tobias "ToMar" Maier | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Electra_Glide_dashboard.jpg) |
| Harley-Davidson FXDWG Dyna Wide Glide used in ABUDEKA IS B | Tokumeigakarinoaoshima | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_FXDWG_Dyna_Wide_Glide_used_in_ABUDEKA_IS_BACK_and_Nissan_LEOPARD_Ultima_V30_TWINCAM_TURBO_(E-UF31)_ver.Minato_302.jpg) |
| Harley-Davidson Museum May 2024 21 (1997 FLSTS Heritage Sp | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_May_2024_21_(1997_FLSTS_Heritage_Springer--OHV_V-Twin).jpg) |
| Harley-Davidson Museum May 2024 20 (1998 FLTRI Road Glide- | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_May_2024_20_(1998_FLTRI_Road_Glide--OHV_V-Twin).jpg) |
| Harley-Davidson Museum February 2024 15 (Engine Room--Twin | Michael Barera | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_Museum_February_2024_15_(Engine_Room--Twin_Cam,_1999-2017).jpg) |
| Harley-Davidson V-Rod front-right Porsche Museum.jpg | Morio | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) | [sumber](https://commons.wikimedia.org/wiki/File:Harley-Davidson_V-Rod_front-right_Porsche_Museum.jpg) |
| Ms-vrscr.jpg | Von Mitch | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:Ms-vrscr.jpg) |
| 2008 Harley-Davidson Rocker in Athens on 11-14-2023.jpg | George E. Koronaios | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | [sumber](https://commons.wikimedia.org/wiki/File:2008_Harley-Davidson_Rocker_in_Athens_on_11-14-2023.jpg) |
| 2014 Harley-Davidson Street 750 front.jpg | Ryan Urlacher from USA | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | [sumber](https://commons.wikimedia.org/wiki/File:2014_Harley-Davidson_Street_750_front.jpg) |

</details>

### 4b. Artwork produk — MIT (bagian dari proyek)

Berkas di `assets/img/products/**` adalah SVG yang digambar program oleh
`lib/generate_art.rb`. Seluruhnya karya asli proyek ini dan tercakup lisensi
MIT.

### 4c. Gambar warisan tugas 2021 — hak pemilik masing-masing

Berkas di `assets/img/bikes/**`, `assets/img/gallery/**`, `assets/img/hero/**`,
dan `assets/img/news/**` berasal dari tugas kuliah tahun 2021. Gambar aslinya
diunduh dari sumber publik dan **hak ciptanya tetap milik pemegang aslinya**,
antara lain Ducati Media House, Wikimedia Commons, GOMA Brisbane, Robb Report,
Speedcafe, Bike Review, Gridoto, dan Otosia.

Gambar-gambar tersebut dipakai **hanya sebagai contoh visual dalam proyek
portofolio non-komersial**. Repositori ini tidak mengklaim kepemilikan atasnya
dan tidak memberikan lisensi apa pun untuk penggunaan ulang. Jika Anda memakai
ulang kode proyek ini, ganti berkas-berkas tersebut dengan gambar milik Anda
sendiri.

## 5. Nama merek

"Kawasaki" adalah merek terdaftar milik Kawasaki Heavy Industries, Ltd.
"Harley-Davidson" adalah merek terdaftar milik H-D U.S.A., LLC.
Nama-nama merek dan model lain yang muncul di situs ini adalah milik pemegang
merek masing-masing.

**HTZL Motorcycle Club adalah perusahaan fiktif.** Situs ini dibuat sebagai
karya portofolio dan latihan pengembangan web. Tidak ada hubungan, afiliasi,
sponsor, atau dukungan apa pun dengan produsen sepeda motor mana pun. Seluruh
harga, spesifikasi, stok, dan berita di situs ini adalah data contoh yang
dibuat oleh program (`lib/htzl/catalog.rb`), bukan penawaran sungguhan.
