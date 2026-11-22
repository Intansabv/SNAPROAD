# SNAPROAD — Aplikasi Flutter Klasifikasi Kerusakan Jalan

Aplikasi Android (Flutter) untuk Tugas Pemrograman Bergerak. Pengguna mengambil/memilih **satu foto jalan**, model **MobileNetV2 (TensorFlow Lite)** dari notebook `SNAPROAD.ipynb` menaksir tingkat keparahan **Ringan / Sedang / Berat** langsung di HP (offline), lalu hasilnya bisa disimpan ke riwayat lokal beserta koordinat GPS (opsional).

UI mengikuti desain Figma `SNAPROAD.fig` (navy + cyan, Material 3).

## Langkah menjalankan di OPPO A6 (HP fisik)

### 1. Siapkan HP
1. Pengaturan → Tentang perangkat → Versi → ketuk **Nomor build** 7 kali.
2. Pengaturan → Pengaturan tambahan → **Opsi pengembang** → aktifkan **USB debugging**.
3. Sambungkan HP ke laptop dengan kabel data. Di HP pilih mode **Transfer file**, lalu izinkan *"Allow USB debugging"* untuk komputer ini.
   (Di ColorOS, jika `flutter run` gagal memasang aplikasi, aktifkan juga **Install via USB** di Opsi pengembang.)

### 2. Siapkan laptop
Pasang Flutter SDK + Android Studio (Android SDK), lalu cek:
```bash
flutter doctor
flutter devices      # OPPO A6 harus muncul di daftar
```

### 3. Buat kerangka proyek lalu salin berkas ini
Jalankan di folder **tanpa spasi** pada path-nya:
```bash
flutter create --org id.ac.upgrismadiun --platforms=android snaproad
```
Lalu **salin dan timpa** ke dalam folder `snaproad` yang baru dibuat:
`lib/`, `assets/`, `test/`, dan `pubspec.yaml` dari zip ini.

### 4. Dua pengaturan Android (wajib)
**a. `android/app/build.gradle.kts`** (atau `build.gradle` di Flutter lama) — set minSdk 26 (Android 8.0, sesuai SKPL):
```kotlin
minSdk = 26            // Groovy: minSdkVersion 26
```
**b. `android/app/src/main/AndroidManifest.xml`** — tambahkan izin lokasi di dalam `<manifest>` (di atas `<application>`), dan ganti label aplikasi:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
...
<application android:label="SNAPROAD" ...>
```
(Izin kamera tidak perlu: foto diambil lewat aplikasi kamera bawaan HP.)

### 5. Pasang model hasil notebook
1. Jalankan `SNAPROAD.ipynb` di Google Colab (GPU T4) sampai sel terakhir; unduh hasilnya.
2. Salin **`snaproad_mobilenetv2_fp16.tflite`** ke folder `assets/model/` (`labels.txt` sudah ada; isinya harus tetap `ringan, sedang, berat`).
3. Tanpa berkas model, aplikasi tetap terbuka tetapi menampilkan *"Model belum terpasang"* dan analisis akan gagal.

### 6. Jalankan
```bash
flutter pub get
flutter run            # pilih OPPO A6 jika ditanya
```
Setiap menambah/mengganti berkas di `assets/`, hentikan aplikasi lalu `flutter run` lagi (hot reload tidak memuat aset baru).

APK untuk dibagikan: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.

## Alur aplikasi
Splash → Onboarding (sekali) → **Beranda** (Mulai Deteksi / Kamera / Galeri / Deteksi terakhir) → **Preview** (opsi lokasi) → **Analisis** → **Hasil** (severity, confidence, probabilitas, tindak lanjut) → Simpan ke **Riwayat** (filter, detail, hapus) · **Tentang**.

Jika confidence tertinggi < 50 %, hasil ditampilkan sebagai *"Kerusakan Tidak Terdeteksi"* beserta tips foto (ambang diatur di `ClassificationResult.minConfidence`, `lib/models/detection.dart`).

## Struktur kode
```
lib/
  main.dart
  theme/app_theme.dart            warna & tema dari design system Figma
  models/detection.dart           Severity, ClassificationResult, DetectionRecord
  services/classifier_service.dart  load .tflite, preprocessing (isolate), inferensi
  services/database_service.dart    SQLite (sqflite) + salinan foto
  services/location_service.dart    GPS opsional (geolocator)
  screens/                        splash, onboarding, shell, home, preview,
                                  analyzing, result, history, history_detail, about
  widgets/common.dart             komponen UI bersama
assets/model/                     .tflite + labels.txt
test/widget_test.dart             unit test logika (flutter test)
```

Kontrak model (harus sama dengan notebook): input `[1,224,224,3]` float32 nilai 0–255 (normalisasi sudah di dalam model), output `[1,3]` softmax urut `ringan, sedang, berat`. Varian `int8` (input uint8) juga dikenali otomatis.

## Kesesuaian dengan SKPL
| FR | Status |
|---|---|
| FR-01 Beranda, FR-02 kamera/galeri, FR-03 pratinjau | ✅ |
| FR-06 estimasi keparahan, FR-07 confidence | ✅ |
| FR-08 GPS (izin pengguna), FR-10 simpan riwayat, FR-11 detail, FR-12 hapus | ✅ |
| FR-04 deteksi objek + bounding box, FR-05 jenis kerusakan (D00/D10/D20/D40) | ⚠️ belum — butuh model YOLO (lihat bawah) |
| FR-09 panel petugas | ➖ di luar cakupan (SKPL revisi: aplikasi tidak mengirim laporan) |

## Catatan penting / keterbatasan
- **Model notebook adalah *classifier*, bukan detektor YOLO.** Ia dilatih pada *crop* area kerusakan, jadi hasil terbaik didapat bila foto diambil dekat dan memenuhi area retak/lubang. Foto jalan lebar bisa kurang akurat, dan model tidak punya kelas "jalan mulus" (karena itu ada ambang confidence).
- Bounding box & jenis kerusakan (sesuai SKPL/Figma) membutuhkan model deteksi YOLO yang diekspor ke TFLite; itu bisa ditambahkan sebagai pengembangan lanjutan tanpa mengubah UI/riwayat.
- Dataset RDD2022ES berlisensi CC BY-NC-SA 4.0 (non-komersial) — cukup untuk keperluan kuliah.
- Hasil hanyalah estimasi berbasis gambar, bukan penilaian teknis resmi.
- Kode ditulis tanpa dapat dikompilasi di lingkungan penyusun; jika `flutter pub get`/`flutter run` menampilkan error versi paket, jalankan `flutter pub upgrade` lalu kirim pesan error-nya.
