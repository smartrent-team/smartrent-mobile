import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/billing/data/tenant_invoice_service.dart';
import 'package:smartrent_mobile/tenant/features/billing/domain/models/tenant_invoice.dart';
import 'package:smartrent_mobile/tenant/features/billing/presentation/pages/order_page.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/tenant_payment_nav.dart';
import 'package:smartrent_mobile/tenant/features/contract/presentation/pages/contract_page.dart';
import 'package:smartrent_mobile/tenant/features/repair/presentation/pages/repair_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/tenant/features/home/data/services/home_service.dart';
import 'package:smartrent_mobile/tenant/core/widgets/tenant_notif_panel.dart';
import 'package:smartrent_mobile/tenant/features/notification/presentation/pages/tenant_notification_page.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/tenant/features/marketplace/presentation/pages/marketplace_page.dart';
import 'package:smartrent_mobile/tenant/features/home/presentation/pages/tenant_room_detail_page.dart';


class TenantHomePage extends StatefulWidget {
  const TenantHomePage({super.key, bool showBottomNav = false});

  @override
  State<TenantHomePage> createState() => _TenantHomePageState();
}

class _TenantHomePageState extends State<TenantHomePage> {
  final TenantInvoiceService _invoiceService = TenantInvoiceService();
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  final TokenService _tokenService = TokenService();

  bool _isBillExpanded = false;
  TenantInvoice? _unpaidInvoice;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUnpaidInvoice(),
      _loadData(),
    ]);
  }

  Future<void> _loadUnpaidInvoice() async {
    try {
      final res = await _invoiceService.getMyInvoices();
      if (res.statusCode == 200 && res.data['success'] == true) {
        final docs = (res.data['docs'] as List? ?? [])
            .map((e) => TenantInvoice.fromJson(e as Map<String, dynamic>))
            .toList();
        final unpaid = docs.where((i) => !i.isPaid).toList();
        if (mounted) {
          setState(() => _unpaidInvoice = unpaid.isNotEmpty ? unpaid.first : null);
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
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

  void _openRoomDetail() {
    final room = _profileData?['room'];
    if (room != null && room['id'] != null) {
      final int roomId = int.tryParse(room['id'].toString()) ?? 0;
      if (roomId > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TenantRoomDetailPage(roomId: roomId),
          ),
        );
      }
    }
  }

  final HomeService _homeService = HomeService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _errorMessage;

  Future<void> _handleSessionExpired() async {
    await _tokenService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _homeService.getTenantProfile();
      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _profileData = response.data['data'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.data?['error'] ?? 'Không thể tải dữ liệu';
          });
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi kết nối: ${e.toString()}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi kết nối: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        onRefresh: _loadAllData,
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
                            onPressed: _loadAllData,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketplacePage()),
          );
        },
        backgroundColor: TenantColors.primaryGreen,
        elevation: 8,
        shape: const CircleBorder(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 42,
            ),
            Positioned(
              top: 7,
              child: const Icon(
                Icons.storefront_rounded,
                color: TenantColors.primaryGreen,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: null,
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
                          _buildHeaderChip(roomCode, onTap: room != null ? _openRoomDetail : null),
                          const SizedBox(width: 8),
                          _buildHeaderChip(floor, onTap: room != null ? _openRoomDetail : null),
                        ],
                      ),
                    ],
                  ),
                  const TenantNotifBell(),
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

  Widget _buildHeaderChip(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  // ── CONTRACT CARD ────────────────────────────────────────────────────────
  Widget _buildContractCard() {
    final activeContract = _profileData?['active_contract'] as Map<String, dynamic>?;
    final contracts = (_profileData?['contracts'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];
    final contractForDisplay = activeContract ?? (contracts.isNotEmpty ? contracts.first : null);
    String remainingDays = '-- ngày';
    if (contractForDisplay != null && contractForDisplay['end_date'] != null) {
      try {
        final endDate = DateTime.parse(contractForDisplay['end_date'].toString());
        final now = DateTime.now();
        final diffMs = endDate.difference(now).inMilliseconds;
        final difference = diffMs > 0 ? (diffMs / (1000 * 60 * 60 * 24)).ceil() : 0;
        remainingDays = difference > 0 ? '$difference ngày' : 'Hết hạn';
      } catch (e) {
        remainingDays = 'Lỗi ngày';
      }
    } else if (contractForDisplay != null) {
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
          Expanded(
            child: GestureDetector(
              onTap: room != null ? _openRoomDetail : null,
              child: _buildContractCol('Phòng', status),
            ),
          ),
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
    if (_unpaidInvoice == null) {
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
              'Bạn đã thanh toán tất cả hóa đơn.',
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

    final inv = _unpaidInvoice!;
    final isPaid = inv.isPaid;
    final total = inv.totalAmount.toDouble();
    
    final issued = DateTime.tryParse(inv.issuedAt ?? inv.createdAt ?? '');
    final monthStr = issued != null ? '${issued.month}/${issued.year}' : '--/--';
    final dueDateStr = issued != null 
        ? '10/${issued.month + 1 > 12 ? 1 : issued.month + 1}/${issued.month + 1 > 12 ? issued.year + 1 : issued.year}' 
        : '--/--/----';

    final roomCode = inv.roomCode ?? '--';
    final branchName = inv.branchName ?? 'Nhà trọ';

    final double roomPrice = inv.roomPrice.toDouble();
    final double electricCost = inv.electricCost.toDouble();
    final double waterCost = inv.waterCost.toDouble();
    final double serviceCost = inv.serviceCost.toDouble();
    const double internetCost = 0;

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
                            'Hóa đơn tháng $monthStr',
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
                  _currency.format(total),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
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
                          'Tiền phòng', _currency.format(roomPrice)),
                      const Divider(height: 24, color: Color(0xFFEAF5EF)),
                      _costRow(Icons.bolt_outlined,
                          const Color(0xFFFFF3E0), TenantColors.warningOrange,
                          'Tiền điện', _currency.format(electricCost)),
                      const Divider(height: 24, color: Color(0xFFEAF5EF)),
                      _costRow(Icons.water_drop_outlined,
                          const Color(0xFFE1F5FE), Colors.blue,
                          'Tiền nước', _currency.format(waterCost)),
                      if (_isBillExpanded) ...[
                        if (internetCost > 0) ...[
                          const Divider(height: 24, color: Color(0xFFEAF5EF)),
                          _costRow(Icons.wifi_outlined,
                              const Color(0xFFF3E5F5), Colors.purple,
                              'Internet', _currency.format(internetCost)),
                        ],
                        if (serviceCost > 0) ...[
                          const Divider(height: 24, color: Color(0xFFEAF5EF)),
                          _costRow(Icons.star_outline_rounded,
                              const Color(0xFFFCE4EC), Colors.pink,
                              'Phí dịch vụ', _currency.format(serviceCost)),
                        ],
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
                                : 'Xem thêm ▼',
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
              ],
            ),
          ),
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

  Widget _buildQuickServices() {
    final room = _profileData?['room'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dịch vụ nhanh',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildServiceItem('Hóa đơn', Icons.description_outlined,
                  TenantColors.primaryGreen,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TenantOrderPage()))),
              const SizedBox(width: 16),
              _buildServiceItem(
                  'Thanh toán QR', Icons.qr_code_outlined,
                  const Color(0xFF26A69A),
                  onTap: _openPayment),
              const SizedBox(width: 16),
              _buildServiceItem(
                  'Báo hỏng', Icons.build_outlined,
                  TenantColors.warningAmber,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RepairPage()))),
              const SizedBox(width: 16),
              _buildServiceItem(
                  'Hợp đồng', Icons.assignment_outlined,
                  const Color(0xFF5C6BC0),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TenantContractPage()))),
              if (room != null) ...[
                const SizedBox(width: 16),
                _buildServiceItem(
                    'Phòng ở', Icons.meeting_room_outlined,
                    const Color(0xFF8D6E63),
                    onTap: _openRoomDetail),
              ],
            ],
          ),
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

  Widget _buildNotifications() {
    final List tickets = _profileData?['maintenance_tickets'] ?? [];
    final List invoices = _profileData?['recent_invoices'] ?? [];

    final List<Map<String, dynamic>> items = [];

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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TenantNotificationPage(),
                  ),
                );
              },
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
                      color: item['bgColor'] ?? Colors.transparent,
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
                                item['title'] ?? '',
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
                          item['sub'] ?? '',
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
                    item['time'] ?? '',
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
}
