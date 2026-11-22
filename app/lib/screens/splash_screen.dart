import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_services.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Muat model + buka database, minimal tampil 1,4 detik agar splash terbaca.
    await Future.wait<Object?>([
      AppServices.classifier.load(),
      AppServices.db.init(),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);

    var onboarded = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboarded = prefs.getBool('onboarded') ?? false;
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) =>
            onboarded ? const ShellScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.cyan, width: 2),
                ),
                child: const Icon(Icons.add_road, size: 52, color: AppColors.cyan),
              ),
              const SizedBox(height: 24),
              const Text(
                'SNAPROAD',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'AI ROAD DAMAGE DETECTION',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(flex: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: AppColors.raised,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Menyiapkan SNAPROAD...',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              const Text(
                'DETEKSI LOKAL. TANPA AKUN.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
