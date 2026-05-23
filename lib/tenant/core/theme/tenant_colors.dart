import 'package:flutter/material.dart';

/// Bảng màu thống nhất module Tenant (palette xanh lá).
abstract final class TenantColors {
  TenantColors._();

  // ── Primary greens ────────────────────────────────────────────────────────
  static const Color primaryGreen      = Color(0xFF4CAF50);
  static const Color primaryGreenAlt   = Color(0xFF42A36E); // login/otp variant
  static const Color primaryGreenLight = Color(0xFF5CB85C); // nav/profile variant
  static const Color primaryGreenDark  = Color(0xFF388E3C);

  // ── Background ────────────────────────────────────────────────────────────
  static const Color bgLightGreen  = Color(0xFFF1F8F4);
  static const Color bgMint        = Color(0xFFE8F5E9);
  static const Color bgMintPale    = Color(0xFFF1FDF5);
  static const Color bgScreenLight = Color(0xFFF0F5F2);
  static const Color bgScreenRepair= Color(0xFFF8FAF9);

  // ── Tint / border ─────────────────────────────────────────────────────────
  static const Color lightGreenBg     = Color(0xFFE1F2E8);
  static const Color lightGreenBorder = Color(0xFFB9E4C9);
  static const Color fieldBgTint      = Color(0xFFF1FDF5);
  static const Color cardBg           = Color(0xFFF7FBF9);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textCharcoal  = Color(0xFF2D312E);
  static const Color textBlack87   = Color(0xDD000000);
  static const Color textGrey      = Color(0xFF757575);
  static const Color subtitleGrey  = Color(0xFF9E9E9E);

  // ── Accent / semantic ─────────────────────────────────────────────────────
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color warningAmber  = Color(0xFFFFB300);
  static const Color errorRed      = Color(0xFFE65100);

  // ── Shadow ────────────────────────────────────────────────────────────────
  static const Color cardShadow = Color(0x0D000000);
}
