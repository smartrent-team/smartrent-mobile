import 'package:flutter/material.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/billing/presentation/pages/order_page.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/pages/payment_qr_page.dart';
import 'package:smartrent_mobile/tenant/features/contract/presentation/pages/contract_page.dart';
import 'package:smartrent_mobile/tenant/features/repair/presentation/pages/repair_page.dart';
import 'package:smartrent_mobile/tenant/features/profile/presentation/pages/profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/tenant/features/home/data/services/home_service.dart';

class TenantHomePage extends StatefulWidget {
  final bool showBottomNav;
  const TenantHomePage({super.key, this.showBottomNav = true});

  @override
  State<TenantHomePage> createState() => _TenantHomePageState();
}

class _TenantHomePageState extends State<TenantHomePage> {
  int _currentIndex = 0;
  bool _isBillExpanded = false;

  final HomeService _homeService = HomeService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _homeService.getTenantProfile();
      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _profileData = response.data['data'];
        });
      } else {
        setState(() {
          _errorMessage = response.data?['error'] ?? 'Không thể tải dữ liệu';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatMoney(dynamic amount) {
    if (amount == null) return '0 đ';
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    if (amount is String) {
      amount = double.tryParse(amount) ?? 0;
    }
    return formatter.format(amount).replaceAll('₫', 'đ').replaceAll(',00', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TenantColors.bgLightGreen,
      body: RefreshIndicator(
        color: TenantColors.primaryGreen,
        onRefresh: _loadData,
        child: _isLoading && _profileData == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: TenantColors.primaryGreen,
                ),
              )
            : _errorMessage != null && _profileData == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: TenantColors.errorRed,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: TenantColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TenantColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
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
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final String fullName = _profileData?['full_name'] ?? 'Khách thuê';
    final room = _profileData?['room'];
    final String roomCode = room != null ? 'Phòng ${room['room_code']}' : 'Chưa có phòng';
    final String floor = room != null ? 'Tầng ${room['floor']}' : 'Tầng --';

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
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildHeaderChip(roomCode),
                          const SizedBox(width: 8),
                          _buildHeaderChip(floor),
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
    final activeContract = _profileData?['active_contract'];
    String remainingDays = '-- ngày';
    if (activeContract != null && activeContract['end_date'] != null) {
      try {
        final endDate = DateTime.parse(activeContract['end_date']);
        final now = DateTime.now();
        final difference = endDate.difference(now).inDays;
        remainingDays = difference > 0 ? '$difference ngày' : 'Hết hạn';
      } catch (e) {
        remainingDays = 'Lỗi ngày';
      }
    } else if (activeContract != null) {
      remainingDays = 'Vô thời hạn';
    }

    final now = DateTime.now();
    final String currentMonth = 'T${now.month}/${now.year}';
    final room = _profileData?['room'];
    final String status = room != null ? 'Hoạt động' : 'Trống';

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
          Expanded(child: _buildContractCol('Hợp đồng còn', remainingDays)),
          Container(width: 1, height: 28, color: Colors.white24),
          Expanded(child: _buildContractCol('Tháng hiện tại', currentMonth)),
          Container(width: 1, height: 28, color: Colors.white24),
          Expanded(child: _buildContractCol('Phòng', status)),
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
    final List invoices = _profileData?['recent_invoices'] ?? [];
    if (invoices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: TenantColors.bgMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: TenantColors.primaryGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tất cả đã thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tuyệt vời! Bạn không có hóa đơn nào cần thanh toán.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: TenantColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    // Find the latest invoice (e.g. unpaid first, or just the first in list)
    final Map<String, dynamic> invoice = invoices.firstWhere(
        (inv) => inv['payment_status'] == 'unpaid',
        orElse: () => invoices.first) as Map<String, dynamic>;

    final isPaid = invoice['payment_status'] == 'paid';
    final total = (invoice['total_amount'] ?? 0).toDouble();

    String billTitle = 'Hóa đơn';
    String dueDateStr = 'Chờ cập nhật';
    if (invoice['issued_at'] != null) {
      try {
        final issuedAt = DateTime.parse(invoice['issued_at']);
        billTitle = 'Hóa đơn tháng ${issuedAt.month}/${issuedAt.year}';
        
        // Calculate due date (e.g. 10th of that month)
        final dueDate = DateTime(issuedAt.year, issuedAt.month, 10);
        dueDateStr = DateFormat('dd/MM/yyyy').format(dueDate);
      } catch (e) {
        // Fallback
      }
    }

    final room = _profileData?['room'];
    final String roomCode = room?['room_code'] ?? '--';
    final String branchName = room?['branch_name'] ?? 'Nhà trọ';

    // Breakdown values with fallbacks
    final double roomPrice = (invoice['room_price'] ?? room?['base_price'] ?? 2200000).toDouble();
    double electricCost = (invoice['electric_cost'] ?? 312000).toDouble();
    double waterCost = (invoice['water_cost'] ?? 78000).toDouble();
    double internetCost = (invoice['internet_cost'] ?? 120000).toDouble();
    double serviceCost = (invoice['service_cost'] ?? 140000).toDouble();

    // Proportional adjustment if breakdown fields are missing/null and total differs from the default sum
    final double defaultSum = roomPrice + electricCost + waterCost + internetCost + serviceCost;
    if (invoice['electric_cost'] == null && total != defaultSum) {
      final double diff = total - roomPrice;
      if (diff > 0) {
        final double scale = diff / (312000 + 78000 + 120000 + 140000);
        electricCost = (312000 * scale).roundToDouble();
        waterCost = (78000 * scale).roundToDouble();
        internetCost = (120000 * scale).roundToDouble();
        serviceCost = (140000 * scale).roundToDouble();
      } else {
        electricCost = 0;
        waterCost = 0;
        internetCost = 0;
        serviceCost = 0;
      }
    }

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            billTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Phòng $roomCode · $branchName',
                            style: const TextStyle(
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
                        color: isPaid ? TenantColors.bgMint : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid ? Icons.check_circle_outline_rounded : Icons.access_time,
                            color: isPaid ? TenantColors.primaryGreen : const Color(0xFFE65100),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPaid ? 'Đã thanh toán' : 'Chờ thanh toán',
                            style: TextStyle(
                              color: isPaid ? TenantColors.primaryGreen : const Color(0xFFE65100),
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
                Text(
                  _formatMoney(total),
                  style: const TextStyle(
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
                          'Tiền phòng', _formatMoney(roomPrice)),
                      const Divider(height: 24, color: Color(0xFFEAF5EF)),
                      _costRow(Icons.bolt_outlined,
                          const Color(0xFFFFF3E0), TenantColors.warningOrange,
                          'Tiền điện', _formatMoney(electricCost)),
                      const Divider(height: 24, color: Color(0xFFEAF5EF)),
                      _costRow(Icons.water_drop_outlined,
                          const Color(0xFFE1F5FE), Colors.blue,
                          'Tiền nước', _formatMoney(waterCost)),
                      if (_isBillExpanded) ...[
                        const Divider(height: 24, color: Color(0xFFEAF5EF)),
                        _costRow(Icons.wifi_outlined,
                            const Color(0xFFF3E5F5), Colors.purple,
                            'Internet', _formatMoney(internetCost)),
                        const Divider(height: 24, color: Color(0xFFEAF5EF)),
                        _costRow(Icons.star_outline_rounded,
                            const Color(0xFFFCE4EC), Colors.pink,
                            'Phí dịch vụ', _formatMoney(serviceCost)),
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
                Row(
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                      color: isPaid ? TenantColors.primaryGreen : TenantColors.errorRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPaid ? 'Đã đóng tiền ngày: ' : 'Hạn thanh toán: ',
                      style: const TextStyle(
                          fontSize: 13, color: TenantColors.textGrey),
                    ),
                    Text(
                      dueDateStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? TenantColors.primaryGreen : TenantColors.errorRed,
                      ),
                    ),
                  ],
                ),
                if (!isPaid) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TenantPaymentQRPage(
                              amount: total,
                              invoiceCode: invoice['invoice_code'],
                              bankContent: 'Thue phong $roomCode ${invoice['invoice_code']}',
                            )),
                      ),
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
                  onTap: () {
                    final List invoices = _profileData?['recent_invoices'] ?? [];
                    final Map<String, dynamic>? invoice = invoices.isNotEmpty
                        ? (invoices.firstWhere((inv) => inv['payment_status'] == 'unpaid', orElse: () => invoices.first) as Map<String, dynamic>)
                        : null;
                    Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => TenantPaymentQRPage(
                            amount: invoice != null ? (invoice['total_amount'] ?? 0).toDouble() : 0.0,
                            invoiceCode: invoice?['invoice_code'],
                            bankContent: invoice != null ? 'Thue phong ${_profileData?['room']?['room_code'] ?? ''} ${invoice['invoice_code']}' : null,
                          )));
                  }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildServiceItem(
                  'Báo hỏng', Icons.build_outlined,
                  TenantColors.warningAmber,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RepairPage()))),
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
    final List tickets = _profileData?['maintenance_tickets'] ?? [];
    final List invoices = _profileData?['recent_invoices'] ?? [];

    final List<Map<String, dynamic>> items = [];

    // Map invoices to notifications
    for (final inv in invoices) {
      final isPaid = inv['payment_status'] == 'paid';
      String timeLabel = 'Gần đây';
      if (inv['issued_at'] != null) {
        try {
          final date = DateTime.parse(inv['issued_at']);
          final diff = DateTime.now().difference(date).inDays;
          if (diff == 0) {
            timeLabel = 'Hôm nay';
          } else if (diff == 1) {
            timeLabel = '1 ngày trước';
          } else {
            timeLabel = '$diff ngày trước';
          }
        } catch (e) {}
      }

      if (!isPaid) {
        items.add({
          'title': 'Hóa đơn chưa thanh toán',
          'sub': 'Mã ${inv['invoice_code']} — Số tiền: ${_formatMoney(inv['total_amount'])}',
          'time': timeLabel,
          'icon': Icons.notifications_none_outlined,
          'iconColor': TenantColors.primaryGreen,
          'bgColor': TenantColors.bgMint,
          'unread': true,
        });
      } else {
        items.add({
          'title': 'Thanh toán thành công',
          'sub': 'Mã ${inv['invoice_code']} — Số tiền: ${_formatMoney(inv['total_amount'])}',
          'time': timeLabel,
          'icon': Icons.check_circle_outline,
          'iconColor': TenantColors.primaryGreen,
          'bgColor': TenantColors.bgMint,
          'unread': false,
        });
      }
    }

    // Map tickets to notifications
    for (final ticket in tickets) {
      String timeLabel = 'Gần đây';
      if (ticket['created_at'] != null) {
        try {
          final date = DateTime.parse(ticket['created_at']);
          final diff = DateTime.now().difference(date).inDays;
          if (diff == 0) {
            timeLabel = 'Hôm nay';
          } else if (diff == 1) {
            timeLabel = '1 ngày trước';
          } else {
            timeLabel = '$diff ngày trước';
          }
        } catch (e) {}
      }

      final String status = ticket['status'] ?? 'pending';
      String statusText = 'Tiếp nhận';
      Color color = TenantColors.primaryGreen;
      Color bgColor = TenantColors.bgMint;
      if (status == 'in-progress') {
        statusText = 'Đang xử lý';
        color = TenantColors.warningOrange;
        bgColor = const Color(0xFFFFF3E0);
      } else if (status == 'resolved') {
        statusText = 'Đã hoàn thành';
        color = Colors.blue;
        bgColor = const Color(0xFFE1F5FE);
      }

      items.add({
        'title': 'Sự cố: ${ticket['title']}',
        'sub': 'Trạng thái: $statusText (Mức ưu tiên: ${ticket['priority']})',
        'time': timeLabel,
        'icon': Icons.build_outlined,
        'iconColor': color,
        'bgColor': bgColor,
        'unread': status == 'pending',
      });
    }

    // Fallback to static notifications if list is empty
    if (items.isEmpty) {
      items.addAll([
        {
          'title': 'Chào mừng thành viên mới',
          'sub': 'Chào mừng bạn đến với hệ thống quản lý nhà trọ SmartRent!',
          'time': 'Vừa xong',
          'icon': Icons.celebration_outlined,
          'iconColor': TenantColors.primaryGreen,
          'bgColor': TenantColors.bgMint,
          'unread': true,
        },
        {
          'title': 'Thông tin hệ thống',
          'sub': 'Liên hệ quản lý nếu bạn cần hỗ trợ các dịch vụ lưu trú.',
          'time': '1 ngày trước',
          'icon': Icons.info_outline_rounded,
          'iconColor': Colors.indigo,
          'bgColor': const Color(0xFFE8EAF6),
          'unread': false,
        }
      ]);
    }

    // Limit to 4 items
    final displayItems = items.take(4).toList();

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
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];
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
            _buildNavItem(2, 'Sửa chữa', Icons.build_outlined,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RepairPage()))),
            _buildNavItem(3, 'Thông báo',
                Icons.notifications_none_outlined, hasBadge: true),
            _buildNavItem(4, 'Tài khoản', Icons.person_outline_rounded,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()))),
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
