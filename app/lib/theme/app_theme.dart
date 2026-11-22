import 'package:flutter/material.dart';

/// Token warna dari Design System SNAPROAD (Figma).
class AppColors {
  AppColors._();

  static const navy = Color(0xFF0A1A2F);
  static const surface = Color(0xFF122B43);
  static const raised = Color(0xFF19364E);
  static const cyan = Color(0xFF00D9FF);
  static const orange = Color(0xFFFF6B35);
  static const text = Color(0xFFF5F7FA);
  static const muted = Color(0xFFB2C4D4);
  static const border = Color(0xFF385268);
  static const green = Color(0xFF47DEAC);
  static const amber = Color(0xFFFFBF57);
  static const red = Color(0xFFFF7687);

  // Latar lembut (alpha ~16%) untuk chip/badge.
  static const cyanSoft = Color(0x2900D9FF);
  static const orangeSoft = Color(0x29FF6B35);
  static const greenSoft = Color(0x2947DEAC);
  static const amberSoft = Color(0x29FFBF57);
  static const redSoft = Color(0x29FF7687);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.cyan,
      onPrimary: AppColors.navy,
      secondary: AppColors.orange,
      onSecondary: AppColors.navy,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.red,
      onError: AppColors.navy,
      outline: AppColors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.navy,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.cyanSoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.cyan : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.cyan : AppColors.muted,
          );
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.raised,
        contentTextStyle: TextStyle(color: AppColors.text),
      ),
    );
  }
}
