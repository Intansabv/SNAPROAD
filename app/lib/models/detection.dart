import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tiga tingkat kerusakan. Urutan enum HARUS sama dengan labels.txt
/// dari notebook: ringan, sedang, berat.
enum Severity {
  ringan(
    key: 'ringan',
    label: 'Ringan',
    action: 'Pemeliharaan rutin',
    description: 'Retak halus atau permukaan mulai aus; belum mengganggu berkendara.',
    color: AppColors.green,
    soft: AppColors.greenSoft,
    icon: Icons.check_circle_outline,
  ),
  sedang(
    key: 'sedang',
    label: 'Sedang',
    action: 'Dijadwalkan perbaikan',
    description: 'Retak lebar atau lubang dangkal; berpotensi membesar.',
    color: AppColors.amber,
    soft: AppColors.amberSoft,
    icon: Icons.warning_amber_rounded,
  ),
  berat(
    key: 'berat',
    label: 'Berat',
    action: 'Prioritas tinggi',
    description: 'Lubang dalam, amblas, atau pengelupasan luas; membahayakan.',
    color: AppColors.red,
    soft: AppColors.redSoft,
    icon: Icons.error_outline,
  );

  const Severity({
    required this.key,
    required this.label,
    required this.action,
    required this.description,
    required this.color,
    required this.soft,
    required this.icon,
  });

  final String key;
  final String label;
  final String action;
  final String description;
  final Color color;
  final Color soft;
  final IconData icon;

  static Severity? fromKey(String raw) {
    final k = raw.trim().toLowerCase();
    for (final s in Severity.values) {
      if (s.key == k) return s;
    }
    return null;
  }
}

/// Hasil satu kali inferensi model.
class ClassificationResult {
  const ClassificationResult({
    required this.scores,
    required this.inferenceMs,
  });

  /// Probabilitas tiap kelas (jumlah ~1.0).
  final Map<Severity, double> scores;
  final int inferenceMs;

  /// Di bawah ambang ini, aplikasi menganggap hasil "belum yakin".
  static const double minConfidence = 0.50;

  Severity get top =>
      scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

  double get confidence => scores[top] ?? 0;

  bool get isConfident => confidence >= minConfidence;
}

/// Satu baris riwayat deteksi yang tersimpan di SQLite.
class DetectionRecord {
  const DetectionRecord({
    this.id,
    required this.imagePath,
    required this.severity,
    required this.confidence,
    required this.scores,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.accuracy,
  });

  final int? id;
  final String imagePath;
  final Severity severity;
  final double confidence;
  final Map<Severity, double> scores;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final double? accuracy;

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'image_path': imagePath,
        'severity': severity.key,
        'confidence': confidence,
        'scores': jsonEncode({
          for (final e in scores.entries) e.key.key: e.value,
        }),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory DetectionRecord.fromMap(Map<String, Object?> m) {
    final raw = jsonDecode(m['scores'] as String) as Map<String, dynamic>;
    final scores = <Severity, double>{};
    raw.forEach((k, v) {
      final s = Severity.fromKey(k);
      if (s != null) scores[s] = (v as num).toDouble();
    });
    return DetectionRecord(
      id: m['id'] as int?,
      imagePath: m['image_path'] as String,
      severity: Severity.fromKey(m['severity'] as String) ?? Severity.ringan,
      confidence: (m['confidence'] as num).toDouble(),
      scores: scores,
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      accuracy: (m['accuracy'] as num?)?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }
}
