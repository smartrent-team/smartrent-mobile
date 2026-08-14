import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';
import 'package:smartrent_mobile/core/utils/vn_date.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/tenant/core/navigation/tenant_nav.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/profile/data/services/profile_service.dart';
import 'package:smartrent_mobile/tenant/features/profile/domain/models/tenant_profile.dart';
import 'package:smartrent_mobile/tenant/features/profile/presentation/widgets/info_tile.dart';
import 'package:smartrent_mobile/tenant/features/profile/presentation/pages/tenant_change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final ProfileService _profileService = ProfileService();
  TenantProfile? _profile;
  bool _isLoading = true;
  late final StreamSubscription<AppEvent> _eventSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchProfile();
    _eventSub = AppEventBus.instance.onAny((_) {
      if (mounted) _fetchProfile(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSub.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _fetchProfile(silent: true);
    }
  }

  Future<void> _fetchProfile({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    final profile = await _profileService.getProfile(bustCache: true);
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: TenantColors.primaryGreen),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Không thể tải thông tin hồ sơ"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TenantColors.primaryGreen,
                ),
                child: const Text("Thử lại", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: TenantColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),

              // Mục 1: Thông tin liên hệ
              _buildSectionHeader(
                icon: Icons.person_outline_rounded,
                title: "Thông tin liên hệ",
                iconColor: Colors.blueAccent,
              ),
              const SizedBox(height: 8),
              _buildContactCard(),

              const SizedBox(height: 24),

              // Mục 2: Thông tin phòng thuê
              _buildSectionHeader(
                icon: Icons.apartment_rounded,
                title: "Thông tin phòng thuê",
                iconColor: TenantColors.primaryGreen,
              ),
              const SizedBox(height: 8),
              _buildRoomInfoCard(),

              const SizedBox(height: 24),

              // Mục 3: Cài đặt tài khoản & Bảo mật
              _buildSectionHeader(
                icon: Icons.shield_outlined,
                title: "Tài khoản & Bảo mật",
                iconColor: Colors.orange.shade700,
              ),
              const SizedBox(height: 8),
              _buildMenuActions(context),

              const SizedBox(height: 24),
              _buildLogoutButton(context),
              const SizedBox(height: 32),
              _buildFooter(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            TenantColors.primaryGreen,
            Color(0xFF4CAF50),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tài khoản",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 46,
                  backgroundColor: Color(0xFFC8E6C9),
                  child: Icon(Icons.person, size: 54, color: TenantColors.primaryGreen),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: TenantColors.primaryGreen, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _profile?.fullName ?? "N/A",
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Cư dân phòng ${_profile?.room?.roomCode ?? "N/A"}",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileInfoTile(
            icon: Icons.phone_outlined,
            iconColor: Colors.blueAccent,
            label: "Số điện thoại",
            value: _profile?.phone ?? "Chưa cập nhật",
          ),
          ProfileInfoTile(
            icon: Icons.mail_outline,
            iconColor: Colors.deepPurpleAccent,
            label: "Email",
            value: _profile?.email ?? "Chưa cập nhật",
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileInfoTile(
            icon: Icons.tag,
            iconColor: TenantColors.primaryGreen,
            label: "Phòng đang ở",
            value: "${_profile?.room?.roomCode ?? "N/A"} · Tầng ${_profile?.room?.floor ?? "N/A"}",
          ),
          ProfileInfoTile(
            icon: Icons.calendar_today_outlined,
            iconColor: Colors.teal,
            label: "Ngày bắt đầu thuê",
            value: VnDate.format(_profile?.moveInDate),
          ),
          ProfileInfoTile(
            icon: Icons.payments_outlined,
            iconColor: Colors.amber.shade800,
            label: "Giá phòng cơ bản",
            value: _profile?.room?.basePrice != null
                ? "${currencyFormat.format(_profile!.room!.basePrice)} / tháng"
                : "0 đ / tháng",
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          MenuActionTile(
            icon: Icons.lock_outline_rounded,
            color: Colors.orange.shade700,
            title: "Đổi mật khẩu",
            subtitle: "Thay đổi mật khẩu đăng nhập tài khoản",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TenantChangePasswordPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(targetNav: TenantNav()),
                ),
                (route) => false,
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Đăng xuất",
                    style: GoogleFonts.outfit(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            "RMS Tenant App",
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Phiên bản 2.4.1",
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
