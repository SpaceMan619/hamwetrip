import 'package:flutter/material.dart';

abstract final class AppColors {
  // Inferra AI-inspired palette: quiet canvas, charcoal type, one clear accent.
  static const charcoal = Color(0xFF222F30);
  static const deepSea = Color(0xFF445E5F);
  static const offWhite = Color(0xFFF7F7F5);
  static const accent = Color(0xFF22C55E);

  // Legacy names remain as aliases so feature code can migrate incrementally.
  static const forest = charcoal;
  static const forestLight = deepSea;
  static const sunset = Color(0xFFF59E0B);
  static const warmSand = offWhite;
  static const sand = Color(0xFFEEEEEE);
  static const ink = charcoal;
  static const muted = deepSea;
  static const line = Color(0xFFDDE2DE);
  static const mint = accent;
  static const paleMint = Color(0xFFE8F6EC);
  static const paleSunset = Color(0xFFFFE0C9);
}
