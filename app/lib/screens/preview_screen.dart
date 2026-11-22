import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_services.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'analyzing_screen.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.imagePath, required this.source});

  final String imagePath;
  final ImageSource source;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late String _path = widget.imagePath;
  late ImageSource _source = widget.source;

  bool _useLocation = false;
  bool _locating = false;
  LocationResult? _location;

  Future<void> _replacePhoto() async {
    final source = await showSourceSheet(context);
    if (source == null || !mounted) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _path = picked.path;
        _source = source;
      });
    } catch (_) {
      if (mounted) showSnack(context, 'Foto tidak dapat dipilih.');
    }
  }

  Future<void> _toggleLocation(bool value) async {
    if (!value) {
      setState(() {
        _useLocation = false;
        _location = null;
      });
      return;
    }

    // Jelaskan dulu kenapa izin lokasi diminta (sesuai desain Figma).
    if (await AppServices.location.needsPermissionPrompt()) {
      if (!mounted) return;
      final agree = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.place_outlined, color: AppColors.cyan, size: 32),
          title: const Text('Izinkan akses lokasi?'),
          content: const Text(
            'Lokasi digunakan secara opsional untuk menyimpan koordinat '
            'pengambilan foto.\n\nTetap bisa deteksi tanpa lokasi.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nanti saja'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.navy,
              ),
              child: const Text('Izinkan'),
            ),
          ],
        ),
      );
      if (agree != true) return;
    }

    if (!mounted) return;
    setState(() {
      _useLocation = true;
      _locating = true;
      _location = null;
    });

    final result = await AppServices.location.getCurrent();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _location = result;
      if (!result.ok) _useLocation = false;
    });
    if (!result.ok) showSnack(context, result.message);
  }

  void _analyze() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalyzingScreen(
          imagePath: _path,
          source: _source,
          position: _useLocation ? _location?.position : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = _location?.position;

    return Scaffold(
      appBar: AppBar(title: const Text('Preview Foto')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          children: [
            const Text(
              'Periksa foto sebelum dianalisis.',
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                LocalPhoto(
                  path: _path,
                  height: 340,
                  width: double.infinity,
                  radius: 24,
                  cacheWidth: 1080,
                ),
                const Positioned(
                  left: 12,
                  top: 12,
                  child: InfoPill(
                    text: '1 foto dipilih',
                    icon: Icons.check_circle,
                    color: AppColors.cyan,
                    background: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, color: AppColors.cyan),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tambahkan lokasi (opsional)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_locating)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Switch(
                          value: _useLocation,
                          onChanged: _toggleLocation,
                          activeTrackColor: AppColors.cyan,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_locating)
                    const InfoPill(
                      text: 'Mengambil lokasi...',
                      icon: Icons.gps_fixed,
                      color: AppColors.cyan,
                      background: AppColors.cyanSoft,
                    )
                  else if (_useLocation && pos != null)
                    InfoPill(
                      text: 'Lokasi tersedia (±${pos.accuracy.round()} m)',
                      icon: Icons.place,
                      color: AppColors.green,
                      background: AppColors.greenSoft,
                    )
                  else
                    const InfoPill(
                      text: 'Lokasi tidak digunakan',
                      icon: Icons.location_off_outlined,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _source == ImageSource.gallery
                        ? 'Koordinat diambil dari posisi Anda saat ini, bukan dari lokasi foto di galeri.'
                        : 'Koordinat diambil dari posisi Anda saat ini.',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Analisis dengan AI',
              icon: Icons.auto_awesome,
              onPressed: _locating ? null : _analyze,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Ganti Foto',
              icon: Icons.swap_horiz,
              onPressed: _replacePhoto,
            ),
          ],
        ),
      ),
    );
  }
}
