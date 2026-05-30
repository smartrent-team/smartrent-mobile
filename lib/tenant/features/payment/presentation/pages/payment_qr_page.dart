import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/payment/domain/tenant_payment_args.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/tenant_payment_messages.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/pages/payment_success_page.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantPaymentQRPage extends StatefulWidget {
  final TenantPaymentArgs args;

  const TenantPaymentQRPage({super.key, required this.args});

  @override
  State<TenantPaymentQRPage> createState() => _TenantPaymentQRPageState();
}

class _TenantPaymentQRPageState extends State<TenantPaymentQRPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  TenantPaymentArgs get _args => widget.args;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String get _amountText => _currency.format(_args.amount);

  Future<void> _openCheckoutUrl() async {
    final url = _args.checkoutUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyText(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép: $label'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQr = _args.qrPayload != null && _args.qrPayload!.isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF021B12),
              Color(0xFF063D1E),
              Color(0xFF0D5C2E),
            ],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        if (_args.bankBin != null) _buildBankChip(),
                        const SizedBox(height: 20),
                        _buildAmountSection(),
                        const SizedBox(height: 28),
                        if (hasQr)
                          _buildQrCard()
                        else
                          _buildNoQrCard(),
                        const SizedBox(height: 24),
                        if (hasQr) _buildBankInfo(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _buildBottomActions(context, hasQr),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
        const Expanded(
          child: Column(
            children: [
              Text(
                'Thanh toán QR',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                'Quét mã VietQR từ PayOS',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_args.checkoutUrl != null && _args.checkoutUrl!.isNotEmpty)
          _CircleIconButton(
            onTap: _openCheckoutUrl,
            child: const Icon(Icons.open_in_browser_rounded,
                color: Colors.white, size: 20),
          )
        else
          const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildBankChip() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A4D2E),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: TenantColors.primaryGreen.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: TenantColors.primaryGreen, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.account_balance_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Ngân hàng · ${_args.bankBin}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      children: [
        const Text('Số tiền cần thanh toán',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        Text(
          _amountText,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: TenantColors.primaryGreen.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          QrImageView(
            data: _args.qrPayload!,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black87,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black87,
            ),
            embeddedImage: null,
          ),
          const SizedBox(height: 20),
          Text(
            _args.roomLabel,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            _args.invoiceCode,
            style: const TextStyle(
                fontSize: 13,
                color: TenantColors.textGrey,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_2_rounded,
              size: 64, color: TenantColors.textGrey),
          const SizedBox(height: 12),
          const Text(
            'Chưa có mã thanh toán',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            TenantPaymentMessages.noQrYet,
            textAlign: TextAlign.center,
            style: TextStyle(color: TenantColors.textGrey, fontSize: 13),
          ),
          if (_args.checkoutUrl != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openCheckoutUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: TenantColors.primaryGreen,
              ),
              child: const Text('Mở trang thanh toán',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankInfo() {
    final items = <Map<String, String>>[];
    if (_args.bankBin != null && _args.bankBin!.isNotEmpty) {
      items.add({'label': 'Ngân hàng (BIN)', 'value': _args.bankBin!});
    }
    if (_args.accountNumber != null && _args.accountNumber!.isNotEmpty) {
      items.add({'label': 'Số tài khoản', 'value': _args.accountNumber!});
    }
    if (_args.accountName != null && _args.accountName!.isNotEmpty) {
      items.add({'label': 'Chủ tài khoản', 'value': _args.accountName!});
    }
    final desc = _args.transferDescription ?? _args.invoiceCode;
    items.add({'label': 'Nội dung CK', 'value': desc});

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['label']!,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(item['value']!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _copyText(item['label']!, item['value']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              TenantColors.primaryGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: TenantColors.primaryGreen
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Text('Copy',
                            style: TextStyle(
                                color: TenantColors.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, color: Colors.white10),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, bool hasQr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          if (_args.checkoutUrl != null && _args.checkoutUrl!.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openCheckoutUrl,
                icon: const Icon(Icons.link_rounded, color: Colors.white70),
                label: const Text('Thanh toán qua link PayOS',
                    style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TenantPaymentSuccessPage()),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white),
              label: const Text(
                'Đã thanh toán',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TenantColors.primaryGreen,
                elevation: 6,
                shadowColor: TenantColors.primaryGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _CircleIconButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Center(child: child),
      ),
    );
  }
}
