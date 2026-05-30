import 'package:flutter/material.dart';

/// Thông báo hiển thị cho cư dân (không lộ cấu hình kỹ thuật).
abstract final class TenantPaymentMessages {
  static const String alreadyPaid = 'Hóa đơn này đã được thanh toán.';

  static const String noQrYet =
      'Hóa đơn chưa có mã QR. Vui lòng liên hệ ban quản lý để được hỗ trợ thanh toán.';

  static const String unavailable =
      'Không thể tạo mã QR lúc này. Vui lòng thử lại sau hoặc liên hệ ban quản lý.';

  static const String serviceMaintenance =
      'Thanh toán QR tạm thời chưa khả dụng. Vui lòng liên hệ ban quản lý.';

  static const String loadingQr = 'Đang tạo mã QR thanh toán...';

  /// Luôn trả về câu phù hợp cư dân, bỏ qua nội dung kỹ thuật từ API.
  static String fromApi(String? raw) {
    if (raw == null || raw.trim().isEmpty) return unavailable;
    final lower = raw.toLowerCase();
    if (lower.contains('đã được thanh toán') || lower.contains('đã thanh toán')) {
      return alreadyPaid;
    }
    if (lower.contains('liên hệ ban quản lý') ||
        lower.contains('thử lại sau') ||
        lower.contains('tạm thời')) {
      return raw.trim();
    }
    return serviceMaintenance;
  }
}

void showTenantPaymentSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ),
  );
}
