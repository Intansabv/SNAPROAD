import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/preview_screen.dart';
import '../widgets/common.dart';

/// Ambil/pilih satu foto lalu buka layar pratinjau.
/// Satu foto per proses deteksi (sesuai SKPL).
Future<void> startDetection(BuildContext context, ImageSource source) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600, // cukup untuk model 224px, hemat memori & penyimpanan
      imageQuality: 90,
    );
    if (picked == null) return;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PreviewScreen(imagePath: picked.path, source: source),
      ),
    );
  } catch (_) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Kamera tidak dapat dibuka.'
                : 'Galeri tidak dapat dibuka.',
          ),
        ),
      );
  }
}

/// Dipakai tombol "Mulai Deteksi": tanya sumber foto dulu.
Future<void> startDetectionWithChooser(BuildContext context) async {
  final source = await showSourceSheet(context);
  if (source == null || !context.mounted) return;
  await startDetection(context, source);
}
