import 'package:flutter/material.dart';

/// Chuyển cảnh mượt khi điều hướng — chỉ animation, không đổi logic màn hình.
abstract final class AppPageRoutes {
  static const Duration tabDuration = Duration(milliseconds: 260);
  static const Duration pageDuration = Duration(milliseconds: 320);
  static const Duration modalDuration = Duration(milliseconds: 360);

  /// Chuyển tab / màn chính (fade nhẹ + trượt dọc rất nhỏ).
  static Route<T> fade<T>(Widget page, {String? name, Duration? duration}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      transitionDuration: duration ?? tabDuration,
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.018),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Màn chi tiết / form — trượt ngang + fade (giống iOS/Material 3).
  static Route<T> slide<T>(Widget page, {String? name}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      transitionDuration: pageDuration,
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offset = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curved);
        return SlideTransition(
          position: offset,
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Màn nhập liệu / xác nhận — trượt từ dưới lên.
  static Route<T> modal<T>(Widget page, {String? name}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      transitionDuration: modalDuration,
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }
}

extension AppNavigatorTransitions on BuildContext {
  Future<T?> pushFade<T extends Object?>(Widget page, {String? name}) {
    return Navigator.of(this).push<T>(AppPageRoutes.fade<T>(page, name: name));
  }

  Future<T?> pushSlide<T extends Object?>(Widget page, {String? name}) {
    return Navigator.of(this).push<T>(AppPageRoutes.slide<T>(page, name: name));
  }

  Future<T?> pushModal<T extends Object?>(Widget page, {String? name}) {
    return Navigator.of(this).push<T>(AppPageRoutes.modal<T>(page, name: name));
  }
}
