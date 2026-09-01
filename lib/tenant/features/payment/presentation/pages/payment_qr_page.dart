import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/payment/domain/tenant_payment_args.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/tenant_payment_messages.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/pages/payment_success_page.dart';
import 'package:smartrent_mobile/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantPaymentQRPage extends StatefulWidget {
  final TenantPaymentArgs? args;
  final int? invoiceId;
  final int? amount;
  final String? invoiceCode;
  final String? roomLabel;
  final String? bankContent;

  const TenantPaymentQRPage({
    super.key,
    this.args,
    this.invoiceId,
    this.amount,
    this.invoiceCode,
    this.roomLabel,
    this.bankContent,
  });

  @override
  State<TenantPaymentQRPage> createState() => _TenantPaymentQRPageState();
}

class _TenantPaymentQRPageState extends State<TenantPaymentQRPage> {
  late final WebViewController _controller;

  bool _isLoading = true;
  String? _errorMessage;
  bool _hasNavigated = false;

  TenantPaymentArgs get _args {
    if (widget.args != null) return widget.args!;
    return TenantPaymentArgs(
      invoiceId: widget.invoiceId ?? 0,
      amount: widget.amount ?? 0,
      invoiceCode: widget.invoiceCode ?? '',
      roomLabel: widget.roomLabel ?? '',
      checkoutUrl: '', // Will handle error in initState
    );
  }

  @override
  void initState() {
    super.initState();
    _initWebView();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _handleNavigation(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('[WebView Error] type: ${error.errorType}, desc: ${error.description}, isMainFrame: ${error.isForMainFrame}');
            // Chỉ coi là lỗi fatal khi chính trang chính (main frame) không thể tải
            if (!_hasNavigated && (error.isForMainFrame == true)) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Không thể tải trang thanh toán (${error.description}). Vui lòng thử lại.';
              });
            }
          },
          onNavigationRequest: (request) async {
            final url = request.url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thiết bị chưa cài ứng dụng Ngân hàng này. Vui lòng chọn tab "Thẻ ATM / Tài khoản ngân hàng" để thanh toán demo.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                }
              } catch (_) {}
              return NavigationDecision.prevent;
            }
            _handleNavigation(url);
            return NavigationDecision.navigate;
          },
        ),
      );

    final checkoutUrl = _args.checkoutUrl;
    if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
      _controller.loadRequest(Uri.parse(checkoutUrl)).catchError((e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể mở cổng thanh toán. Vui lòng thử lại.';
        });
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = TenantPaymentMessages.noLinkAvailable;
      });
    }
  }

  Future<void> _handleNavigation(String url) async {
    if (_hasNavigated) return;

    if (!url.contains('/api/webhooks/vnpay/return')) return;

    _hasNavigated = true;

    final uri = Uri.parse(url);
    final responseCode = uri.queryParameters['vnp_ResponseCode'];

    try {
      final dio = Dio();

      // Xây lại URL dùng baseUrl từ AppConstants để hoạt động trên cả
      // emulator (10.0.2.2) lẫn điện thoại thật (tunnel URL)
      final queryString = uri.query;
      final backendBase = AppConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
      final finalUrl = '$backendBase/api/webhooks/vnpay/return?$queryString';

      await dio.get(finalUrl);
    } catch (e) {
      debugPrint('Error triggering webhook: $e');
    }

    if (responseCode == '00') {
      _navigateToSuccess();
    } else {
      _handlePaymentCancelledOrFailed(responseCode);
    }
  }

  void _navigateToSuccess() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TenantPaymentSuccessPage(
          invoiceCode: _args.invoiceCode,
          amount: _args.amount,
        ),
      ),
      (route) => false,
    );
  }

  void _handlePaymentCancelledOrFailed(String? responseCode) {
    if (!mounted) return;
    String message;
    if (responseCode == null) {
      message = TenantPaymentMessages.paymentCancelled;
    } else {
      message = TenantPaymentMessages.paymentFailed;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TenantColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: TenantColors.errorRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Thanh toán thất bại',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: TenantColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thanh toán VNPay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Đang kết nối cổng thanh toán...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black54)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitConfirmation(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.8),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: TenantColors.primaryGreen),
            SizedBox(height: 20),
            Text(
              'Đang tải cổng thanh toán...',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TenantColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: TenantColors.errorRed, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Không thể mở thanh toán',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? TenantPaymentMessages.unavailable,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TenantColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF9800), size: 26),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hủy thanh toán?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn đang trong quá trình thanh toán. Nếu thoát ngay, giao dịch có thể chưa hoàn tất.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Tiếp tục thanh toán',
              style: TextStyle(color: TenantColors.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: TenantColors.errorRed,
            ),
            child: const Text('Hủy thanh toán'),
          ),
        ],
      ),
    );
  }
}
