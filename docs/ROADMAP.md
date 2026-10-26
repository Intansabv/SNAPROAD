# ROADMAP SNAPROAD

Rencana pengerjaan bertahap. Setiap tahap punya **output yang bisa dicek** dan **contoh pesan commit**. Tujuannya agar riwayat commit di GitHub mencerminkan proses pengerjaan, bukan satu commit besar di akhir.

## Aturan commit

1. Satu commit = satu perubahan yang bisa dijelaskan dalam satu kalimat.
2. Format pesan: `tipe(area): ringkasan` — tipe: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
3. Commit dan push di akhir setiap langkah kecil (minimal 1× per hari kerja).
4. **Jangan pernah** commit: dataset mentah, `kaggle.json`, file `.env`, `build/`, `*.zip` hasil Colab.
5. Update tabel status di `README.md` setiap menyelesaikan satu tahap.

---

## Tahap 0 — Persiapan repo ✅

**Output:** repo rapi, `.gitignore` aman, roadmap ini.

- [x] Clone repo, susun struktur `docs/`, `ml/`, `assets/`
- [x] `.gitignore` untuk dataset, token, artefak build
- [x] README + roadmap

**Commit:**
```
docs: tambah roadmap pengerjaan dan struktur repo
chore: perketat gitignore untuk dataset dan kredensial
```

---

## Tahap 1 — Dataset & eksplorasi (Colab) 🚧

**Tujuan:** mendapatkan data 3 kelas yang bersih dan siap dilatih.

**Output:**
- Notebook `ml/notebooks/SNAPROAD_MobileNetV2_TFLite.ipynb` berjalan sampai sel EDA.
- Grafik distribusi kelas + contoh crop (untuk laporan).
- `manifest_crops.csv` (daftar crop + sumber gambar).

**Langkah:**
1. Siapkan token Kaggle (`kaggle.json`).
2. Jalankan sel 1–7 di notebook.
3. Catat di laporan: jumlah gambar asli, jumlah crop per kelas, rasio split.
4. Tulis alasan pemetaan 8 kelas RDD2022ES → 3 kelas aplikasi.

**Commit:**
```
feat(ml): tambah notebook unduh dataset dan pra-olah crop bbox
docs(ml): catat distribusi kelas dan contoh data
```

---

## Tahap 2 — Pelatihan MobileNetV2 🚧

**Tujuan:** model transfer learning terlatih dan tervalidasi.

**Output:**
- `training_curves.png`
- `metrics.json` (accuracy, macro F1)
- Model terbaik `best_model.keras`

**Target (dari dokumen spesifikasi):** akurasi ≥ 80%, macro F1 ≥ 0,75.

**Langkah:**
1. Tahap 1: latih kepala klasifikasi, base dibekukan (12 epoch).
2. Tahap 2: fine-tuning 40 layer terakhir (lr 1e-5).
3. Evaluasi pada test set + confusion matrix.
4. Jika target belum tercapai, lakukan perbaikan di notebook (lihat bagian akhir notebook), **bukan** menaikkan angka di laporan.

**Commit:**
```
feat(ml): latih MobileNetV2 dua tahap dengan class weight
docs(ml): tambah hasil evaluasi dan confusion matrix
```

---

## Tahap 3 — Ekspor & verifikasi TFLite 🚧

**Output:**
- `snaproad_mobilenetv2_fp16.tflite` (model utama, ±4,8 MB)
- `snaproad_mobilenetv2_int8.tflite` (pembanding, ±2,9 MB)
- `labels.txt`, `model_meta.json`
- Tabel perbandingan ukuran, akurasi, dan latensi untuk laporan

**Langkah:**
1. Jalankan sel konversi + verifikasi.
2. Unduh `snaproad_model.zip`, ekstrak ke `ml/artifacts/`.
3. Commit model (ukurannya kecil, aman untuk GitHub).

**Commit:**
```
feat(ml): ekspor model TFLite fp16 dan int8
docs(ml): catat perbandingan ukuran dan latensi model
```

---

## Tahap 4 — Scaffold aplikasi Flutter ⬜

**Tujuan:** aplikasi bisa dijalankan di HP fisik, tampilan dasar siap.

**Output:**
- `flutter create` di root repo, package `snaproad`
- Tema Material 3, 3 halaman: Beranda, Lapor (3 langkah), Riwayat
- Widget bersama (tombol, kartu status, indikator langkah)

**Langkah:**
1. `flutter doctor` → pastikan Android toolchain OK.
2. Aktifkan **Opsi Pengembang** + **USB debugging** di HP, sambungkan, `flutter devices`.
3. `flutter create --org id.snaproad --project-name snaproad .`
4. Susun `lib/` per fitur: `lib/features/home`, `lib/features/report`, `lib/features/history`, `lib/core`.
5. Jalankan `flutter run` di HP (bukan emulator) → screenshot untuk laporan.

**Commit:**
```
feat(app): scaffold proyek Flutter dan tema aplikasi
feat(app): tambah halaman beranda dan alur lapor 3 langkah
```

---

## Tahap 5 — Kamera & GPS ⬜

**Output:** foto dari kamera/galeri + koordinat GPS + alamat, dengan penanganan izin.

**Langkah:**
1. Paket: `image_picker` (atau `camera`), `geolocator`, `permission_handler`.
2. Minta izin eksplisit; tampilkan pesan jelas bila ditolak.
3. Tampilkan akurasi GPS (meter) dan tombol "perbarui lokasi".
4. Uji di HP: foto resolusi tinggi, mode pesawat (GPS tetap jalan), izin ditolak.

**Commit:**
```
feat(report): ambil foto dari kamera dan galeri
feat(report): baca koordinat GPS dan tampilkan akurasi
```

---

## Tahap 6 — Integrasi TFLite on-device ⬜

**Output:** hasil klasifikasi (kelas + skor keyakinan) muncul < 1 detik setelah foto diambil, bisa dikoreksi pengguna (NFR-06).

**Langkah:**
1. Salin `snaproad_mobilenetv2_fp16.tflite` + `labels.txt` ke `assets/models/`, daftarkan di `pubspec.yaml`.
2. Paket `tflite_flutter`.
3. Preprocessing **wajib sama** dengan notebook: resize 224×224, RGB, nilai piksel **0–255** (model menormalisasi sendiri). Jangan bagi 255.
4. Jalankan di isolate agar UI tidak tersendat; ukur waktu inferensi dan tampilkan di halaman hasil.
5. Uji dengan minimal 15 foto asli (5 per kelas) dan catat akurasi lapangan.

**Commit:**
```
feat(ml): tambahkan model TFLite ke aset aplikasi
feat(report): klasifikasi kerusakan on-device dengan tflite_flutter
perf(report): jalankan inferensi di isolate dan catat latensi
```

---

## Tahap 7 — Laporan, riwayat, dan status ⬜

**Output:** laporan tersimpan lokal, daftar riwayat, detail laporan dengan status (Menunggu / Diverifikasi / Dijadwalkan / Selesai).

**Langkah:**
1. Simpanan lokal: `sqflite` atau `hive` (pilih satu, jelaskan alasannya di laporan).
2. Model data: id, foto, lat, lng, alamat, kelas, keyakinan, keterangan, status, timestamp.
3. Halaman riwayat dengan filter status; halaman detail.
4. Antrean laporan offline lalu sinkron saat online (NFR-03).

**Commit:**
```
feat(history): simpan laporan lokal dan tampilkan riwayat
feat(history): halaman detail laporan dan status
feat(sync): antrean laporan offline dan sinkronisasi
```

---

## Tahap 8 — Peta sebaran ⬜

**Output:** titik laporan pada peta, bisa diketuk untuk melihat detail.

**Langkah:** `flutter_map` + OpenStreetMap (tanpa API key) **atau** `google_maps_flutter` (butuh API key). Untuk tugas, `flutter_map` lebih aman.

**Commit:**
```
feat(map): tampilkan sebaran laporan pada peta
```

---

## Tahap 9 — Backend (opsional, sesuai dokumen) ⬜

**Output:** login, data laporan tersinkron, foto tersimpan di cloud, panel petugas sederhana.

**Langkah:**
1. `firebase_auth` (email/Google), `cloud_firestore`, `firebase_storage`.
2. Struktur koleksi: `reports/{id}` + `users/{uid}`.
3. Aturan keamanan Firestore: pengguna hanya bisa menulis laporannya sendiri; petugas bisa membaca semua.
4. Panel petugas: daftar laporan + ubah status.

**Commit:**
```
feat(auth): login dan registrasi dengan Firebase Auth
feat(report): kirim laporan ke Firestore dan Storage
feat(officer): panel petugas untuk verifikasi dan ubah status
```

> Kalau waktu terbatas, tahap ini bisa dipangkas dan ditulis sebagai "pengembangan lanjutan" di laporan. Tahap 4–8 sudah memenuhi inti FR-01 s.d. FR-07.

---

## Tahap 10 — Notifikasi ⬜

**Output:** notifikasi ketika status laporan berubah (FR-08).

**Commit:**
```
feat(notification): notifikasi perubahan status laporan
```

---

## Tahap 11 — Pengujian & rilis ⬜

**Output:**
- APK release (`flutter build apk --release --split-per-abi`)
- Tabel pengujian fungsional (FR-01…FR-09)
- Tabel latensi inferensi di HP (target < 1 detik)
- Rekap kuesioner SUS (target ≥ 68)
- Laporan akhir + video demo

**Commit:**
```
test: catat hasil pengujian fungsional di HP fisik
docs: tambah laporan pengujian dan panduan instalasi APK
chore(release): build APK release v1.0.0
```

---

## Ringkasan target keberhasilan

| Aspek | Target | Cara mengukur |
|---|---|---|
| Akurasi klasifikasi | ≥ 80% | `metrics.json` (test set) |
| Macro F1 | ≥ 0,75 | `metrics.json` |
| Ukuran model | ≤ 15 MB | ukuran file `.tflite` |
| Latensi inferensi | < 1 detik | stopwatch di aplikasi |
| Alur lapor | ≤ 3 langkah | uji kegunaan |
| SUS | ≥ 68 | kuesioner 10 pertanyaan |
