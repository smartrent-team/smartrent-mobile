import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/notification/data/services/manager_notification_service.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/tenant/features/notification/data/models/tenant_notification.dart';

class ManagerNotificationPage extends StatefulWidget {
  const ManagerNotificationPage({super.key});

  @override
  State<ManagerNotificationPage> createState() => _ManagerNotificationPageState();
}

class _ManagerNotificationPageState extends State<ManagerNotificationPage>
    with SingleTickerProviderStateMixin {
  final ManagerNotificationService _service = ManagerNotificationService.instance;
  final RoomService _roomService = RoomService();
  List<TenantNotification> _notifications = const [];
  // Danh sách hợp đồng sắp hết hạn lấy trực tiếp từ API (≤ 7 ngày, ≥ 0 ngày)
  List<Map<String, dynamic>> _expiringContracts = const [];
  bool _isLoading = true;
  bool _isLoadingExpiring = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
    _loadExpiringContracts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    await _service.fetchNotifications(forceRemote: true);
    final cached = await _service.getCachedNotifications();

    if (!mounted) return;
    setState(() {
      _notifications = List<TenantNotification>.from(cached);
      _isLoading = false;
    });
  }

  /// Lấy trực tiếp từ API hợp đồng sắp hết hạn ≤ 7 ngày, ẩn card âm ngày
  Future<void> _loadExpiringContracts() async {
    if (mounted) setState(() => _isLoadingExpiring = true);
    try {
      final raw = await _roomService.getExpiringContracts(maxDays: 7);
      // Chỉ hiển thị card có remainingDays >= 0
      final filtered = raw
          .where((e) => (e['remainingDays'] as num? ?? 0) >= 0)
          .toList();
      if (mounted) {
        setState(() {
          _expiringContracts = filtered;
          _isLoadingExpiring = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingExpiring = false);
    }
  }

  Future<void> _markAllAsRead() async {
    await _service.markAllAsRead();
    if (!mounted) return;
    setState(() {
      _notifications = _notifications
          .map((item) => TenantNotification(
                id: item.id,
                title: item.title,
                body: item.body,
                type: item.type,
                isRead: true,
                createdAt: item.createdAt,
                userId: item.userId,
              ))
          .toList();
    });
  }

  /// Lọc thông báo thông thường (bỏ qua loại expiring cũ nếu còn sót)
  List<TenantNotification> get _generalNotifications =>
      _notifications
          .where((n) =>
              n.type != 'contract_expiring_30d' && n.type != 'contract_expiring_7d')
          .toList();

  /// Màu theo số ngày còn lại
  Color _daysColor(int days) {
    if (days <= 1) return const Color(0xFFD32F2F);
    if (days <= 3) return const Color(0xFFE64A19);
    return const Color(0xFFF57C00);
  }

  @override
  Widget build(BuildContext context) {
    // Badge count = số phòng lấy thẳng từ API (≤ 7 ngày, ≥ 0 ngày)
    final expiringCount = _expiringContracts.length;

    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1F8A52),
                    ManagerColors.primaryGreen,
                    Color(0xFF6BCB86),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Thông báo',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _markAllAsRead,
                        child: const Text(
                          'Đánh dấu tất cả',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ── Tabs ──────────────────────────────────────────────
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    unselectedLabelStyle:
                        GoogleFonts.outfit(fontSize: 14),
                    tabs: [
                      const Tab(text: 'Tất cả'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Sắp hết hạn HĐ'),
                            if (expiringCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5252),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$expiringCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tab content ─────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: Tất cả thông báo
                  _buildNotificationList(_generalNotifications),

                  // Tab 1: Phòng sắp hết hạn hợp đồng
                  _buildExpiringContractsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 0: Danh sách thông báo thông thường ────────────────────────────
  Widget _buildNotificationList(List<TenantNotification> items) {
    return RefreshIndicator(
      color: ManagerColors.primaryGreen,
      onRefresh: _loadNotifications,
      child: _isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 220),
                Center(
                  child: CircularProgressIndicator(
                    color: ManagerColors.primaryGreen,
                  ),
                ),
              ],
            )
          : items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Icon(Icons.notifications_none_rounded,
                        size: 72, color: Colors.grey[350]),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có thông báo nào',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 16, color: ManagerColors.textGrey),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildGeneralNotifCard(items[index]);
                  },
                ),
    );
  }

  Widget _buildGeneralNotifCard(TenantNotification item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: item.isRead
            ? null
            : Border.all(
                color: ManagerColors.primaryGreen.withOpacity(0.25)),
        boxShadow: const [
          BoxShadow(
            color: ManagerColors.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
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
                        item.title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ManagerColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.body,
                  style: GoogleFonts.outfit(
                      color: ManagerColors.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  item.timeLabel,
                  style: GoogleFonts.outfit(
                      color: Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Phòng sắp hết hạn hợp đồng ──────────────────────────────────
  // Lấy trực tiếp từ API, KHÔNG dùng notification table
  Widget _buildExpiringContractsList() {
    return RefreshIndicator(
      color: ManagerColors.primaryGreen,
      onRefresh: _loadExpiringContracts,
      child: _isLoadingExpiring
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 220),
                Center(
                  child: CircularProgressIndicator(
                    color: ManagerColors.primaryGreen,
                  ),
                ),
              ],
            )
          : _expiringContracts.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 64, color: Color(0xFF2D9D5E)),
                          const SizedBox(height: 16),
                          Text(
                            'Không có phòng\nnào sắp hết hạn',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tất cả hợp đồng đang trong trạng thái tốt.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                                fontSize: 13, color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // ── Summary banner ───────────────────────────────
                    _buildDirectExpiringSummaryBanner(),
                    const SizedBox(height: 16),

                    // ── Cards ────────────────────────────────────────
                    ..._expiringContracts.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildDirectExpiringCard(item),
                        )),
                  ],
                ),
    );
  }

  Widget _buildDirectExpiringSummaryBanner() {
    final count = _expiringContracts.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFEBEE)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCCBC), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFE64A19), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảnh báo hợp đồng sắp hết hạn',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFFBF360C),
                  ),
                ),
                const SizedBox(height: 4),
                _buildSummaryChip(
                  '$count phòng ≤ 7 ngày',
                  const Color(0xFFD32F2F),
                  const Color(0xFFFFEBEE),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Card dùng dữ liệu trực tiếp từ API /api/contracts/expiring
  Widget _buildDirectExpiringCard(Map<String, dynamic> item) {
    final days = (item['remainingDays'] as num? ?? 0).toInt();
    final daysColor = _daysColor(days);
    final roomCode = item['roomCode']?.toString() ?? 'Phòng';
    final contractId = item['contractId']?.toString() ?? '';
    final endDate = item['endDate']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: daysColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: daysColor.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header strip ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: daysColor.withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: daysColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: daysColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Phòng $roomCode',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hợp đồng cư dân sắp hết hạn',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng $roomCode: hợp đồng $contractId${endDate.isNotEmpty ? ' — hạn $endDate' : ''}.',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),

                // ── Countdown badge ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              daysColor.withOpacity(0.12),
                              daysColor.withOpacity(0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: daysColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_outlined,
                                color: daysColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Hạn còn ',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: daysColor.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              '$days ngày',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: daysColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
