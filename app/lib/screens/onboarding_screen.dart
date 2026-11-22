import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell_screen.dart';

class _Page {
  const _Page(this.icon, this.tag, this.title, this.body);
  final IconData icon;
  final String tag;
  final String title;
  final String body;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _Page(
      Icons.document_scanner_outlined,
      'ANALISIS SATU FOTO',
      'Deteksi Kerusakan\nJalan dengan AI',
      'Analisis foto kondisi jalan menggunakan teknologi computer vision.',
    ),
    _Page(
      Icons.layers_outlined,
      'KENALI TINGKAT KEPARAHAN',
      'Ringan, Sedang,\natau Berat',
      'AI mengestimasi tingkat keparahan kerusakan lengkap dengan confidence score.',
    ),
    _Page(
      Icons.folder_open_outlined,
      'DOKUMENTASI LOKAL',
      'Simpan Hasil',
      'Simpan hasil analisis dan lokasi secara lokal untuk dokumentasi.',
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarded', true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ShellScreen()),
    );
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: last ? null : _finish,
                  child: Text(
                    'Lewati',
                    style: TextStyle(
                      color: last ? Colors.transparent : AppColors.muted,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(p.icon, size: 96, color: AppColors.cyan),
                        ),
                        const SizedBox(height: 32),
                        SectionLabel(p.tag),
                        const SizedBox(height: 8),
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.body,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.cyan : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: last ? 'Mulai' : 'Lanjut', onPressed: _next),
            ],
          ),
        ),
      ),
    );
  }
}
