import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Brand Palette (Based on User Logo)
  static const Color navyDeep      = Color(0xFF0A2540); 
  static const Color brandEmerald   = Color(0xFF0F9D58);
  static const Color leafGreen     = Color(0xFF4CAF50);
  
  // Growth & Health Palette
  static const Color growthDark    = Color(0xFF16A34A);
  static const Color growthMid     = Color(0xFF22C55E);
  static const Color growthLight   = Color(0xFF86EFAC);

  // Water & AI Intensity Palette
  static const Color waterDeep     = Color(0xFF1E3A8A);
  static const Color waterMid      = Color(0xFF3B82F6);
  static const Color waterLight    = Color(0xFF60A5FA);

  // Premium Accents (Gold)
  static const Color goldDark      = Color(0xFFF59E0B);
  static const Color goldMid       = Color(0xFFFBBF24);
  static const Color goldLight     = Color(0xFFFDE68A);

  // Semantic Colors
  static const Color success      = Color(0xFF0F9D58);
  static const Color warning      = Color(0xFFFBBF24);
  static const Color danger       = Color(0xFFEF4444);
  static const Color info         = Color(0xFF3B82F6);

  // Surface & Text
  static const Color background   = Color(0xFFF8FAFC);
  static const Color surface      = Color(0xFFF8FAFC);
  static const Color textPrimary  = Color(0xFF0F172A); // Strong dark slate
  static const Color textSecondary = Color(0xFF475569); // Slate secondary
  static const Color textMuted    = Color(0xFF94A3B8);

  // Gradients (Investor-Grade)
  static const List<Color> primaryGradient = [
    Color(0xFF0A2540),
    Color(0xFF0F9D58),
    Color(0xFF4CAF50),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF1E3A8A),
    Color(0xFF3B82F6),
    Color(0xFF60A5FA),
  ];

  static const List<Color> growthGradient = [
    Color(0xFF0F9D58),
    Color(0xFF22C55E),
    Color(0xFF86EFAC),
  ];

  static const List<Color> aiAdvisoryGradient = [
    Color(0xFF3B82F6), // Blue (Intelligence)
    Color(0xFF0F9D58), // Green (Agriculture)
  ];

  static const List<Color> accentGradient = [
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
    Color(0xFFFDE68A),
  ];

  static const List<Color> brandGradient = [
    Color(0xFF0F3D3E),
    Color(0xFF136F63),
    Color(0xFF1FAB89),
    Color(0xFF62D2A2),
  ];
  static const Color glassWhite   = Color(0x33FFFFFF);
  static const Color glassBorder  = Color(0x4DFFFFFF);
  static const Color borderLight  = Color(0xFFE2E8F0);

  // Legacy Compatibility (mapping old names to new palette)
  static const Color emerald = Color(0xFF0F9D58);
  static const Color emeraldDark = Color(0xFF0A2540);
  static const List<Color> emeraldGradient = growthGradient;
}
