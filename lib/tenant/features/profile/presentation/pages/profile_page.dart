import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/tenant/core/navigation/tenant_nav.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/profile/presentation/widgets/info_tile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TenantColors.bgScreenLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildContactCard(),
            const SizedBox(height: 16),
            _buildRoomInfoCard(),
            const SizedBox(height: 16),
            _buildMenuActions(),
            const SizedBox(height: 16),
            _buildLogoutButton(context),
            const SizedBox(height: 40),
            _buildFooter(),
            const SizedBox(height: 40),
          ],
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
            "Nguyễn Văn An",
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "Cư dân phòng 203",
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
      child: const Column(
        children: [
          ProfileInfoTile(
            icon: Icons.phone_outlined,
            label: "Số điện thoại",
            value: "0909 123 456",
          ),
          ProfileInfoTile(
            icon: Icons.mail_outline,
            label: "Email",
            value: "nguyenvanan@email.com",
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfoCard() {
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
          const ProfileInfoTile(
            icon: Icons.tag,
            label: "Phòng",
            value: "P203 - Tầng 2",
          ),
          const ProfileInfoTile(
            icon: Icons.calendar_today_outlined,
            label: "Ngày bắt đầu thuê",
            value: "01/01/2025",
          ),
          const ProfileInfoTile(
            icon: Icons.check_circle_outline,
            iconColor: TenantColors.primaryGreen,
            label: "Trạng thái hợp đồng",
            value: "Đang hiệu lực",
          ),
          const ProfileInfoTile(
            icon: Icons.payments_outlined,
            label: "Tiền cọc",
            value: "5.000.000 đ",
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          MenuActionTile(
            icon: Icons.lock_open_rounded,
            color: TenantColors.primaryGreenDark,
            title: "Đổi mật khẩu",
            subtitle: "Thay đổi mật khẩu đăng nhập",
          ),
          MenuActionTile(
            icon: Icons.call_outlined,
            color: Colors.blue,
            title: "Liên hệ quản lý",
            subtitle: "Hotline: 0909 123 456",
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
