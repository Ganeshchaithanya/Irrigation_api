import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color emerald      = Color(0xFF10B981);
  static const Color emeraldDark  = Color(0xFF065F46);
  static const Color emeraldLight = Color(0xFFD1FAE5);
  static const Color ivory        = Color(0xFFFDFDF9);
  
  // Semantic Colors
  static const Color success      = Color(0xFF10B981);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color danger       = Color(0xFFEF4444);
  static const Color info         = Color(0xFF3B82F6);

  // Surface & Text
  static const Color background   = Color(0xFFF9FAFB);
  static const Color surface      = Colors.white;
  static const Color textPrimary  = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted    = Color(0xFF9CA3AF);

  // Gradients
  static const List<Color> emeraldGradient = [
    Color(0xFF065F46),
    Color(0xFF10B981),
  ];

  static const List<Color> primaryGradient = emeraldGradient;

  static const List<Color> aiAdvisoryGradient = [
    Color(0xFF7C3AED), // Purple-ish 
    Color(0xFF10B981), // Emerald
  ];

  // Glass & Borders
  static const Color glassWhite   = Color(0x33FFFFFF);
  static const Color glassBorder  = Color(0x4DFFFFFF);
  static const Color borderLight  = Color(0xFFE5E7EB);
}

