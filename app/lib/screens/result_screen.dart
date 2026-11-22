import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/detection.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/photo_flow.dart';
import '../widgets/common.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.source,
    required this.result,
    this.position,
  });

  final String imagePath;
  final ImageSource source;
  final ClassificationResult result;
  final Position? position;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final stored = await AppServices.db.persistImage(widget.imagePath);
      final r = widget.result;
      final pos = widget.position;
      await AppServices.db.insert(
        DetectionRecord(
          imagePath: stored,
          severity: r.top,
          confidence: r.confidence,
          scores: r.scores,
          createdAt: DateTime.now(),
          latitude: pos?.latitude,
          longitude: pos?.longitude,
          accuracy: pos?.accuracy,
        ),
      );
      if (!mounted) return;
      setState(() {
        _saved = true;
        _saving = false;
      });
      showSnack(context, 'Tersimpan di perangkat');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, 'Gagal menyimpan. Coba lagi.');
    }
  }

  void _backToStart() => Navigator.of(context).popUntil((r) => r.isFirst);

  void _retake(ImageSource source) {
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    startDetection(nav.context, source);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Deteksi')),
      body: SafeArea(
        child: result.isConfident ? _confident(result) : _uncertain(result),
      ),
    );
  }

  // ---------------------------------------------------------------- hasil yakin
  Widget _confident(ClassificationResult result) {
    final sev = result.top;
    final pos = widget.position;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      children: [
        LocalPhoto(
          path: widget.imagePath,
          height: 240,
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
              const SectionLabel('TINGKAT KEPARAHAN'),
              const SizedBox(height: 10),
              Row(
                children: [
                  SeverityChip(sev, large: true),
                  const Spacer(),
                  Text(
                    Fmt.percent(result.confidence),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: sev.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Confidence score',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                sev.description,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in_outlined,
                      size: 18, color: AppColors.cyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tindak lanjut: ${sev.action}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
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
              ScoreList(scores: result.scores, top: sev),
              const SizedBox(height: 4),
              Text(
                'Waktu inferensi: ${result.inferenceMs} ms',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(
            children: [
              Icon(
                pos != null ? Icons.place : Icons.location_off_outlined,
                color: pos != null ? AppColors.green : AppColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pos != null
                      ? Fmt.coords(pos.latitude, pos.longitude)
                      : 'Lokasi tidak digunakan',
                  style: TextStyle(
                    color: pos != null ? AppColors.text : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _Disclaimer(),
        const SizedBox(height: 20),
        PrimaryButton(
          label: _saved ? 'Tersimpan' : (_saving ? 'Menyimpan...' : 'Simpan ke Riwayat'),
          icon: _saved ? Icons.check : Icons.bookmark_add_outlined,
          onPressed: (_saved || _saving) ? null : _save,
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Deteksi Lagi',
          icon: Icons.refresh,
          onPressed: _backToStart,
        ),
      ],
    );
  }

  // -------------------------------------------------------------- hasil ragu
  Widget _uncertain(ClassificationResult result) {
    final best = result.top;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      children: [
        LocalPhoto(
          path: widget.imagePath,
          height: 200,
          width: double.infinity,
          radius: 24,
          cacheWidth: 1080,
        ),
        const SizedBox(height: 8),
        const EmptyState(
          icon: Icons.search_off,
          title: 'Kerusakan Tidak Terdeteksi',
          message:
              'Belum ditemukan objek kerusakan yang memenuhi ambang deteksi.',
        ),
        Center(
          child: Text(
            'Tebakan terbaik model: ${best.label} (${Fmt.percent(result.confidence)}), '
            'di bawah ambang ${Fmt.percent(ClassificationResult.minConfidence)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips foto lebih baik',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              _Tip('Permukaan jalan terlihat jelas'),
              _Tip('Pencahayaan cukup'),
              _Tip('Tidak blur'),
              _Tip('Gunakan jarak yang sesuai (dekati area rusak)'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Ambil Foto Lagi',
          icon: Icons.photo_camera_outlined,
          onPressed: () => _retake(ImageSource.camera),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Pilih Foto Lain',
          icon: Icons.photo_library_outlined,
          onPressed: () => _retake(ImageSource.gallery),
        ),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted))),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: AppColors.muted),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Hasil estimasi berbasis gambar, bukan penilaian teknis resmi.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }
}
