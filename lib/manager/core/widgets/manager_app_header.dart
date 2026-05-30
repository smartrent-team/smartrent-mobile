import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';

/// Định dạng ngày hiển thị trên header manager (tiếng Việt).
class ManagerHeaderDate {
  static String format([DateTime? date]) {
    return DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(date ?? DateTime.now());
  }
}

/// Header xanh dùng chung: SĐT đăng nhập + ngày giờ thực.
class ManagerAppHeader extends StatefulWidget {
  final bool showNotificationDot;

  const ManagerAppHeader({
    super.key,
    this.showNotificationDot = true,
  });

  /// Chuẩn hóa SĐT lưu/hiển thị (vd. +84979... → 0979...).
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
        ? 'Chào, $_displayPhone 👋'
        : 'Chào, Quản lý 👋';

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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'RMS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý cơ sở',
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
                              onPressed: () {},
                            ),
                          ),
                          if (widget.showNotificationDot)
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
