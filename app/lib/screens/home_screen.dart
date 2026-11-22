import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/detection.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/photo_flow.dart';
import '../widgets/common.dart';
import 'history_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenHistory});

  final VoidCallback onOpenHistory;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DetectionRecord> _recent = const [];

  @override
  void initState() {
    super.initState();
    AppServices.db.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppServices.db.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await AppServices.db.all(limit: 3);
    if (!mounted) return;
    setState(() => _recent = rows);
  }

  @override
  Widget build(BuildContext context) {
    final modelReady = AppServices.classifier.isReady;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cyan),
                ),
                child: const Icon(Icons.add_road, color: AppColors.cyan),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SNAPROAD',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              InfoPill(
                text: modelReady ? 'SIAP DIGUNAKAN' : 'MODEL BELUM ADA',
                icon: modelReady ? Icons.check_circle : Icons.error_outline,
                color: modelReady ? AppColors.green : AppColors.orange,
                background: modelReady ? AppColors.greenSoft : AppColors.orangeSoft,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Deteksi Kerusakan\nJalan',
            style: TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analisis kondisi jalan dengan AI',
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 20),
          if (!modelReady) ...[
            GlassCard(
              color: AppColors.orangeSoft,
              borderColor: AppColors.orange,
              child: Text(
                'Model belum terpasang.\n'
                '${AppServices.classifier.loadError ?? ''}\n\n'
                'Letakkan snaproad_mobilenetv2_fp16.tflite di assets/model/ '
                'lalu jalankan ulang aplikasi (stop, lalu flutter run).',
                style: const TextStyle(height: 1.4, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('ANALISIS DI PERANGKAT'),
                const SizedBox(height: 8),
                const Text(
                  'Satu foto. Analisis di perangkat.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Foto diproses langsung di ponsel Anda, tanpa unggahan ke cloud.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Mulai Deteksi',
                  icon: Icons.document_scanner_outlined,
                  onPressed: () => startDetectionWithChooser(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Akses cepat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickAction(
                icon: Icons.photo_camera_outlined,
                label: 'Kamera',
                onTap: () => startDetection(context, ImageSource.camera),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.photo_library_outlined,
                label: 'Galeri',
                onTap: () => startDetection(context, ImageSource.gallery),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.history,
                label: 'Riwayat',
                onTap: widget.onOpenHistory,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Deteksi Terakhir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (_recent.isNotEmpty)
                TextButton(
                  onPressed: widget.onOpenHistory,
                  child: const Text('Lihat semua'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recent.isEmpty)
            const GlassCard(
              child: EmptyState(
                icon: Icons.image_search_outlined,
                title: 'Belum ada hasil deteksi',
                message: 'Mulai dari satu foto.',
              ),
            )
          else
            for (final r in _recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DetectionTile(record: r),
              ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppColors.cyan, size: 28),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu baris riwayat (dipakai di Beranda dan Riwayat).
class DetectionTile extends StatelessWidget {
  const DetectionTile({super.key, required this.record});

  final DetectionRecord record;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HistoryDetailScreen(record: record),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              LocalPhoto(
                path: record.imagePath,
                width: 72,
                height: 72,
                cacheWidth: 216,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SeverityChip(record.severity),
                    const SizedBox(height: 8),
                    Text(
                      '${Fmt.percent(record.confidence)} confidence  /  '
                      '${Fmt.date(record.createdAt)}, ${Fmt.time(record.createdAt)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (record.hasLocation)
                const Icon(Icons.place_outlined, color: AppColors.cyan, size: 20),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
