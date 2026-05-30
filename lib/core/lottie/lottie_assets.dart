/// Đường dẫn file Lottie trong [assets/lottie/].
///
/// Thêm constant mới khi bạn copy file `.json` vào thư mục tương ứng.
abstract final class LottieAssets {
  static const String _base = 'assets/lottie';

  // ── Loading ─────────────────────────────────────────────────────────────
  static const aiLoading = '$_base/loading/ai_loading.json';

  // ── Tenant ──────────────────────────────────────────────────────────────
  // static const tenantPaymentSuccess = '$_base/success/payment_success.json';

  // ── Manager ─────────────────────────────────────────────────────────────
  // static const managerInvoiceCreated = '$_base/manager/invoice_created.json';
}
