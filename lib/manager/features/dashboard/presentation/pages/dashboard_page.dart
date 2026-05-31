import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_nav.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_bottom_nav.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/change_password_page.dart';
import 'package:smartrent_mobile/manager/features/billing/data/invoice_model.dart';
import 'package:smartrent_mobile/manager/features/billing/data/invoice_service.dart';
import 'package:smartrent_mobile/manager/features/billing/data/utility_service.dart';
import 'package:smartrent_mobile/manager/features/billing/presentation/pages/invoice_confirm_page.dart';
import 'package:smartrent_mobile/manager/features/billing/presentation/pages/utility_input_page.dart';
import 'package:smartrent_mobile/manager/features/issue/data/models/ticket_model.dart';
import 'package:smartrent_mobile/manager/features/issue/data/services/ticket_service.dart';
import 'package:smartrent_mobile/manager/features/issue/presentation/pages/issue_detail_page.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';

class _UtilityAlertData {
  final String room;
  final String desc;
  final String tag;
  final Color color;
  final IconData icon;

  const _UtilityAlertData({
    required this.room,
    required this.desc,
    required this.tag,
    required this.color,
    required this.icon,
  });
}

class DashboardPage extends StatefulWidget {
  final bool embedInShell;
  final void Function({required int openTickets})? onShellStats;

  const DashboardPage({
    super.key,
    this.embedInShell = false,
    this.onShellStats,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final RoomService _roomService = RoomService();
  final TenantService _tenantService = TenantService();
  final InvoiceService _invoiceService = InvoiceService();
  final TicketService _ticketService = TicketService();
  final UtilityService _utilityService = UtilityService();
  bool _isLoading = true;
  String? _errorMessage;

  int _totalRooms = 0;
  int _occupiedRooms = 0;
  int _availableRooms = 0;
  int _totalTenants = 0;
  int _newTenantsThisMonth = 0;
  int _pendingInvoices = 0;
  num _pendingInvoiceAmount = 0;
  int _openTickets = 0;
  int _urgentTickets = 0;

  List<TicketModel> _recentTickets = [];
  TicketModel? _emergencyTicket;
  List<_UtilityAlertData> _utilityAlerts = [];

  double _occupancyRate = 0;
  double _electricRate = 0;
  double _waterRate = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait([
        _roomService.getRooms(limit: 100),
        _tenantService.getTenants(),
        _invoiceService.getInvoices(limit: 100),
        _ticketService.getTickets(),
        _utilityService.getLatestUtilities(),
      ]);

      _applyRooms(responses[0]);
      _applyTenants(responses[1]);
      _applyInvoices(responses[2]);
      _applyTickets(responses[3]);
      _applyUtilities(responses[4]);

      if (mounted) {
        setState(() => _isLoading = false);
        widget.onShellStats?.call(openTickets: _openTickets);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải dữ liệu dashboard. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyRooms(dynamic response) {
    if (response.statusCode != 200) return;
    final data = response.data;
    if (data['success'] != true) return;

    final docs = (data['docs'] as List<dynamic>?) ?? [];
    final totalFromApi = data['totalDocs'] as int?;
    var occupied = 0;
    var available = 0;

    for (final room in docs) {
      final status = room['status']?.toString() ?? '';
      if (status == 'occupied') {
        occupied++;
      } else if (status == 'available') {
        available++;
      }
    }

    final total = totalFromApi ?? docs.length;
    _totalRooms = total;
    _occupiedRooms = occupied;
    _availableRooms = available;
    _occupancyRate = total > 0 ? occupied / total : 0;
  }

  void _applyTenants(dynamic response) {
    if (response.statusCode != 200) return;
    final docs = (response.data['docs'] as List<dynamic>?) ?? [];
    final now = DateTime.now();
    var newThisMonth = 0;

    for (final tenant in docs) {
      final checkIn = tenant['checkInDate']?.toString();
      if (_isSameMonth(checkIn, now)) {
        newThisMonth++;
      }
    }

    _totalTenants = docs.length;
    _newTenantsThisMonth = newThisMonth;
  }

  bool _isSameMonth(String? dateStr, DateTime now) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        return date.year == now.year && date.month == now.month;
      }
      final parsed = DateTime.parse(dateStr);
      return parsed.year == now.year && parsed.month == now.month;
    } catch (_) {
      return false;
    }
  }

  void _applyInvoices(dynamic response) {
    if (response.statusCode != 200) return;
    final docs = (response.data['docs'] as List<dynamic>?) ?? [];
    final invoices = docs.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    final now = DateTime.now();

    var pendingCount = 0;
    num pendingAmount = 0;
    num totalElectricUsage = 0;
    num totalWaterUsage = 0;

    for (final invoice in invoices) {
      if (invoice.isUnpaid || invoice.paymentStatus == 'partial') {
        pendingCount++;
        pendingAmount += invoice.totalAmount;
      }

      final dateStr = invoice.issuedAt ?? invoice.createdAt;
      if (dateStr == null || !_isInvoiceInMonth(dateStr, now)) continue;

      if (invoice.electricNew != null && invoice.electricOld != null) {
        final usage = invoice.electricNew! - invoice.electricOld!;
        if (usage > 0) totalElectricUsage += usage;
      }
      if (invoice.waterNew != null && invoice.waterOld != null) {
        final usage = invoice.waterNew! - invoice.waterOld!;
        if (usage > 0) totalWaterUsage += usage;
      }
    }

    _pendingInvoices = pendingCount;
    _pendingInvoiceAmount = pendingAmount;

    if (_totalRooms > 0) {
      _electricRate = (totalElectricUsage / (_totalRooms * 200)).clamp(0.0, 1.0);
      _waterRate = (totalWaterUsage / (_totalRooms * 15)).clamp(0.0, 1.0);
    }
  }

  bool _isInvoiceInMonth(String dateStr, DateTime now) {
    try {
      final date = DateTime.parse(dateStr);
      return date.year == now.year && date.month == now.month;
    } catch (_) {
      return false;
    }
  }

  void _applyTickets(dynamic response) {
    if (response.statusCode != 200) return;
    final data = response.data;
    if (data['success'] != true) return;

    final tickets = ((data['data'] as List<dynamic>?) ?? [])
        .map((json) => TicketModel.fromJson(json as Map<String, dynamic>))
        .toList();

    tickets.sort((a, b) {
      final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
      final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    final openTickets = tickets.where((t) => t.isOpen).toList();
    _openTickets = openTickets.length;
    _urgentTickets = openTickets.where((t) => t.isUrgent).length;
    _recentTickets = tickets.take(4).toList();
    final urgentOpen = openTickets.where((t) => t.isUrgent).toList();
    _emergencyTicket = urgentOpen.isNotEmpty ? urgentOpen.first : null;
  }

  void _applyUtilities(dynamic response) {
    if (response.statusCode != 200) return;
    final data = response.data;
    if (data['success'] != true) return;

    final docs = (data['docs'] as List<dynamic>?) ?? [];
    final now = DateTime.now();
    final alerts = <_UtilityAlertData>[];
    var enteredThisMonth = 0;

    for (final doc in docs) {
      final lastMonth = doc['lastMonth'] as int?;
      final lastYear = doc['lastYear'] as int?;
      final roomName = doc['roomName']?.toString() ?? 'Phòng N/A';

      if (lastMonth == now.month && lastYear == now.year) {
        enteredThisMonth++;
      } else {
        alerts.add(_UtilityAlertData(
          room: roomName,
          desc: 'Chưa nhập chỉ số tháng ${now.month}/${now.year}',
          tag: 'Chờ nhập',
          color: Colors.orange,
          icon: Icons.bolt_outlined,
        ));
      }
    }

    if (docs.isNotEmpty) {
      _electricRate = (_electricRate + (enteredThisMonth / docs.length)) / 2;
      _waterRate = (_waterRate + (enteredThisMonth / docs.length)) / 2;
    }

    _utilityAlerts = alerts.take(2).toList();
  }

  String _formatCompactCurrency(num amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      final text = millions >= 10
          ? millions.toStringAsFixed(0)
          : millions.toStringAsFixed(1).replaceAll('.', ',');
      return '$text triệu đ';
    }
    final format = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$format đ';
  }

  String _formatPercent(double value) => '${(value * 100).toStringAsFixed(1)}%';

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays == 1) return 'Hôm qua';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _ticketStatusLabel(String? status) {
    switch (status) {
      case 'new':
      case 'pending':
        return 'Mở';
      case 'in_progress':
      case 'in-progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Xong';
      default:
        return 'Chờ xử lý';
    }
  }

  Color _ticketStatusColor(String? status) {
    switch (status) {
      case 'new':
      case 'pending':
        return Colors.red;
      case 'in_progress':
      case 'in-progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _priorityLabel(String? priority) {
    switch (priority) {
      case 'high':
        return 'Khẩn';
      case 'low':
        return 'Thấp';
      default:
        return 'Thường';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = 'Tháng ${now.month}/${now.year}';

    final scrollBody = RefreshIndicator(
              onRefresh: _loadDashboard,
              color: ManagerColors.primaryGreen,
              child: _isLoading && _totalRooms == 0 && _recentTickets.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: CircularProgressIndicator(
                            color: ManagerColors.primaryGreen,
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                              ),
                            ),
                          ],
                          _buildSummaryGrid(context),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Thao tác nhanh', showAction: false),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  'Tạo hóa đơn',
                                  'Xác nhận & tạo hóa đơn mới',
                                  Icons.request_quote_outlined,
                                  ManagerColors.bgMint,
                                  ManagerColors.primaryGreen,
                                  onTap: () => context.pushModal(const InvoiceConfirmPage()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildActionCard(
                                  'Nhập chỉ số',
                                  'Điện · nước cho phòng',
                                  Icons.timeline_rounded,
                                  const Color(0xFFFFF8E1),
                                  Colors.orange,
                                  onTap: () => context.pushModal(const UtilityInputPage()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  'Đổi mật khẩu',
                                  'Cập nhật mật khẩu mới',
                                  Icons.lock_reset_rounded,
                                  const Color(0xFFF3E5F5),
                                  Colors.purple,
                                  onTap: () => context.pushSlide(const ChangePasswordPage()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Spacer(),
                            ],
                          ),
                          if (_utilityAlerts.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSectionHeader('Cảnh báo điện - nước'),
                            for (final alert in _utilityAlerts) ...[
                              _buildUtilityAlert(
                                context,
                                alert.room,
                                alert.desc,
                                alert.tag,
                                alert.color,
                                alert.icon,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                          if (_emergencyTicket != null) ...[
                            const SizedBox(height: 24),
                            _buildEmergencyAlert(context, _emergencyTicket!),
                          ],
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            'Ticket sự cố gần đây',
                            onSeeAll: () => ManagerNav.openIssuePage(context),
                          ),
                          if (_recentTickets.isEmpty)
                            _buildEmptyCard('Chưa có ticket sự cố nào')
                          else
                            _buildTicketList(context),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Công suất sử dụng'),
                          _buildUtilizationCard(monthLabel),
                          const SizedBox(height: 24),
                          const Center(
                            child: Text(
                              '© 2025 RMS · Phiên bản 2.4.1',
                              style: TextStyle(fontSize: 12, color: Colors.black38),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            );

    if (widget.embedInShell) {
      return scrollBody;
    }

    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(
        children: [
          ManagerAppHeader(showNotificationDot: _openTickets > 0),
          Expanded(child: scrollBody),
        ],
      ),
      bottomNavigationBar: ManagerBottomNav(
        currentIndex: 4,
        onTap: (index) => ManagerNav.bottomNav(context, index, currentIndex: 4),
        issueBadgeCount: _openTickets,
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Text(message, style: const TextStyle(color: Colors.black45, fontSize: 14)),
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          '$_totalRooms',
          'Tổng phòng',
          '$_occupiedRooms đang thuê · $_availableRooms trống',
          Icons.home_work_outlined,
          Colors.green,
          onTap: () => ManagerNav.openRoomList(context),
        ),
        _buildStatCard(
          '$_totalTenants',
          'Cư dân',
          _newTenantsThisMonth > 0
              ? '$_newTenantsThisMonth mới tháng này'
              : 'Đang quản lý',
          Icons.people_alt_outlined,
          Colors.blue,
          onTap: () => ManagerNav.openTenantTab(context, 1),
        ),
        _buildStatCard(
          '$_pendingInvoices',
          'Hóa đơn chờ',
          _pendingInvoices > 0
              ? 'Tổng ${_formatCompactCurrency(_pendingInvoiceAmount)}'
              : 'Không có hóa đơn chờ',
          Icons.receipt_long_outlined,
          Colors.orange,
          onTap: () => ManagerNav.openTenantTab(context, 2),
        ),
        _buildStatCard(
          '$_openTickets',
          'Sự cố mở',
          _urgentTickets > 0 ? '$_urgentTickets khẩn cấp' : 'Không có khẩn cấp',
          Icons.report_gmailerrorred_rounded,
          Colors.red,
          onTap: () => ManagerNav.openIssuePage(context),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.black38),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: const [
            BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black38),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityAlert(
    BuildContext context,
    String room,
    String desc,
    String tag,
    Color color,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => context.pushModal(const UtilityInputPage()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          room,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black38)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyAlert(BuildContext context, TicketModel ticket) {
    final title = ticket.title ?? ticket.description ?? 'Sự cố khẩn cấp';
    return InkWell(
      onTap: () => context.pushSlide(IssueDetailPage(issue: ticket)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCCCC)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFFFE0E0), shape: BoxShape.circle),
              child: const Icon(Icons.local_fire_department, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ticket.roomName ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Khẩn',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showAction = true, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (showAction)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'Xem tất cả >',
                style: TextStyle(
                  color: ManagerColors.primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketList(BuildContext context) {
    return Column(
      children: _recentTickets.map((ticket) {
        final statusLabel = _ticketStatusLabel(ticket.status);
        final statusColor = _ticketStatusColor(ticket.status);
        final displayTitle = ticket.title ?? ticket.description ?? 'Không có mô tả';
        return _buildTicketCard(
          context,
          ticket,
          '#T-${ticket.id}',
          displayTitle,
          ticket.roomName ?? 'N/A',
          _timeAgo(ticket.createdAt),
          statusLabel,
          statusColor,
          _priorityLabel(ticket.priority),
        );
      }).toList(),
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    TicketModel ticket,
    String id,
    String title,
    String room,
    String time,
    String status,
    Color statusColor,
    String priorityLabel,
  ) {
    return InkWell(
      onTap: () => context.pushSlide(IssueDetailPage(issue: ticket)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.build_outlined, color: statusColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        id,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priorityLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('$room · $time', style: const TextStyle(color: Colors.black38, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilizationCard(String monthLabel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(monthLabel, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          _buildProgressItem(
            Icons.meeting_room_outlined,
            'Tỉ lệ lấp đầy phòng',
            _occupancyRate,
            _formatPercent(_occupancyRate),
            Colors.green,
          ),
          _buildProgressItem(
            Icons.bolt_outlined,
            'Điện tiêu thụ',
            _electricRate,
            _formatPercent(_electricRate),
            Colors.orange,
          ),
          _buildProgressItem(
            Icons.water_drop_outlined,
            'Nước tiêu thụ',
            _waterRate,
            _formatPercent(_waterRate),
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    IconData icon,
    String label,
    double value,
    String percent,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              const Spacer(),
              Text(percent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

}
