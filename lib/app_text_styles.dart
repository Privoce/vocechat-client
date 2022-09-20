import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class AppTextStyles {
  // Only 2 weights for Chinese characters.
  // All FontWeights need to be either w600 (bold) or w400 (thin).

  // AppTextStyles.

  /// All AppBar titles
  /// TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.grey700)
  static TextStyle get titleLarge => TextStyle(
      fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.grey700);

  /// Chat tile title, list view tile title.
  static TextStyle get titleMedium => TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey700);

  static TextStyle get listTileTitle => TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.grey700);

  static TextStyle get snippet => TextStyle(
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 14,
        color: AppColors.darkGrey,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get labelLarge => TextStyle(
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 16,
        color: AppColors.grey500,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 14,
        color: AppColors.grey500,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 12,
        color: AppColors.darkGrey,
        fontWeight: FontWeight.w400,
      );
}
