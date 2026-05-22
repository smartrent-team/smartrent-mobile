import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/repair_request.dart';
import '../widgets/stat_card.dart';
import '../widgets/repair_card.dart';

class RepairScreen extends StatefulWidget {
  const RepairScreen({super.key});

  @override
  State<RepairScreen> createState() => _RepairScreenState();
}

class _RepairScreenState extends State<RepairScreen> {
  int activeFilterIndex = 0;
  final List<String> filters = ["Tất cả", "Tiếp nhận", "Đang sửa", "Hoàn thành"];
  final List<int> filterCounts = [5, 1, 2, 2];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildFilterChips(),
            const SizedBox(height: 16),
            _buildRepairList(),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF5CB85C),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Tạo yêu cầu",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3E2703),
            Color(0xFF5D4037),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Phòng P203 · Nhà trọ Phúc An",
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Yêu cầu sửa chữa",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white70, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Row(
            children: [
              StatCard(
                title: "Tổng yêu cầu",
                count: "5",
                color: Color(0xFFF1C40F),
              ),
              StatCard(
                title: "Đang xử lý",
                count: "3",
                color: Color(0xFFE67E22),
              ),
              StatCard(
                title: "Hoàn thành",
                count: "2",
                color: Color(0xFF27AE60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          bool isActive = activeFilterIndex == index;
          return GestureDetector(
            onTap: () => setState(() => activeFilterIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF5CB85C) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isActive ? Colors.transparent : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    filters[index],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      filterCounts[index].toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRepairList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: fakeRepairRequests.map((req) => RepairCard(request: req)).toList(),
      ),
    );
  }
}
