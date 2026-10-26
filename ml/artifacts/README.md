Folder ini menyimpan hasil Colab (`snaproad_model.zip` diekstrak di sini):

- `snaproad_mobilenetv2_fp16.tflite` — model utama aplikasi (± 4,8 MB)
- `snaproad_mobilenetv2_int8.tflite` — pembanding kuantisasi (± 2,9 MB)
- `labels.txt` — urutan kelas: ringan, sedang, berat
- `model_meta.json` — kontrak input/preprocessing + metrik
- `metrics.json`, `confusion_matrix.png`, `training_curves.png`, `class_distribution.png` — bahan laporan

File `.zip` dan dataset mentah tidak di-commit (lihat `.gitignore`).
