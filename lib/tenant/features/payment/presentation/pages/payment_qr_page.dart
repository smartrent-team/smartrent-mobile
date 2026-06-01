import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/pages/payment_success_page.dart';

class TenantPaymentQRPage extends StatefulWidget {
  final double? amount;
  final String? invoiceCode;
  final String? bankContent;
  const TenantPaymentQRPage({super.key, this.amount, this.invoiceCode, this.bankContent});

  @override
  State<TenantPaymentQRPage> createState() => _TenantPaymentQRPageState();
}

class _TenantPaymentQRPageState extends State<TenantPaymentQRPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final int _secondsLeft = 14 * 60 + 33;

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

  String get _countdownText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
                        _buildBankChip(),
                        const SizedBox(height: 20),
                        _buildAmountSection(),
                        const SizedBox(height: 28),
                        _buildQrCard(),
                        const SizedBox(height: 16),
                        _buildCountdown(),
                        const SizedBox(height: 24),
                        _buildBankInfo(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _buildBottomButton(context),
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
                'Quét mã để chuyển khoản',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        _CircleIconButton(
          onTap: () {},
          child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
        ),
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
              child: const Text('V',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            const SizedBox(width: 10),
            const Text('Vietcombank · VCB',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(width: 10),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: TenantColors.primaryGreen, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    final String amountText = widget.amount != null
        ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
            .format(widget.amount)
            .replaceAll('₫', 'đ')
            .replaceAll(',00', '')
        : '2.850.000 đ';

    return Column(
      children: [
        const Text('Số tiền cần thanh toán',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        Text(
          amountText,
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
          Stack(
            alignment: Alignment.center,
            children: [
              _buildFakeQR(),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.home_work_rounded,
                    color: TenantColors.primaryGreen, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Nhà trọ Phúc An · P203',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            widget.invoiceCode ?? 'HD-2025-05-203',
            style: const TextStyle(
                fontSize: 13,
                color: TenantColors.textGrey,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFakeQR() {
    const size = 220.0;
    const cellCount = 25;
    const cellSize = size / cellCount;
    final rng = Random(42);
    final grid = List.generate(
      cellCount,
      (_) => List.generate(cellCount, (_) => rng.nextBool()),
    );

    void drawFinder(int row, int col) {
      for (int r = row; r < row + 7; r++) {
        for (int c = col; c < col + 7; c++) {
          grid[r][c] = (r == row || r == row + 6 || c == col || c == col + 6)
              ? true
              : (r >= row + 2 && r <= row + 4 && c >= col + 2 && c <= col + 4);
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(0, cellCount - 7);
    drawFinder(cellCount - 7, 0);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _QRPainter(grid: grid, cellSize: cellSize),
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, color: Colors.white60, size: 16),
          const SizedBox(width: 8),
          Text(
            'Hết hạn sau: $_countdownText',
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfo() {
    final items = [
      {'label': 'Ngân hàng', 'value': 'Vietcombank (VCB)'},
      {'label': 'Số tài khoản', 'value': '0901234567890'},
      {'label': 'Chủ tài khoản', 'value': 'TRAN VAN BINH'},
      {'label': 'Nội dung CK', 'value': widget.bankContent ?? 'Thue phong P203 HD-2025-05-203'},
    ];

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item['value']!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sao chép: ${item['label']}'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: TenantColors.primaryGreen.withValues(alpha: 0.15),
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

  Widget _buildBottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TenantPaymentSuccessPage()),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
          label: const Text(
            'Đã thanh toán',
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
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
    );
  }
}

// ── HELPERS ──────────────────────────────────────────────────────────────────
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

class _QRPainter extends CustomPainter {
  final List<List<bool>> grid;
  final double cellSize;
  const _QRPainter({required this.grid, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black87;
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    const logoSize = 56.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final logoRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: logoSize,
      height: logoSize,
    );

    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        if (!grid[r][c]) continue;
        final rect = Rect.fromLTWH(
          c * cellSize, r * cellSize, cellSize - 0.5, cellSize - 0.5,
        );
        if (rect.overlaps(logoRect)) continue;
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(1.0));
        canvas.drawRRect(rr, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
