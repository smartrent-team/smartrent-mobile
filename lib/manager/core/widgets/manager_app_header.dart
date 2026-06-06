import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/manager/features/notification/presentation/pages/manager_notification_page.dart';

class ManagerHeaderDate {
  static String format([DateTime? date]) {
    return DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(date ?? DateTime.now());
  }
}

class ManagerAppHeader extends StatefulWidget {
  final bool showNotificationDot;
  final int unreadNotificationCount;
  final String? title;

  const ManagerAppHeader({
    super.key,
    this.showNotificationDot = true,
    this.unreadNotificationCount = 0,
    this.title,
  });

  static String formatPhoneDisplay(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final p = phone.trim();
    if (p.startsWith('+84')) return '0${p.substring(3)}';
    if (p.startsWith('84') && p.length > 9) return '0${p.substring(2)}';
    return p;
  }

  @override
  State<ManagerAppHeader> createState() => _ManagerAppHeaderState();
}

class _ManagerAppHeaderState extends State<ManagerAppHeader> {
  final TokenService _tokenService = TokenService();
  String _displayPhone = '';

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    final phone = await _tokenService.getPhone();
    if (!mounted) return;
    setState(() => _displayPhone = ManagerAppHeader.formatPhoneDisplay(phone));
  }

  Future<void> _logout(BuildContext context) async {
    await _tokenService.clearToken();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      AppPageRoutes.fade(const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _displayPhone.isNotEmpty
        ? 'Chào, $_displayPhone'
        : 'Chào, Quản lý';
    final hasNotificationCount = widget.showNotificationDot && widget.unreadNotificationCount > 0;
    final showSimpleDot = widget.showNotificationDot && widget.unreadNotificationCount == 0;
    final badgeText = widget.unreadNotificationCount > 99
        ? '99+'
        : widget.unreadNotificationCount.toString();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: ManagerColors.primaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        padding: const EdgeInsets.all(6),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'logo/logo1.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title ?? 'Quản lý cơ sở',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            greeting,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_none_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  AppPageRoutes.slide(
                                    const ManagerNotificationPage(),
                                    name: 'manager_notifications',
                                  ),
                                );
                              },
                            ),
                          ),
                          if (hasNotificationCount)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: ManagerColors.primaryGreen,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  badgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          if (showSimpleDot)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ManagerColors.primaryGreen,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.logout_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => _logout(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                ManagerHeaderDate.format(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
