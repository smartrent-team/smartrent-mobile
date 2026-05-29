import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/repair/domain/models/repair_request.dart';
import 'package:smartrent_mobile/tenant/features/repair/presentation/widgets/stat_card.dart';
import 'package:smartrent_mobile/tenant/features/repair/presentation/widgets/repair_card.dart';
import 'package:smartrent_mobile/tenant/features/repair/data/services/repair_service.dart';
import 'package:smartrent_mobile/tenant/features/repair/presentation/pages/create_repair_page.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';

class RepairPage extends StatefulWidget {
  const RepairPage({super.key});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  final RepairService _repairService = RepairService();
  
  List<RepairRequest> _requests = [];
  bool _isLoading = true;
  int _roomId = 1;
  int _tenantId = 5;

  int activeFilterIndex = 0;
  final List<String> filters = ["Tất cả", "Tiếp nhận", "Đang sửa", "Hoàn thành"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _repairService.getTickets();
      if (response.data != null && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        final List<RepairRequest> parsedRequests = data.map((json) => RepairRequest.fromJson(json)).toList();

        // Sort by dateTime descending (newest first)
        parsedRequests.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        setState(() {
          _requests = parsedRequests;
        });

        if (data.isNotEmpty) {
          final firstTicket = data.first;
          if (firstTicket['rooms'] != null && firstTicket['rooms']['id'] != null) {
            _roomId = firstTicket['rooms']['id'];
          }
          if (firstTicket['tenants'] != null && firstTicket['tenants']['id'] != null) {
            _tenantId = firstTicket['tenants']['id'];
          }
        } else {
          // If no tickets exist, fetch tenant profile details to discover correct tenantId
          await _fetchTenantIdFromProfile();
        }
      }
    } catch (e) {
      debugPrint('Error loading tickets: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTenantIdFromProfile() async {
    try {
      final token = await TokenService().getToken();
      String loggedInPhone = '';
      String loggedInName = '';

      if (token != null) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            String payload = parts[1];
            int padLength = 4 - (payload.length % 4);
            if (padLength < 4) {
              payload += '=' * padLength;
            }
            final decodedBytes = base64Url.decode(payload);
            final decodedStr = utf8.decode(decodedBytes);
            final decodedMap = json.decode(decodedStr);
            
            loggedInPhone = decodedMap['phone']?.toString() ?? '';
            if (decodedMap['user_metadata'] != null) {
              loggedInName = decodedMap['user_metadata']['full_name']?.toString() ?? '';
            }
            debugPrint('Decoded JWT - Phone: $loggedInPhone, Name: $loggedInName');
          }
        } catch (e) {
          debugPrint('Error decoding JWT: $e');
        }
      }

      final res = await _repairService.getTenants();
      int foundTenantId = -1;

      if (res.data != null && res.data['success'] == true) {
        final List docs = res.data['docs'] ?? [];
        for (final doc in docs) {
          final tenantPhone = doc['phone']?.toString().replaceAll('+', '').replaceAll(' ', '') ?? '';
          final normalizedPhone = loggedInPhone.replaceAll('+', '').replaceAll(' ', '');
          
          if ((normalizedPhone.isNotEmpty && tenantPhone.contains(normalizedPhone)) || 
              (loggedInName.isNotEmpty && doc['name'] == loggedInName)) {
            foundTenantId = doc['id'];
            setState(() {
              _tenantId = foundTenantId;
            });
            debugPrint('Found Tenant ID from database: $foundTenantId');
            break;
          }
        }
      }

      // If we found a valid tenantId, discover the matching roomId from room details in parallel!
      if (foundTenantId != -1) {
        final List<int> roomIdsToTest = List.generate(30, (i) => i + 1);
        final List<Future> futures = roomIdsToTest.map((roomId) async {
          try {
            final response = await _repairService.getRoomDetail(roomId);
            if (response.data != null && response.data['success'] == true) {
              final data = response.data['data'];
              if (data != null && data['tenant'] != null && data['tenant']['id'] == foundTenantId) {
                setState(() {
                  _roomId = roomId;
                });
                debugPrint('Dynamic discovery found Room ID: $roomId for Tenant ID: $foundTenantId');
              }
            }
          } catch (e) {
            // Room does not exist or fetch failed
          }
        }).toList();

        await Future.wait(futures);
      }
    } catch (e) {
      debugPrint('Error in _fetchTenantIdFromProfile: $e');
    }
  }

  List<RepairRequest> get _filteredRequests {
    if (activeFilterIndex == 1) {
      return _requests.where((r) => r.status == RepairStatus.received).toList();
    } else if (activeFilterIndex == 2) {
      return _requests.where((r) => r.status == RepairStatus.processing).toList();
    } else if (activeFilterIndex == 3) {
      return _requests.where((r) => r.status == RepairStatus.completed).toList();
    }
    return _requests;
  }

  List<int> get _filterCounts {
    final int total = _requests.length;
    final int received = _requests.where((r) => r.status == RepairStatus.received).length;
    final int processing = _requests.where((r) => r.status == RepairStatus.processing).length;
    final int completed = _requests.where((r) => r.status == RepairStatus.completed).length;
    return [total, received, processing, completed];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TenantColors.bgScreenRepair,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        color: TenantColors.primaryGreen,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildFilterChips(),
              const SizedBox(height: 16),
              _isLoading && _requests.isEmpty 
                  ? _buildLoadingState() 
                  : _buildRepairList(),
              const SizedBox(height: 120), // Extra space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final success = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRepairPage(
                roomId: _roomId,
                tenantId: _tenantId,
              ),
            ),
          );

          if (success == true) {
            _loadData();
          }
        },
        backgroundColor: TenantColors.primaryGreenLight,
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
    final int total = _requests.length;
    final int processing = _requests.where((r) => r.status == RepairStatus.processing || r.status == RepairStatus.received).length;
    final int completed = _requests.where((r) => r.status == RepairStatus.completed).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
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
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: "Tổng yêu cầu",
                  count: total.toString(),
                  color: const Color(0xFFF1C40F),
                ),
              ),
              Expanded(
                child: StatCard(
                  title: "Đang xử lý",
                  count: processing.toString(),
                  color: const Color(0xFFE67E22),
                ),
              ),
              Expanded(
                child: StatCard(
                  title: "Hoàn thành",
                  count: completed.toString(),
                  color: const Color(0xFF27AE60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final counts = _filterCounts;
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
                color: isActive ? TenantColors.primaryGreenLight : Colors.white,
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
                      counts[index].toString(),
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

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80.0),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: TenantColors.primaryGreen),
            const SizedBox(height: 16),
            Text(
              'Đang tải yêu cầu sửa chữa...',
              style: GoogleFonts.outfit(color: TenantColors.textGrey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairList() {
    final filtered = _filteredRequests;

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60.0, left: 30, right: 30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  size: 80,
                  color: TenantColors.subtitleGrey,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chưa có yêu cầu nào',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TenantColors.textCharcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                activeFilterIndex == 0 
                    ? 'Nhấn nút "+" phía dưới để tạo yêu cầu sửa chữa thiết bị hỏng hóc trong phòng.'
                    : 'Không tìm thấy yêu cầu nào phù hợp với bộ lọc này.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: TenantColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: filtered.map((req) => RepairCard(request: req)).toList(),
      ),
    );
  }
}
