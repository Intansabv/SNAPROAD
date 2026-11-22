import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_services.dart';
import '../services/classifier_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Layar "Menganalisis gambar..." -> menjalankan model -> membuka layar hasil.
class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({
    super.key,
    required this.imagePath,
    required this.source,
    this.position,
  });

  final String imagePath;
  final ImageSource source;
  final Position? position;

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_error != null) setState(() => _error = null);
    // Tampilkan animasi minimal ~1 detik agar tidak berkedip.
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 1000));
    try {
      final result = await AppServices.classifier.classify(widget.imagePath);
      await minDelay;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            imagePath: widget.imagePath,
            source: widget.source,
            result: result,
            position: widget.position,
          ),
        ),
      );
    } on ModelUnavailableException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('[SNAPROAD] Analisis gagal: $e');
      if (mounted) setState(() => _error = 'Analisis gagal. Coba lagi.\n\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final failed = _error != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Analisis AI')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: LocalPhoto(
                        path: widget.imagePath,
                        radius: 24,
                        cacheWidth: 1080,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0x990A1A2F),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    if (!failed)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _scan,
                          builder: (context, _) => Align(
                            alignment: Alignment(0, -1 + 2 * _scan.value),
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.cyan,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: const [
                                  BoxShadow(color: AppColors.cyan, blurRadius: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    const Positioned(
                      left: 12,
                      top: 12,
                      child: InfoPill(
                        text: 'AI SCAN',
                        icon: Icons.auto_awesome,
                        color: AppColors.cyan,
                        background: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!failed) ...[
                const SectionLabel('PROSES LOKAL'),
                const SizedBox(height: 8),
                const Text(
                  'Menganalisis gambar...',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'AI sedang mendeteksi kerusakan jalan',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: AppColors.raised,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Foto diproses di perangkat Anda.\nTidak memerlukan unggahan ke cloud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                ),
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.red),
                    SizedBox(width: 8),
                    Text(
                      'Analisis gagal',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Coba Lagi', icon: Icons.refresh, onPressed: _run),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Kembali',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
