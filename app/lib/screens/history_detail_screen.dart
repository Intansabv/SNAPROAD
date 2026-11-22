import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/detection.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.record});

  final DetectionRecord record;

  Future<void> _confirmDelete(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 32),
        title: const Text('Hapus riwayat?'),
        content: const Text(
          'Data deteksi ini akan dihapus dari penyimpanan lokal.\n\n'
          'Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.navy,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await AppServices.db.delete(record);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Riwayat dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    final sev = record.severity;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Riwayat')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          children: [
            LocalPhoto(
              path: record.imagePath,
              height: 280,
              width: double.infinity,
              radius: 24,
              cacheWidth: 1080,
            ),
            const SizedBox(height: 16),
            GlassCard(
              borderColor: sev.color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SeverityChip(sev, large: true),
                      const Spacer(),
                      Text(
                        Fmt.percent(record.confidence),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: sev.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tindak lanjut: ${sev.action}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Probabilitas tiap kelas',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ScoreList(scores: record.scores, top: sev),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _Row(
                    icon: Icons.schedule,
                    text: Fmt.dateTime(record.createdAt),
                  ),
                  const Divider(height: 24),
                  if (record.hasLocation) ...[
                    _Row(
                      icon: Icons.place,
                      color: AppColors.green,
                      text: Fmt.coords(record.latitude!, record.longitude!),
                      trailing: IconButton(
                        tooltip: 'Salin koordinat',
                        icon: const Icon(Icons.copy, size: 18, color: AppColors.cyan),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: Fmt.coords(record.latitude!, record.longitude!),
                            ),
                          );
                          showSnack(context, 'Koordinat disalin');
                        },
                      ),
                    ),
                    if (record.accuracy != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 36, top: 2),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Akurasi ±${record.accuracy!.round()} m',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ] else
                    const _Row(
                      icon: Icons.location_off_outlined,
                      text: 'Lokasi tidak digunakan',
                      color: AppColors.muted,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SecondaryButton(
              label: 'Hapus Riwayat',
              icon: Icons.delete_outline,
              color: AppColors.red,
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.text,
    this.color = AppColors.cyan,
    this.trailing,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 16),
        Expanded(child: Text(text)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
