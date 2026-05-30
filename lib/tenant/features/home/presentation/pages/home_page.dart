import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/billing/data/tenant_invoice_service.dart';
import 'package:smartrent_mobile/tenant/features/billing/domain/models/tenant_invoice.dart';
import 'package:smartrent_mobile/tenant/features/billing/presentation/pages/order_page.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/tenant_payment_nav.dart';
import 'package:smartrent_mobile/tenant/features/contract/presentation/pages/contract_page.dart';
import 'package:google_fonts/google_fonts.dart';

class TenantHomePage extends StatefulWidget {
  final bool showBottomNav;
  const TenantHomePage({super.key, this.showBottomNav = true});

  @override
  State<TenantHomePage> createState() => _TenantHomePageState();
}

class _TenantHomePageState extends State<TenantHomePage> {
  final TenantInvoiceService _invoiceService = TenantInvoiceService();
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  int _currentIndex = 0;
  bool _isBillExpanded = false;
  TenantInvoice? _unpaidInvoice;

  @override
  void initState() {
    super.initState();
    _loadUnpaidInvoice();
  }

  Future<void> _loadUnpaidInvoice() async {
    try {
      final res = await _invoiceService.getMyInvoices();
      if (res.statusCode == 200 && res.data['success'] == true) {
        final docs = (res.data['docs'] as List? ?? [])
            .map((e) => TenantInvoice.fromJson(e as Map<String, dynamic>))
            .toList();
        final unpaid = docs.where((i) => !i.isPaid && i.canPay).toList();
        if (mounted) {
          setState(() => _unpaidInvoice = unpaid.isNotEmpty ? unpaid.first : null);
        }
      }
    } catch (_) {}
  }

  void _openPayment() {
    if (_unpaidInvoice != null) {
      openTenantPaymentQr(context, _unpaidInvoice!);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TenantOrderPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TenantColors.bgLightGreen,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBillCard(),
                        const SizedBox(height: 24),
                        _buildQuickServices(),
                        const SizedBox(height: 24),
                        _buildNotifications(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF388E3C),
                TenantColors.primaryGreen,
                Color(0xFF66BB6A),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xin chào 👋',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Nguyễn Văn A',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildHeaderChip('Phòng P203'),
                          const SizedBox(width: 8),
                          _buildHeaderChip('Tầng 2'),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildContractCard(),
            ],
          ),
        ),
        Positioned(
          right: -30,
          top: -20,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          right: 40,
          top: 60,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── CONTRACT CARD ────────────────────────────────────────────────────────
  Widget _buildContractCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildContractCol('Hợp đồng còn', '102 ngày')),
          Container(width: 1, height: 28, color: Colors.white24),
          Expanded(child: _buildContractCol('Tháng hiện tại', 'T5/2025')),
          Container(width: 1, height: 28, color: Colors.white24),
          Expanded(child: _buildContractCol('Phòng', 'Hoạt động')),
        ],
      ),
    );
  }

  Widget _buildContractCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── BILL CARD ────────────────────────────────────────────────────────────
  Widget _buildBillCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: TenantColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: TenantColors.bgMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: TenantColors.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hóa đơn tháng 5/2025',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Phòng P203 · Nhà trọ Phúc An',
                            style: TextStyle(
                              fontSize: 12,
                              color: TenantColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time,
                              color: Color(0xFFE65100), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Chờ thanh toán',
                            style: TextStyle(
                              color: Color(0xFFE65100),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tổng số tiền',
                  style: TextStyle(fontSize: 14, color: TenantColors.textGrey),
                ),
                const SizedBox(height: 4),
                const Text(
                  '2.850.000 đ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Cost list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TenantColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEAF5EF)),
                  ),
                  child: Column(
                    children: [
                      _costRow(Icons.home_work_outlined,
                          TenantColors.bgMint, TenantColors.primaryGreen,
                          'Tiền phòng', '2.200.000 đ'),
                      const Divider(height: 24, color: Color(0xFFEAF5EF)),
                      _costRow(Icons.bolt_outlined,
                          const Color(0xFFFFF3E0), TenantColors.warningOrange,
                          'Tiền điện', '312.000 đ'),
                      const Divider(height: 24, color: Color(0xFFEAF5EF)),
                      _costRow(Icons.water_drop_outlined,
                          const Color(0xFFE1F5FE), Colors.blue,
                          'Tiền nước', '78.000 đ'),
                      if (_isBillExpanded) ...[
                        const Divider(height: 24, color: Color(0xFFEAF5EF)),
                        _costRow(Icons.wifi_outlined,
                            const Color(0xFFF3E5F5), Colors.purple,
                            'Internet', '120.000 đ'),
                        const Divider(height: 24, color: Color(0xFFEAF5EF)),
                        _costRow(Icons.star_outline_rounded,
                            const Color(0xFFFCE4EC), Colors.pink,
                            'Phí dịch vụ', '140.000 đ'),
                      ],
                      const Divider(height: 24, color: Color(0xFFEAF5EF)),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isBillExpanded = !_isBillExpanded),
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: Colors.transparent,
                          child: Text(
                            _isBillExpanded
                                ? 'Thu gọn ▲'
                                : 'Xem thêm 2 khoản ▼',
                            style: const TextStyle(
                              color: TenantColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: TenantColors.errorRed, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Hạn thanh toán: ',
                      style: TextStyle(
                          fontSize: 13, color: TenantColors.textGrey),
                    ),
                    Text(
                      '10/06/2025',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: TenantColors.errorRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _openPayment,
                    icon: const Icon(Icons.qr_code_scanner_outlined,
                        color: Colors.white),
                    label: const Text(
                      'Thanh toán ngay',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TenantColors.primaryGreen,
                      elevation: 4,
                      shadowColor:
                          TenantColors.primaryGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Decorative water bubble
          Positioned(
            right: 0,
            top: 140,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5FE),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue, size: 14),
                  SizedBox(width: 4),
                  Icon(Icons.add, color: Colors.blue, size: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _costRow(IconData icon, Color bgColor, Color iconColor, String title,
      String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration:
              BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }

  // ── QUICK SERVICES ───────────────────────────────────────────────────────
  Widget _buildQuickServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dịch vụ nhanh',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildServiceItem('Hóa đơn', Icons.description_outlined,
                  TenantColors.primaryGreen,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TenantOrderPage()))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildServiceItem(
                  'Thanh toán QR', Icons.qr_code_outlined,
                  const Color(0xFF26A69A),
                  onTap: _openPayment),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildServiceItem(
                  'Báo hỏng', Icons.build_outlined,
                  TenantColors.warningAmber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildServiceItem(
                  'Hợp đồng', Icons.assignment_outlined,
                  const Color(0xFF5C6BC0),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TenantContractPage()))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(String title, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ── NOTIFICATIONS ────────────────────────────────────────────────────────
  Widget _buildNotifications() {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'Hóa đơn tháng 5 đã sẵn sàng',
        'sub': 'Vui lòng thanh toán trước ngày 10/06/2025',
        'time': '2 giờ trước',
        'icon': Icons.notifications_none_outlined,
        'iconColor': TenantColors.primaryGreen,
        'bgColor': TenantColors.bgMint,
        'unread': true,
      },
      {
        'title': 'Báo hỏng đã được tiếp nhận',
        'sub': 'Sự cố điện phòng 203 đang được xử lý',
        'time': '1 ngày trước',
        'icon': Icons.build_outlined,
        'iconColor': TenantColors.warningOrange,
        'bgColor': const Color(0xFFFFF3E0),
        'unread': true,
      },
      {
        'title': 'Thanh toán thành công',
        'sub': 'Hóa đơn tháng 4/2025 — 2.850.000 đ',
        'time': '3 ngày trước',
        'icon': Icons.check_circle_outline,
        'iconColor': TenantColors.primaryGreen,
        'bgColor': TenantColors.bgMint,
        'unread': false,
      },
      {
        'title': 'Hợp đồng sắp hết hạn',
        'sub': 'Hợp đồng phòng P203 hết hạn 30/08/2025',
        'time': '5 ngày trước',
        'icon': Icons.assignment_outlined,
        'iconColor': Colors.indigo,
        'bgColor': const Color(0xFFE8EAF6),
        'unread': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thông báo gần đây',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Tất cả >',
                style: TextStyle(
                    color: TenantColors.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: TenantColors.cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item['bgColor'],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'],
                        color: item['iconColor'], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['title'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item['unread'] == true) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: TenantColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['sub'],
                          style: const TextStyle(
                              fontSize: 12, color: TenantColors.textGrey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item['time'],
                    style: const TextStyle(fontSize: 11, color: Colors.black26),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'Trang chủ', Icons.home_outlined),
            _buildNavItem(1, 'Hóa đơn', Icons.description_outlined,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TenantOrderPage()))),
            _buildNavItem(2, 'Sửa chữa', Icons.build_outlined),
            _buildNavItem(3, 'Thông báo',
                Icons.notifications_none_outlined, hasBadge: true),
            _buildNavItem(4, 'Tài khoản', Icons.person_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon,
      {bool hasBadge = false, VoidCallback? onTap}) {
    final bool isActive = _currentIndex == index;
    return InkWell(
      onTap: onTap ??
          () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? TenantColors.bgMint : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon,
                    color: isActive
                        ? TenantColors.primaryGreen
                        : Colors.grey[400],
                    size: 24),
                if (hasBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? TenantColors.primaryGreen : Colors.grey[400],
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
