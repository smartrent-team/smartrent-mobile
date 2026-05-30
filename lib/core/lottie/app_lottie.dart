import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget bọc Lottie — dùng chung cho loading / empty / success.
class AppLottie extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final Animation<double>? controller;

  const AppLottie({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      controller: controller,
      errorBuilder: (_, __, ___) => SizedBox(
        width: width ?? 120,
        height: height ?? 120,
        child: const Icon(Icons.animation_outlined, size: 48),
      ),
    );
  }
}
