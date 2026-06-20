import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  TenantProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });
    final profile = await _profileService.getProfile();
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
      backgroundColor: TenantColors.bgScreenLight,
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: TenantColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildContactCard(),
              const SizedBox(height: 16),
              _buildRoomInfoCard(),
              const SizedBox(height: 16),
              _buildMenuActions(context),
              const SizedBox(height: 16),
              _buildLogoutButton(context),
              const SizedBox(height: 40),
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
                  radius: 50,
                  backgroundColor: Color(0xFFC8E6C9),
                  child: Icon(Icons.person, size: 60, color: TenantColors.primaryGreen),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: TenantColors.primaryGreen, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _profile?.fullName ?? "N/A",
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "Cư dân phòng ${_profile?.room?.roomCode ?? "N/A"}",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileInfoTile(
            icon: Icons.phone_outlined,
            label: "Số điện thoại",
            value: _profile?.phone ?? "N/A",
          ),
          ProfileInfoTile(
            icon: Icons.mail_outline,
            label: "Email",
            value: _profile?.email ?? "N/A",
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TenantColors.bgMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apartment, color: TenantColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                "Thông tin phòng thuê",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TenantColors.textCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProfileInfoTile(
            icon: Icons.tag,
            label: "Phòng",
            value: "${_profile?.room?.roomCode ?? "N/A"} - Tầng ${_profile?.room?.floor ?? "N/A"}",
          ),
          ProfileInfoTile(
            icon: Icons.calendar_today_outlined,
            label: "Ngày bắt đầu thuê",
            value: _profile?.moveInDate != null ? dateFormat.format(_profile!.moveInDate) : "N/A",
          ),
          ProfileInfoTile(
            icon: Icons.check_circle_outline,
            iconColor: _profile?.status == 'active' ? TenantColors.primaryGreen : Colors.grey,
            label: "Trạng thái",
            value: _profile?.status == 'active' ? "Đang hoạt động" : "Ngừng hoạt động",
          ),
          ProfileInfoTile(
            icon: Icons.payments_outlined,
            label: "Giá phòng cơ bản",
            value: _profile?.room?.basePrice != null ? currencyFormat.format(_profile!.room!.basePrice) : "0 đ",
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
            icon: Icons.lock_open_rounded,
            color: TenantColors.primaryGreenDark,
            title: "Đổi mật khẩu",
            subtitle: "Thay đổi mật khẩu đăng nhập",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TenantChangePasswordPage()),
            ),
          ),
          MenuActionTile(
            icon: Icons.call_outlined,
            color: Colors.blue,
            title: "Liên hệ quản lý",
            subtitle: _profile?.room?.branchName != null ? "Chi nhánh: ${_profile!.room!.branchName}" : "Hotline liên hệ",
          ),
          MenuActionTile(
            icon: Icons.security_outlined,
            color: Colors.purple,
            title: "Chính sách ứng dụng",
            subtitle: "Điều khoản & bảo mật",
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
          borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
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
    return Column(
      children: [
        Text(
          "RMS Tenant App",
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.grey[400],
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          "Version 1.0.0 • Build 2025.05",
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.grey[350],
          ),
        ),
      ],
    );
  }
}

