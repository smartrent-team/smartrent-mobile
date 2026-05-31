import 'package:flutter/material.dart';

/// Thông báo hiển thị cho cư dân (không lộ cấu hình kỹ thuật).
abstract final class TenantPaymentMessages {
  static const String alreadyPaid = 'Hóa đơn này đã được thanh toán.';

  static const String noQrYet =
      'Hóa đơn chưa có mã thanh toán. Vui lòng liên hệ ban quản lý để được hỗ trợ thanh toán.';

  static const String unavailable =
      'Không thể khởi tạo thanh toán lúc này. Vui lòng thử lại sau hoặc liên hệ ban quản lý.';

  static const String serviceMaintenance =
      'Dịch vụ thanh toán tạm thời chưa khả dụng. Vui lòng liên hệ ban quản lý.';

  static const String loadingQr = 'Đang khởi tạo thanh toán...';

  static const String paymentSuccess =
      'Thanh toán thành công! Cảm ơn bạn đã thanh toán hóa đơn qua VNPay.';

  static const String paymentFailed =
      'Thanh toán không thành công hoặc đã bị hủy. Vui lòng thử lại.';

  static const String paymentCancelled = 'Đã hủy thanh toán.';

  static const String noLinkAvailable =
      'Không tìm thấy đường link thanh toán. Vui lòng liên hệ ban quản lý.';

  static const String openingPaymentGateway = 'Đang mở cổng thanh toán VNPay...';

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
