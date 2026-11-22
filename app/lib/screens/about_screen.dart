import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          const Text(
            'Tentang SNAPROAD',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cyan, width: 2),
                  ),
                  child: const Icon(Icons.add_road, size: 40, color: AppColors.cyan),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SNAPROAD',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Versi 1.0.0', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 10),
                const Text(
                  'Dibangun untuk dokumentasi jalan',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const GlassCard(
            child: Column(
              children: [
                _InfoRow(Icons.flutter_dash, 'Framework', 'Flutter · Material 3'),
                Divider(height: 24),
                _InfoRow(
                  Icons.memory,
                  'Model AI',
                  'MobileNetV2 · TensorFlow Lite (klasifikasi 3 tingkat)',
                ),
                Divider(height: 24),
                _InfoRow(Icons.phone_android, 'Pemrosesan', 'Lokal di perangkat'),
                Divider(height: 24),
                _InfoRow(Icons.school_outlined, 'Kampus', 'Universitas PGRI Madiun'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bullet('Deteksi offline setelah model tersedia.'),
                _Bullet('Tanpa login, akun, atau sinkronisasi cloud.'),
                _Bullet('Lokasi (GPS) bersifat opsional.'),
                _Bullet(
                  'Hasil deteksi merupakan estimasi berbasis gambar dan bukan '
                  'penilaian teknis resmi.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.title, this.value);

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cyan, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 16, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.muted, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
