import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/core/services/deep_link_service.dart';
import 'package:smartrent_mobile/tenant/core/state/tenant_notification_state.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/notification/data/models/tenant_notification.dart';
import 'package:smartrent_mobile/tenant/features/notification/data/services/tenant_notification_service.dart';
import 'package:smartrent_mobile/tenant/features/notification/presentation/pages/tenant_notification_page.dart';

class TenantNotifPanel {
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'notifications',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 60,
              right: 12,
              left: 60,
              child: FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.08),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutCubic,
                  )),
                  child: _NotifPanelContent(
                    onClose: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotifPanelContent extends StatefulWidget {
  final VoidCallback onClose;

  const _NotifPanelContent({
    required this.onClose,
  });

  @override
  State<_NotifPanelContent> createState() => _NotifPanelContentState();
}

class _NotifPanelContentState extends State<_NotifPanelContent> {
  final TenantNotificationService _service = TenantNotificationService.instance;
  List<TenantNotification> _remoteItems = const [];
  List<TenantNotifItem> _localItems = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _localItems = List<TenantNotifItem>.of(TenantNotifStore.items);
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _service.fetchNotifications(forceRemote: true);
    await _service.markAllAsRead();

    if (!mounted) return;
    setState(() {
      _remoteItems = items;
      _isLoading = false;
    });
  }

  void _openAllNotifications() {
    widget.onClose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      Navigator.of(context).push(
        AppPageRoutes.slide(const TenantNotificationPage(), name: 'tenant_notifications'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF0F0F0)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_rounded,
                    color: TenantColors.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thông báo',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _openAllNotifications,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 30),
                    ),
                    child: Text(
                      'Xem tất cả',
                      style: GoogleFonts.outfit(
                        color: TenantColors.primaryGreen,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onClose,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 30),
                    ),
                    child: Text(
                      'Đóng',
                      style: GoogleFonts.outfit(
                        color: TenantColors.primaryGreen,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: TenantColors.primaryGreen,
                        ),
                      ),
                    )
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final hasLocal = _localItems.isNotEmpty;
    final hasRemote = _remoteItems.isNotEmpty;

    if (!hasLocal && !hasRemote) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Chưa có thông báo nào.',
          style: GoogleFonts.outfit(
            color: TenantColors.textGrey,
            fontSize: 13,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (hasLocal) ...[
            _buildSectionTitle('AI dò đối chiếu gần đây'),
            ..._localItems.map(_buildLocalTile),
          ],
          if (hasRemote) ...[
            _buildSectionTitle('Thông báo hệ thống'),
            ..._remoteItems.map(_buildRemoteTile),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: TenantColors.textGrey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocalTile(TenantNotifItem n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: n.bg,
              shape: BoxShape.circle,
            ),
            child: Icon(n.icon, color: n.iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (n.unread)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          color: TenantColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  n.body,
                  style: GoogleFonts.outfit(
                    color: TenantColors.textGrey,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  n.time,
                  style: GoogleFonts.outfit(
                    color: Colors.black26,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteTile(TenantNotification n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: n.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(n.icon, color: n.iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!n.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          color: TenantColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  n.body,
                  style: GoogleFonts.outfit(
                    color: TenantColors.textGrey,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  n.timeLabel,
                  style: GoogleFonts.outfit(
                    color: Colors.black26,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TenantNotifBell extends StatelessWidget {
  const TenantNotifBell({super.key});

  void _openNotificationsPage(BuildContext context) {
    Navigator.of(context).push(
      AppPageRoutes.slide(const TenantNotificationPage(), name: 'tenant_notifications'),
    );
  }

  @override
  Widget build(BuildContext context) {
    TenantNotificationNotifier? notifier;
    try {
      notifier = TenantNotificationScope.of(context);
    } catch (_) {}

    return ValueListenableBuilder<int>(
      valueListenable: notifier ?? TenantNotificationNotifier(),
      builder: (ctx, count, _) {
        return GestureDetector(
          onTap: () => _openNotificationsPage(ctx),
          onLongPress: () => TenantNotifPanel.show(ctx),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class TenantNotifItem {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String body;
  final String time;
  final bool unread;

  const TenantNotifItem({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });
}

class _TenantNotifStore {
  static List<TenantNotifItem> items = [];

  static void update(List<TenantNotifItem> newItems) {
    items = newItems;
  }
}

abstract class TenantNotifStore {
  static void update(List<TenantNotifItem> items) =>
      _TenantNotifStore.update(items);

  static List<TenantNotifItem> get items => _TenantNotifStore.items;
}
