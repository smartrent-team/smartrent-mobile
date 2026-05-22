import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/repair_screen.dart';
import 'screens/profile_screen.dart';

class MainNavScaffold extends StatefulWidget {
  const MainNavScaffold({super.key});

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> {
  int _selectedIndex = 2; // Default to Sửa chữa as per request

  final List<Widget> _pages = [
    const Center(child: Text("Trang chủ")),
    const Center(child: Text("Hóa đơn")),
    const RepairScreen(),
    const Center(child: Text("Thông báo")),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF5CB85C),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Trang chủ"),
            const BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: "Hóa đơn"),
            BottomNavigationBarItem(
              icon: _buildNavItem(Icons.build_outlined, false, 2),
              activeIcon: _buildNavItem(Icons.build, true, 2),
              label: "Sửa chữa",
            ),
            const BottomNavigationBarItem(
              icon: Badge(
                label: Text("1"),
                child: Icon(Icons.notifications_none_outlined),
              ),
              activeIcon: Badge(
                label: Text("1"),
                child: Icon(Icons.notifications),
              ),
              label: "Thông báo",
            ),
            BottomNavigationBarItem(
              icon: _buildNavItem(Icons.person_outline, false, 4),
              activeIcon: _buildNavItem(Icons.person, true, 4),
              label: "Tài khoản",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, int index) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: const Color(0xFF5CB85C), size: 24),
      );
    }
    return Icon(icon, size: 24);
  }
}
