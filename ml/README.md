# ML — Dataset, Pelatihan, dan Ekspor TFLite

Bagian ini menjelaskan cara menghasilkan model `snaproad_mobilenetv2_fp16.tflite` yang dipakai aplikasi Flutter.

## Ringkasan pipeline

```
Kaggle (RDD2022ES)
   │  unduh ±2,6 GB
   ▼
Foto jalan utuh + anotasi bbox (YOLO)
   │  crop tiap bbox + margin 20%, resize 224×224
   ▼
3 kelas: ringan / sedang / berat
   │  split per grup (anti-bocor), class weight
   ▼
MobileNetV2 transfer learning (2 tahap)
   │  evaluasi: accuracy, macro F1, confusion matrix
   ▼
TensorFlow Lite (fp16 untuk aplikasi, int8 untuk pembanding)
   │
   ▼
assets/models/ di aplikasi Flutter
```

Semua langkah dijalankan dari satu notebook: [`notebooks/SNAPROAD_MobileNetV2_TFLite.ipynb`](notebooks/SNAPROAD_MobileNetV2_TFLite.ipynb).

## Dataset

**RDD2022ES — Severity Extended RDD2022**
<https://www.kaggle.com/datasets/juusos/rdd2022es>

| Aspek | Keterangan |
|---|---|
| Basis | RDD2022 (Arya dkk., 2022), negara: Amerika, India, Jepang, Ceko |
| Jumlah | ± 25.000 gambar (separuhnya versi cermin) |
| Anotasi | kotak pembatas (YOLO), 8 kelas |
| Lisensi | CC BY-NC-SA 4.0 — akademik, bukan komersial |
| Ukuran unduhan | ± 2,6 GB |

Alasan memilih dataset ini: RDD2022 asli hanya membedakan **jenis** kerusakan (retak memanjang, retak melintang, retak kulit buaya, lubang). Dokumen spesifikasi membutuhkan **tingkat keparahan**, dan RDD2022ES sudah memperluas setiap jenis menjadi dua tingkat (normal vs parah), sehingga bisa dipetakan ke tiga kelas aplikasi.

### Pemetaan 8 kelas → 3 tingkat

| Kelas RDD2022ES | ID | → | Kelas aplikasi | Alasan |
|---|---|---|---|---|
| longitudinal crack | 0 | → | ringan | retak memanjang halus, belum mengganggu |
| transverse crack | 2 | → | ringan | retak melintang halus |
| longitudinal crack wide | 1 | → | sedang | retak melebar, berpotensi membesar |
| transverse crack wide | 3 | → | sedang | retak melebar |
| alligator crack | 4 | → | sedang | retak jaringan, belum amblas |
| pothole | 6 | → | sedang | lubang, belum dalam |
| alligator crack sunken | 5 | → | berat | retak jaringan + permukaan amblas |
| pothole deep | 7 | → | berat | lubang dalam, membahayakan |

> **Ini keputusan desain, bukan label bawaan dataset.** Tulis tabel ini di laporan (Bab 3) beserta alasannya, dan sebutkan sebagai batasan: pelabelan keparahan sepenuhnya mengikuti anotasi RDD2022ES, belum divalidasi oleh petugas Dinas PU.

## Menyiapkan token Kaggle

1. Masuk ke [kaggle.com](https://www.kaggle.com) → klik foto profil → **Settings**.
2. Bagian **API** → **Create New Token** → file `kaggle.json` terunduh.
3. Di Colab, saat notebook meminta, unggah file tersebut. Notebook menyimpannya di `~/.kaggle/kaggle.json`.

Token ini **rahasia**. Jangan pernah di-commit; `.gitignore` sudah mengecualikannya.

## Menjalankan notebook

1. Buka [Colab](https://colab.research.google.com) → **File → Upload notebook** → pilih file `.ipynb`.
2. **Runtime → Change runtime type → T4 GPU**.
3. **Runtime → Run all**.
4. Unggah `kaggle.json` saat diminta.
5. Tunggu ± 35–60 menit.

| Sel | Isi | Perkiraan waktu |
|---|---|---|
| 1–3 | cek lingkungan + unduh dataset | 3–8 menit |
| 4–5 | inspeksi struktur + pemetaan kelas | < 1 menit |
| 6 | crop bbox jadi dataset 3 kelas | 3–8 menit |
| 7–8 | EDA + pipeline `tf.data` | 1 menit |
| 9–11 | bangun model + training 2 tahap | 20–40 menit |
| 12–13 | evaluasi + grafik | 2 menit |
| 14–16 | konversi TFLite + verifikasi + unduh | 3–5 menit |

## Keluaran

Setelah **Run all**, `snaproad_model.zip` otomatis terunduh (juga disalin ke `MyDrive/SNAPROAD/` bila Drive di-mount).

| Berkas | Ukuran | Keterangan |
|---|---|---|
| `snaproad_mobilenetv2_fp16.tflite` | ± 4,8 MB | **dipakai aplikasi** |
| `snaproad_mobilenetv2_int8.tflite` | ± 2,9 MB | pembanding kuantisasi |
| `snaproad_mobilenetv2_fp32.tflite` | ± 9,5 MB | pembanding (tanpa kuantisasi) |
| `labels.txt` | — | urutan kelas: `ringan`, `sedang`, `berat` |
| `model_meta.json` | — | input, preprocessing, metrik, versi |
| `metrics.json` | — | accuracy, F1, laporan per kelas |
| `confusion_matrix.png` | — | untuk laporan |
| `training_curves.png` | — | untuk laporan |
| `class_distribution.png` | — | untuk laporan |

Ekstrak ke `ml/artifacts/`. Model `.tflite` **boleh di-commit** (ukurannya kecil); dataset dan `.zip` tidak.

## Kontrak preprocessing (penting untuk Flutter)

| Item | Nilai |
|---|---|
| Ukuran input | 224 × 224 × 3 (RGB) |
| Tipe data input | `float32` |
| Rentang nilai | **0–255** (JANGAN dibagi 255) |
| Normalisasi | dilakukan **di dalam model** (`Rescaling → [-1, 1]`) |
| Output | `float32[3]`, softmax, urutan `ringan, sedang, berat` |
| Model int8 | input `uint8` 0–255 (hanya untuk eksperimen) |

Kalau di Flutter hasil prediksi terasa acak, 90% penyebabnya adalah preprocessing yang tidak sama (mis. membagi 255 dua kali atau menukar urutan channel BGR).

## Catatan metodologi

1. **Anti-kebocoran data.** Crop dari satu foto tidak boleh muncul di train dan test sekaligus. Notebook mengelompokkan gambar dengan deskriptor 16×16 yang tahan pencerminan, lalu membagi grup (bukan file) ke train/val/test ± 70/15/15.
2. **Class weight** dipakai karena jumlah crop tiap kelas tidak seimbang.
3. **Batas crop per kelas** (3000 train) menjaga waktu training Colab. Untuk hasil lebih baik, naikkan ke 5000–6000.
4. **Split test tidak pernah dipakai** saat training maupun pemilihan model (model dipilih berdasarkan `val_accuracy`).

## Troubleshooting

| Gejala | Penyebab & solusi |
|---|---|
| `403 Forbidden` saat unduh | token salah/kadaluarsa → buat token baru di Kaggle Settings |
| `No such file: kaggle.json` | letakkan manual di `/content/kaggle.json`, jalankan ulang sel 3 |
| Training sangat lambat | GPU belum aktif → Runtime → Change runtime type → T4 GPU |
| `Bahkan waktu 12 jam habis` | turunkan `TRAIN_CAP_PER_CLASS` ke 1500, `BATCH_SIZE` 32 |
| Akurasi < 70% | cek distribusi kelas, naikkan data, periksa pemetaan label |
| Konversi INT8 gagal | tidak fatal; fp16 sudah cukup untuk aplikasi |
| Runtime restart di tengah jalan | unduh `manifest_crops.csv`, jalankan ulang; dataset perlu diunduh lagi |
