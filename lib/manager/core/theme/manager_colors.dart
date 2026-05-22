import 'package:flutter/material.dart';

/// Bảng màu thống nhất module Manager (palette trang Cư dân — xanh nhạt).
abstract final class ManagerColors {
  ManagerColors._();

  /// Xanh chủ đạo
  static const Color primaryGreen = Color(0xFF2D9D5E);

  /// Xanh nhạt hơn (gradient, accent phụ)
  static const Color primaryGreenLight = Color(0xFF42A36E);

  /// Nền màn hình
  static const Color bgLightGreen = Color(0xFFF4F9F6);

  /// Nền / tint xanh mint
  static const Color bgMint = Color(0xFFE8F5E9);
  static const Color bgMintPale = Color(0xFFF1FDF5);

  static const Color lightGreenBorder = Color(0xFFB9E4C9);
  static const Color lightGreenBg = Color(0xFFE1F2E8);
  static const Color fieldBgTint = Color(0xFFF1FDF5);

  static const Color textCharcoal = Color(0xFF2D312E);
  static const Color textGrey = Color(0xFF757575);
  static const Color subtitleGrey = Color(0xFF757575);

  static const Color cardShadow = Color(0x0D000000);
}
