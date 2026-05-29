import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand
  static const Color navy = Color(0xFF0A1628);
  static const Color navyMid = Color(0xFF162040);
  static const Color navyLight = Color(0xFF1E2D4E);
  static const Color teal = Color(0xFF00D4AA);
  static const Color tealLight = Color(0xFF4DFFD6);
  static const Color tealDark = Color(0xFF00A882);

  // Metric Colors (consistent across app)
  static const Color heartRed = Color(0xFFFF4757);
  static const Color oxygenBlue = Color(0xFF4A9EFF);
  static const Color tempOrange = Color(0xFFFF9500);
  static const Color breathGreen = Color(0xFF2ED573);
  static const Color sleepPurple = Color(0xFF9B59B6);
  static const Color stressCoral = Color(0xFFFF6B6B);
  static const Color activityTeal = Color(0xFF00D4AA);
  static const Color skinPink = Color(0xFFFF8FA3);

  // Status
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFFF4757);
  static const Color info = Color(0xFF4A9EFF);

  // Light Theme
  static const Color bgLight = Color(0xFFF4F7FB);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFECF0F7);
  static const Color textPrimary = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF5A6A85);
  static const Color textTertiary = Color(0xFF9AA8BF);
  static const Color dividerLight = Color(0xFFE4E9F2);

  // Dark Theme
  static const Color bgDark = Color(0xFF0A1628);
  static const Color cardDark = Color(0xFF162040);
  static const Color surfaceDark = Color(0xFF1E2D4E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0BDD4);
  static const Color dividerDark = Color(0xFF243050);

  // Gradients
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF162040)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4AA), Color(0xFF00A882)],
  );

  static const LinearGradient heartGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B7A), Color(0xFFFF4757)],
  );

  static const LinearGradient oxygenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6DB8FF), Color(0xFF4A9EFF)],
  );

  static const LinearGradient tempGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB347), Color(0xFFFF9500)],
  );

  static const LinearGradient sleepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBD7CF0), Color(0xFF9B59B6)],
  );
}
