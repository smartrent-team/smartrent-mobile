import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/core/state/tenant_notification_state.dart';

// ── MODEL ──────────────────────────────────────────────────────────────────────

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

// ── PANEL WIDGET ───────────────────────────────────────────────────────────────

/// Overlay notification panel dùng chung toàn tenant app.
/// Gọi [TenantNotifPanel.show(context)] để mở.
class TenantNotifPanel {
  static void show(BuildContext context) {
    // Lấy notifications từ scope
    TenantNotificationNotifier? notifier;
    try {
      notifier = TenantNotificationScope.of(context);
    } catch (_) {}

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
            // Backdrop tap-to-close (handled by barrierDismissible)
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
                      parent: anim, curve: Curves.easeOutCubic)),
                  child: _NotifPanelContent(
                    notifier: notifier,
                    onClose: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    // Reset badge
    notifier?.value = 0;
  }
}

class _NotifPanelContent extends StatefulWidget {
  final TenantNotificationNotifier? notifier;
  final VoidCallback onClose;

  const _NotifPanelContent({required this.notifier, required this.onClose});

  @override
  State<_NotifPanelContent> createState() => _NotifPanelContentState();
}

class _NotifPanelContentState extends State<_NotifPanelContent> {
  List<TenantNotifItem> _items = [];

  @override
  void initState() {
    super.initState();
    _items = _TenantNotifStore.items;
    widget.notifier?.addListener(_onCountChanged);
  }

  @override
  void dispose() {
    widget.notifier?.removeListener(_onCountChanged);
    super.dispose();
  }

  void _onCountChanged() => setState(() {
        _items = _TenantNotifStore.items;
      });

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
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded,
                      color: TenantColors.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Text('Thông báo',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onClose,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 30)),
                    child: Text('Đóng',
                        style: GoogleFonts.outfit(
                            color: TenantColors.primaryGreen,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
            // Items
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: _items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Chưa có thông báo nào.',
                          style: GoogleFonts.outfit(
                              color: TenantColors.textGrey,
                              fontSize: 13)),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: _items
                            .map((n) => _buildTile(n))
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(TenantNotifItem n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                BoxDecoration(color: n.bg, shape: BoxShape.circle),
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
                      child: Text(n.title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (n.unread)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                            color: TenantColors.primaryGreen,
                            shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(n.body,
                    style: GoogleFonts.outfit(
                        color: TenantColors.textGrey, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(n.time,
                    style: GoogleFonts.outfit(
                        color: Colors.black26, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── GLOBAL STORE ───────────────────────────────────────────────────────────────
// Giữ danh sách notifications mới nhất từ AI analysis để
// các screen khác có thể hiển thị mà không cần navigate.

class _TenantNotifStore {
  static List<TenantNotifItem> items = [];

  static void update(List<TenantNotifItem> newItems) {
    items = newItems;
  }
}

// Public accessor
abstract class TenantNotifStore {
  static void update(List<TenantNotifItem> items) =>
      _TenantNotifStore.update(items);
}

// ── BELL WIDGET ────────────────────────────────────────────────────────────────
/// Nút chuông thông báo dùng chung trên header các màn hình tenant.
/// Hiển thị badge số unread, tap mở panel overlay (không navigate).
class TenantNotifBell extends StatelessWidget {
  const TenantNotifBell({super.key});

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
          onTap: () => TenantNotifPanel.show(ctx),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 22),
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
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
