import 'dart:async';
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
import 'package:smartrent_mobile/manager/features/dashboard/data/dashboard_service.dart';
import 'package:smartrent_mobile/manager/features/issue/data/models/ticket_model.dart';
import 'package:smartrent_mobile/manager/features/issue/data/services/ticket_service.dart';
import 'package:smartrent_mobile/manager/features/issue/presentation/pages/issue_detail_page.dart';
import 'package:smartrent_mobile/manager/features/notification/data/services/manager_notification_service.dart';
import 'package:smartrent_mobile/manager/features/notification/presentation/pages/manager_notification_page.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';
import 'package:smartrent_mobile/tenant/features/notification/data/models/tenant_notification.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';

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
  final DashboardService _dashboardService = DashboardService();
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
  List<TenantNotification> _expiringContracts = [];

  double _occupancyRate = 0;
  double _electricRate = 0;
  double _waterRate = 0;

  late final StreamSubscription<AppEvent> _eventSub;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _eventSub = AppEventBus.instance.onAny((_) {
      if (mounted) _loadDashboard();
    });
  }

  @override
  void dispose() {
    _eventSub.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1 request thay vì 5 — tránh connection reset qua ngrok
      final summaryRes = await _dashboardService.getSummary();

      if (summaryRes.statusCode == 200 && summaryRes.data['success'] == true) {
        final data = summaryRes.data['data'] as Map<String, dynamic>;

        // Wrap từng phần vào fake response object cho các _apply* method dùng lại
        _applyRooms(_FakeResponse(200, {'success': true, ...data['rooms'] as Map<String, dynamic>}));
        _applyTenants(_FakeResponse(200, {'success': true, ...data['tenants'] as Map<String, dynamic>}));
        _applyInvoices(_FakeResponse(200, {'success': true, ...data['invoices'] as Map<String, dynamic>}));
        _applyTickets(_FakeResponse(200, {'success': true, ...data['tickets'] as Map<String, dynamic>}));
        _applyUtilities(_FakeResponse(200, {'success': true, ...data['utilities'] as Map<String, dynamic>}));
      }

      // Load thông báo hợp đồng sắp hết hạn từ notification service
      await _loadExpiringContracts();

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

  Future<void> _loadExpiringContracts() async {
    try {
      final notifications = await ManagerNotificationService.instance
          .fetchNotifications(forceRemote: true);
      var expiring = notifications
          .where((n) =>
              n.type == 'contract_expiring_30d' ||
              n.type == 'contract_expiring_7d')
          .toList();

      // Cũng query trực tiếp từ hợp đồng active của các phòng để đề phòng Cron Job chưa chạy
      final directExpiring = await _roomService.getExpiringContracts(maxDays: 30);
      for (final item in directExpiring) {
        final roomCode = item['roomCode'] ?? item['roomName'] ?? '';
        final days = item['remainingDays'] as int? ?? 0;
        final contractId = item['contractId'] ?? '';
        final type = days <= 7 ? 'contract_expiring_7d' : 'contract_expiring_30d';

        // Check xem đã có trong list notification chưa
        final exists = expiring.any((n) => n.body.contains(roomCode) || n.body.contains(contractId.toString()));
        if (!exists) {
          expiring.add(TenantNotification(
            id: 'direct_$contractId',
            title: days <= 7 ? 'Hợp đồng sắp hết hạn — còn $days ngày' : 'Hợp đồng sắp hết hạn',
            body: 'Phòng $roomCode: hợp đồng $contractId sẽ hết hạn sau $days ngày. Vui lòng liên hệ cư dân để gia hạn.',
            type: type,
            isRead: false,
            createdAt: DateTime.now(),
          ));
        }
      }

      if (mounted) {
        setState(() => _expiringContracts = expiring);
      }
    } catch (_) {
      // silent fail — dashboard vẫn hoạt động
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
                          _buildActionCard(
                            'Tạo hóa đơn',
                            'Xác nhận & tạo hóa đơn mới',
                            Icons.request_quote_outlined,
                            ManagerColors.bgMint,
                            ManagerColors.primaryGreen,
                            onTap: () => context.pushModal(const InvoiceConfirmPage()),
                          ),
                          const SizedBox(height: 16),
                          _buildActionCard(
                            'Đổi mật khẩu',
                            'Cập nhật mật khẩu mới',
                            Icons.lock_reset_rounded,
                            const Color(0xFFF3E5F5),
                            Colors.purple,
                            onTap: () => context.pushSlide(const ChangePasswordPage()),
                          ),
                          // ── Cảnh báo hợp đồng sắp hết hạn ────────
                          if (_expiringContracts.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                              'Hợp đồng sắp hết hạn',
                              onSeeAll: () => Navigator.of(context).push(
                                AppPageRoutes.slide(
                                  const ManagerNotificationPage(),
                                  name: 'manager_notifications',
                                ),
                              ),
                            ),
                            _buildExpiringContractsBanner(context),
                          ],
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
      onTap: () => context.pushModal(const InvoiceConfirmPage()),
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

  // ── Banner hợp đồng sắp hết hạn trên Dashboard ──────────────────────────
  int? _parseDaysLeft(String body) {
    final regExp = RegExp(r'(\d+)\s*ngày');
    final match = regExp.firstMatch(body);
    if (match != null) return int.tryParse(match.group(1) ?? '');
    return null;
  }

  Widget _buildExpiringContractsBanner(BuildContext context) {
    final urgentItems = _expiringContracts
        .where((n) => n.type == 'contract_expiring_7d')
        .toList();
    final warningItems = _expiringContracts
        .where((n) => n.type == 'contract_expiring_30d')
        .toList();

    return InkWell(
      onTap: () => Navigator.of(context).push(
        AppPageRoutes.slide(
          const ManagerNotificationPage(),
          name: 'manager_notifications',
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFEDE0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFCCBC), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE64A19).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: Color(0xFFE64A19),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_expiringContracts.length} phòng cần gia hạn hợp đồng',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFFBF360C),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFE64A19)),
              ],
            ),
            const SizedBox(height: 12),
            // ── Chips tóm tắt ──────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (urgentItems.isNotEmpty)
                  _buildDashboardChip(
                    Icons.local_fire_department_rounded,
                    '${urgentItems.length} phòng ≤ 7 ngày',
                    const Color(0xFFD32F2F),
                    const Color(0xFFFFEBEE),
                  ),
                if (warningItems.isNotEmpty)
                  _buildDashboardChip(
                    Icons.access_time_rounded,
                    '${warningItems.length} phòng ≤ 30 ngày',
                    const Color(0xFFE64A19),
                    const Color(0xFFFFF3E0),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Preview danh sách phòng (tối đa 3) ─────────────────────
            ..._expiringContracts.take(3).map((item) {
              final daysLeft = _parseDaysLeft(item.body);
              final isUrgent = item.type == 'contract_expiring_7d';
              final color = isUrgent
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFFE64A19);
              final roomMatch =
                  RegExp(r'Phòng\s+([^\s:]+)').firstMatch(item.body);
              final roomName = roomMatch != null
                  ? 'Phòng ${roomMatch.group(1)}'
                  : 'Phòng';

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.meeting_room_outlined,
                        color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        roomName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (daysLeft != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Còn $daysLeft ngày',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            if (_expiringContracts.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${_expiringContracts.length - 3} phòng khác · Xem tất cả >',
                  style: const TextStyle(
                    color: Color(0xFFE64A19),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardChip(
      IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
                        ticket.roomName ?? 'Chưa xác định',
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
          ticket.roomName ?? 'Chưa xác định',
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

/// Wrapper nhẹ để tái sử dụng các _apply* method vốn nhận Dio Response.
/// Chỉ cần statusCode và data — không cần Dio dependency.
class _FakeResponse {
  final int statusCode;
  final Map<String, dynamic> data;
  const _FakeResponse(this.statusCode, this.data);
}
