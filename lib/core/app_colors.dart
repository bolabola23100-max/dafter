import 'package:flutter/material.dart';

/// كل ألوان التطبيق في مكان واحد.
/// لو حبيت تغير لون التطبيق كله، غيّر من هنا بس.
class AppColors {
  AppColors._();

  // اللون الأساسي (تيل غامق) - نفس لون الأزرار والـ Sidebar في التصميم
  static const Color primary = Color(0xFF0E4C4C);
  static const Color primaryLight = Color(0xFF12615F);
  static const Color primaryDark = Color(0xFF0A3A3A);

  // خلفيات
  static const Color background = Color(0xFFF6F8F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sidebarBackground = Color(0xFFFFFFFF);

  // حدود وفواصل
  static const Color border = Color(0xFFE5E9EB);
  static const Color divider = Color(0xFFEFF2F3);

  // نصوص
  static const Color textPrimary = Color(0xFF1A2327);
  static const Color textSecondary = Color(0xFF6B7A80);
  static const Color textMuted = Color(0xFFA0ADB2);

  // حالات (Status colors)
  static const Color success = Color(0xFF0F9D58);
  static const Color successBg = Color(0xFFE6F4EA);

  static const Color danger = Color(0xFFD93025);
  static const Color dangerBg = Color(0xFFFCE8E6);

  static const Color warning = Color(0xFFF29900);
  static const Color warningBg = Color(0xFFFEF3E0);

  static const Color info = Color(0xFF1A73E8);
  static const Color infoBg = Color(0xFFE8F0FE);

  static const Color neutralBg = Color(0xFFF1F3F4);
  static const Color neutralText = Color(0xFF5F6368);
}
