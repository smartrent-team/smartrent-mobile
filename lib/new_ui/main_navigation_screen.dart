import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/tanent/home_tanent.dart';
import 'package:smartrent_mobile/tanent/order_tanent.dart';
import 'screens/repair_screen.dart';
import 'screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Use IndexedStack to keep the state of each screen
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeTanent(showBottomNav: false),
      const OrderTanent(showBottomNav: false),
      const RepairScreen(),
      const Center(child: Text("Thông báo")), // Placeholder for now
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'Trang chủ', Icons.home_outlined, Icons.home),
              _buildNavItem(1, 'Hóa đơn', Icons.description_outlined, Icons.description),
              _buildNavItem(2, 'Sửa chữa', Icons.build_outlined, Icons.build),
              _buildNavItem(3, 'Thông báo', Icons.notifications_none_outlined, Icons.notifications, hasBadge: true),
              _buildNavItem(4, 'Tài khoản', Icons.person_outline_rounded, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, IconData activeIcon, {bool hasBadge = false}) {
    final bool isActive = _currentIndex == index;
    const Color primaryGreen = Color(0xFF4CAF50);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? primaryGreen : Colors.grey[400],
                  size: 24,
                ),
                if (hasBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? primaryGreen : Colors.grey[400],
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
