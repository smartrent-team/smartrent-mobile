import 'package:flutter/material.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/home/presentation/pages/home_page.dart';
import 'package:smartrent_mobile/tenant/features/billing/presentation/pages/order_page.dart';

class TenantPaymentSuccessPage extends StatefulWidget {
  final String? invoiceCode;
  final int? amount;
  final String? transactionId;
  final String? paymentTime;

  const TenantPaymentSuccessPage({
    super.key,
    this.invoiceCode,
    this.amount,
    this.transactionId,
    this.paymentTime,
  });

  @override
  State<TenantPaymentSuccessPage> createState() =>
      _TenantPaymentSuccessPageState();
}

class _TenantPaymentSuccessPageState extends State<TenantPaymentSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _displayAmount {
    if (widget.amount != null) {
      final formatted = widget.amount!;
      final str = formatted.toString();
      final buffer = StringBuffer();
      final len = str.length;
      for (var i = 0; i < len; i++) {
        if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
        buffer.write(str[i]);
      }
      return '$buffer đ';
    }
    return '— đ';
  }

  String get _displayTime {
    if (widget.paymentTime != null) return widget.paymentTime!;
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} · ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF021B12),
              Color(0xFF063D1E),
              Color(0xFF0A5427),
              Color(0xFF0D6B30),
            ],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TenantColors.primaryGreen.withValues(alpha: 0.25),
                      blurRadius: 120,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          _buildSuccessIcon(),
                          const SizedBox(height: 28),
                          _buildSuccessText(),
                          const SizedBox(height: 36),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildTransactionInfo(),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TenantColors.primaryGreen.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: TenantColors.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TenantColors.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: TenantColors.primaryGreen,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessText() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          const Text(
            'Thanh toán thành công',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _displayAmount,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          if (widget.invoiceCode != null)
            Text(
              widget.invoiceCode!,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 14, letterSpacing: 1.0),
            ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: TenantColors.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: TenantColors.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded,
                    color: TenantColors.primaryGreen, size: 16),
                SizedBox(width: 8),
                Text(
                  'Thanh toán qua VNPay',
                  style: TextStyle(
                    color: TenantColors.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfo() {
    final items = <Map<String, String>>[];
    items.add({'label': 'Mã hóa đơn', 'value': widget.invoiceCode ?? '—'});
    items.add({'label': 'Phương thức', 'value': 'VNPay'});
    items.add({'label': 'Thời gian', 'value': _displayTime});
    if (widget.transactionId != null) {
      items.add({'label': 'Mã GD VNPay', 'value': widget.transactionId!});
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['label']!,
                          style: const TextStyle(
                              color: Color(0xFF88B89E),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 24),
                      Flexible(
                        child: Text(
                          item['value']!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const TenantOrderPage()),
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TenantColors.primaryGreen,
                elevation: 8,
                shadowColor: TenantColors.primaryGreen.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Xem hóa đơn',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const TenantHomePage()),
                (route) => false,
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, color: Colors.white70),
                  SizedBox(width: 10),
                  Text(
                    'Về trang chủ',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
