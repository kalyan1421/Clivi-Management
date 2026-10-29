import 'package:flutter/material.dart';
import 'app_colors.dart';

/// reusable app styles
class AppStyles {
  AppStyles._();

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x05000000), // Black with 2% opacity roughly
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> smallShadow = [
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6), // Blue 500
      Color(0xFF2563EB), // Blue 600
    ],
  );

  // Text Styles
  static const TextStyle statCount = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statLabel = TextStyle(
    color: Colors.white70,
    fontSize: 14,
  );

  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}
