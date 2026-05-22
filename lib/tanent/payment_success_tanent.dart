import 'package:flutter/material.dart';
import 'package:smartrent_mobile/tanent/home_tanent.dart';

class PaymentSuccessTanent extends StatefulWidget {
  const PaymentSuccessTanent({super.key});

  @override
  State<PaymentSuccessTanent> createState() => _PaymentSuccessTanentState();
}

class _PaymentSuccessTanentState extends State<PaymentSuccessTanent>
    with TickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF4CAF50);

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

    // Staggered start
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
            // Glow effect in background
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
                      color: primaryGreen.withValues(alpha: 0.25),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildTransactionInfo(),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SUCCESS ICON ──────────────────────────────────────────────────────────
  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryGreen.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Mid ring
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          // Core circle
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: primaryGreen,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SUCCESS TEXT ─────────────────────────────────────────────────────────
  Widget _buildSuccessText() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: const [
          Text(
            'Thanh toán thành công',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '2.850.000 đ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'HD-2025-05-203',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TRANSACTION INFO ─────────────────────────────────────────────────────
  Widget _buildTransactionInfo() {
    final items = [
      {'label': 'Người nhận', 'value': 'TRAN VAN BINH'},
      {'label': 'Ngân hàng', 'value': 'Vietcombank (VCB)'},
      {'label': 'Số tài khoản', 'value': '0901234567890'},
      {'label': 'Thời gian', 'value': '21/05/2025 · 14:32:07'},
      {'label': 'Mã GD', 'value': 'VCB60821863'},
    ];

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
                      Text(
                        item['label']!,
                        style: const TextStyle(
                          color: Color(0xFF88B89E),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Flexible(
                        child: Text(
                          item['value']!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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

  // ─── BOTTOM BUTTON ─────────────────────────────────────────────────────────
  Widget _buildBottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeTanent()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            elevation: 8,
            shadowColor: primaryGreen.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.home_outlined, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Về trang chủ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
