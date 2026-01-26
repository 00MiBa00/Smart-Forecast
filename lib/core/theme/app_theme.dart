import 'package:flutter/cupertino.dart';

class AppTheme {
  // Colors - Dark theme by default for documentation reading
  static const Color backgroundColor = Color(0xFF000000);
  static const Color surfaceColor = Color(0xFF1C1C1E);
  static const Color secondarySurface = Color(0xFF2C2C2E);
  static const Color tertiaryFill = Color(0xFF3A3A3C);
  
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF8E8E93);
  static const Color tertiaryText = Color(0xFF636366);
  
  static const Color accentBlue = Color(0xFF0A84FF);
  static const Color accentGreen = Color(0xFF30D158);
  static const Color accentRed = Color(0xFFFF453A);
  static const Color accentYellow = Color(0xFFFFD60A);
  static const Color accentOrange = Color(0xFFFF9F0A);
  
  static const Color separator = Color(0xFF38383A);
  
  // Difficulty colors
  static const List<Color> difficultyColors = [
    Color(0xFF30D158), // Easy - green
    Color(0xFF0A84FF), // Medium - blue
    Color(0xFFFFD60A), // Hard - yellow
    Color(0xFFFF453A), // Very Hard - red
  ];

  // SRS grading colors
  static const Color againColor = Color(0xFFFF453A);
  static const Color hardColor = Color(0xFFFF9F0A);
  static const Color goodColor = Color(0xFF0A84FF);
  static const Color easyColor = Color(0xFF30D158);
  
  // Text styles
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: primaryText,
    letterSpacing: 0.4,
  );
  
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryText,
  );
  
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: primaryText,
  );
  
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );
  
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: primaryText,
  );
  
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: primaryText,
  );
  
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: secondaryText,
  );
  
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: secondaryText,
  );
  
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: secondaryText,
  );
  
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: tertiaryText,
  );

  // Spacing
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}
