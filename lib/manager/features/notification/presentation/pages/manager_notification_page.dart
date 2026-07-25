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
  bool _isLoading = true;
  late TabController _tabController;
  final Set<String> _sendingNotificationIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
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
    final notifications = List<TenantNotification>.from(cached);

    try {
      final directExpiring = await _roomService.getExpiringContracts(maxDays: 30);
      for (final item in directExpiring) {
        final roomCode = item['roomCode'] ?? item['roomName'] ?? '';
        final days = item['remainingDays'] as int? ?? 0;
        final contractId = item['contractId'] ?? '';
        final type = days <= 7 ? 'contract_expiring_7d' : 'contract_expiring_30d';

        final exists = notifications.any((n) => n.body.contains(roomCode) || n.body.contains(contractId.toString()));
        if (!exists) {
          notifications.add(TenantNotification(
            id: 'direct_$contractId',
            title: days <= 7 ? 'Hợp đồng sắp hết hạn — còn $days ngày' : 'Hợp đồng sắp hết hạn',
            body: 'Phòng $roomCode: hợp đồng $contractId sẽ hết hạn sau $days ngày. Vui lòng liên hệ cư dân để gia hạn.',
            type: type,
            isRead: false,
            createdAt: DateTime.now(),
            userId: item['userId']?.toString(),
          ));
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _sendNotificationToTenant(TenantNotification item) async {
    final daysLeft = _parseDaysLeft(item.body) ?? 30;
    final roomMatch = RegExp(r'Phòng\s+([^\s:]+)').firstMatch(item.body);
    final roomCode = roomMatch != null ? roomMatch.group(1)! : 'Phòng';

    String? targetUserId = item.userId;

    setState(() => _sendingNotificationIds.add(item.id));

    if (targetUserId == null || targetUserId.isEmpty) {
      try {
        final directExpiring = await _roomService.getExpiringContracts(maxDays: 30);
        final match = directExpiring.firstWhere(
          (e) => (e['roomCode']?.toString().contains(roomCode) ?? false) || (e['roomName']?.toString().contains(roomCode) ?? false),
          orElse: () => {},
        );
        targetUserId = match['userId']?.toString();
      } catch (_) {}
    }

    if (targetUserId == null || targetUserId.isEmpty) {
      if (!mounted) return;
      setState(() => _sendingNotificationIds.remove(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy tài khoản cư dân để gửi thông báo!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await _roomService.sendExpiringContractNotification(
      targetUserId: targetUserId,
      roomCode: roomCode,
      remainingDays: daysLeft,
      contractId: item.id.startsWith('direct_') ? item.id.replaceFirst('direct_', '') : null,
    );

    if (!mounted) return;
    setState(() => _sendingNotificationIds.remove(item.id));

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Đã gửi thông báo gia hạn tới cư dân phòng $roomCode thành công!'),
          backgroundColor: ManagerColors.primaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi thông báo thất bại. Vui lòng thử lại sau.'),
          backgroundColor: Colors.red,
        ),
      );
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

  /// Lọc thông báo hợp đồng sắp hết hạn (30d + 7d)
  List<TenantNotification> get _expiringNotifications => _notifications
      .where((n) =>
          n.type == 'contract_expiring_30d' || n.type == 'contract_expiring_7d')
      .toList();

  /// Lọc thông báo thông thường (không phải sắp hết hạn)
  List<TenantNotification> get _generalNotifications => _notifications
      .where((n) =>
          n.type != 'contract_expiring_30d' && n.type != 'contract_expiring_7d')
      .toList();

  /// Trích xuất số ngày còn lại từ body message
  int? _parseDaysLeft(String body) {
    final regExp = RegExp(r'(\d+)\s*ngày');
    final match = regExp.firstMatch(body);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// Màu theo số ngày còn lại
  Color _daysColor(int? days) {
    if (days == null) return Colors.orange;
    if (days <= 7) return const Color(0xFFD32F2F);
    if (days <= 14) return const Color(0xFFE64A19);
    return const Color(0xFFF57C00);
  }

  /// Label urgency
  String _urgencyLabel(String type, int? days) {
    if (type == 'contract_expiring_7d' || (days != null && days <= 7)) {
      return 'Rất gấp';
    }
    if (days != null && days <= 14) return 'Gấp';
    return 'Sắp hết';
  }

  @override
  Widget build(BuildContext context) {
    final expiringCount = _expiringNotifications.where((n) => !n.isRead).length;

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
  Widget _buildExpiringContractsList() {
    final items = _expiringNotifications;

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
                    const SizedBox(height: 80),
                    // ── Minh hoạ trạng thái rỗng ──
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
                    _buildExpiringSummaryBanner(items),
                    const SizedBox(height: 16),

                    // ── Cards ────────────────────────────────────────
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildExpiringContractCard(item),
                        )),
                  ],
                ),
    );
  }

  Widget _buildExpiringSummaryBanner(List<TenantNotification> items) {
    final urgentCount =
        items.where((n) => n.type == 'contract_expiring_7d').length;
    final warningCount =
        items.where((n) => n.type == 'contract_expiring_30d').length;

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
                Wrap(
                  spacing: 8,
                  children: [
                    if (urgentCount > 0)
                      _buildSummaryChip(
                        '$urgentCount phòng ≤ 7 ngày',
                        const Color(0xFFD32F2F),
                        const Color(0xFFFFEBEE),
                      ),
                    if (warningCount > 0)
                      _buildSummaryChip(
                        '$warningCount phòng ≤ 30 ngày',
                        const Color(0xFFE64A19),
                        const Color(0xFFFFF3E0),
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

  Widget _buildExpiringContractCard(TenantNotification item) {
    final daysLeft = _parseDaysLeft(item.body);
    final daysColor = _daysColor(daysLeft);
    final urgencyLabel = _urgencyLabel(item.type, daysLeft);
    final isUrgent = item.type == 'contract_expiring_7d';

    // Trích tên phòng từ body (format: "Phòng PXXX:")
    String? roomName;
    final roomMatch = RegExp(r'Phòng\s+([^\s:]+)').firstMatch(item.body);
    if (roomMatch != null) roomName = 'Phòng ${roomMatch.group(1)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: daysColor.withOpacity(isUrgent ? 0.5 : 0.2),
          width: isUrgent ? 1.5 : 1,
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
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
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
                    isUrgent
                        ? Icons.local_fire_department_rounded
                        : Icons.access_time_rounded,
                    color: daysColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    roomName ?? item.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // ── Badge urgency ──────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    urgencyLabel,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
                  item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.body,
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),

                // ── Countdown badge ────────────────────────────────
                if (daysLeft != null)
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
                            border: Border.all(
                                color: daysColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.timer_outlined,
                                  color: daysColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Còn ',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: daysColor.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                '$daysLeft ngày',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: daysColor,
                                ),
                              ),
                              Text(
                                ' để gia hạn',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: daysColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendingNotificationIds.contains(item.id)
                        ? null
                        : () => _sendNotificationToTenant(item),
                    icon: _sendingNotificationIds.contains(item.id)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _sendingNotificationIds.contains(item.id)
                          ? 'Đang gửi thông báo...'
                          : 'Gửi thông báo gia hạn cho cư dân',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ManagerColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
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
}
