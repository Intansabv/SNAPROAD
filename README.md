# SNAPROAD

**Implementasi Klasifikasi Tingkat Kerusakan Jalan pada Aplikasi Pelaporan Berbasis Flutter menggunakan MobileNetV2 dan TensorFlow Lite**

| | |
|---|---|
| Nama | Putri Intan Abdillah Fattah |
| NIM | 2305101108 |
| Kelas | Teknik Informatika 7D |
| Mata kuliah | Pemrograman Bergerak |
| Institusi | Universitas PGRI Madiun |

Dokumen spesifikasi kebutuhan (Tugas 1): [`Putri Intan Abdillah Fattah_2305101108_7D_TUGAS-1.pdf`](Putri%20Intan%20Abdillah%20Fattah_2305101108_7D_TUGAS-1.pdf)

---

## Ringkasan proyek

SNAPROAD adalah aplikasi pelaporan jalan rusak. Warga memotret kerusakan, aplikasi membaca koordinat GPS, lalu model **MobileNetV2** yang sudah dikonversi ke **TensorFlow Lite** mengklasifikasikan foto ke tiga tingkat kerusakan — **ringan, sedang, berat** — langsung di perangkat (on-device, tanpa internet). Hasil klasifikasi beserta foto dan lokasi disimpan sebagai laporan yang bisa dipantau statusnya.

| Bagian | Teknologi |
|---|---|
| Aplikasi | Flutter / Dart, target Android |
| Model | MobileNetV2 (transfer learning ImageNet) → TensorFlow Lite |
| Pelatihan | Python, TensorFlow/Keras, Google Colab (GPU T4) |
| Dataset | RDD2022ES (turunan RDD2022), 3 kelas hasil pemetaan |
| Perangkat | Kamera, GPS (`geolocator`), peta |

## Struktur repositori

```
SNAPROAD/
├── README.md                  # halaman ini
├── docs/
│   └── ROADMAP.md             # rencana tahapan + rencana commit
├── ml/
│   ├── README.md              # panduan dataset & training
│   ├── notebooks/
│   │   └── SNAPROAD_MobileNetV2_TFLite.ipynb
│   └── artifacts/             # model .tflite, labels.txt, metrik (hasil Colab)
├── lib/                       # kode aplikasi Flutter (tahap berikutnya)
└── assets/models/             # model yang dipakai aplikasi
```

Dataset mentah **tidak** disimpan di repo (ukurannya > 2 GB). Model hasil training yang kecil tetap di-commit agar aplikasi bisa langsung dijalankan.

## Status pengerjaan

| Tahap | Status |
|---|---|
| Tugas 1 — Dokumen spesifikasi kebutuhan | ✅ selesai |
| Tugas 2 — Dataset + pelatihan model di Colab | 🚧 berjalan |
| Tugas 3 — Aplikasi Flutter (UI, kamera, GPS) | ⬜ belum |
| Tugas 4 — Integrasi TFLite on-device | ⬜ belum |
| Tugas 5 — Riwayat, peta, backend, notifikasi | ⬜ belum |
| Tugas 6 — Pengujian + laporan akhir | ⬜ belum |

Rincian tiap tahap, target, dan contoh pesan commit ada di [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Cara menjalankan

### 1. Melatih ulang model (opsional)

Buka `ml/notebooks/SNAPROAD_MobileNetV2_TFLite.ipynb` di Google Colab, aktifkan GPU T4, lalu **Run all**. Panduan lengkap: [`ml/README.md`](ml/README.md).

### 2. Menjalankan aplikasi

```bash
flutter pub get
flutter run -d <device-id>     # HP Android dengan USB debugging aktif
```

> Bagian ini diisi lengkap setelah proyek Flutter dibuat pada tahap berikutnya.

## Lisensi & atribusi dataset

- RDD2022: Arya, D., Maeda, H., Ghosh, S. K., Toshniwal, D., & Sekimoto, Y. (2022). *RDD2022: A multi-national image dataset for automatic road damage detection*. arXiv:2209.08538.
- RDD2022ES (pemetaan tingkat keparahan): Kaggle `juusos/rdd2022es`, lisensi **CC BY-NC-SA 4.0** — digunakan untuk keperluan akademik, bukan komersial.
- MobileNetV2: Sandler, M. dkk. (2018). *MobileNetV2: Inverted Residuals and Linear Bottlenecks*. CVPR.
