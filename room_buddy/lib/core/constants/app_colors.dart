import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  
  // Brand Identity (Modern Trustworthy Indigo & Emerald)
  static const Color primary = Color(0xFF4F46E5);      // Modern Indigo
  static const Color primaryDark = Color(0xFF3730A3);  // Deep Indigo
  static const Color primaryLight = Color(0xFFEEF2FF); // Soft Indigo Tint
  static const Color accent = Color(0xFF0D9488);       // Emerald Teal
  static const Color accentLight = Color(0xFFCCFBF1);  // Mint Tint
  
  // Neutral Surfaces & Hierarchy
  static const Color background = Color(0xFFF8FAFC);  // Crisp Slate 50
  static const Color surface = Color(0xFFFFFFFF);     // Pure White
  static const Color surfaceMuted = Color(0xFFF1F5F9);// Slate 100
  static const Color divider = Color(0xFFE2E8F0);     // Slate 200
  static const Color border = Color(0xFFE2E8F0);      // Slate 200
  static const Color cardShadow = Color(0x0A0F172A);  // Subtle ambient shadow
  
  // Typography
  static const Color textPrimary = Color(0xFF0F172A);  // Slate 900
  static const Color textSecondary = Color(0xFF64748B);// Slate 500
  static const Color textMuted = Color(0xFF94A3B8);    // Slate 400
  
  // Status & Feedback
  static const Color success = Color(0xFF10B981);      // Emerald 500
  static const Color successLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color successDark = Color(0xFF065F46);  // Emerald 800
  static const Color warning = Color(0xFFF59E0B);      // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color warningDark = Color(0xFF92400E);  // Amber 800
  static const Color error = Color(0xFFEF4444);        // Rose 500
  static const Color errorLight = Color(0xFFFEE2E2);   // Rose 100
  static const Color errorDark = Color(0xFF991B1B);    // Rose 800
  
  // Marketplace Specific
  static const Color star = Color(0xFFF59E0B);         // Amber Star
  static const Color verified = Color(0xFF10B981);     // Verified Badge
  static const Color unverified = Color(0xFFF97316);   // Pending / Warning
  static const Color locked = Color(0xFF6366F1);       // Locked feature badge
}
