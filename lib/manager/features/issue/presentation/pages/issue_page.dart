import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_nav.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_bottom_nav.dart';
import 'package:smartrent_mobile/manager/features/issue/presentation/pages/issue_detail_page.dart';
import 'package:smartrent_mobile/manager/features/issue/data/services/ticket_service.dart';
import 'package:smartrent_mobile/manager/features/issue/data/models/ticket_model.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:intl/intl.dart';

class IssuePage extends StatefulWidget {
  final bool embedInShell;

  const IssuePage({super.key, this.embedInShell = false});

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  final TicketService _ticketService = TicketService();
  final TokenService _tokenService = TokenService();
  String selectedFilter = 'Tất cả';
  List<TicketModel> _allTickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _ticketService.getTickets();
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> ticketsData = data['data'] ?? [];
          setState(() {
            _allTickets = ticketsData.map((json) => TicketModel.fromJson(json)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Không thể tải danh sách sự cố';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi máy chủ: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      setState(() {
        _errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSessionExpired() async {
    await _tokenService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  List<TicketModel> get filteredIssues {
    if (selectedFilter == 'Tiếp nhận') {
      return _allTickets.where((i) => i.status == 'new').toList();
    } else if (selectedFilter == 'Đang sửa') {
      return _allTickets.where((i) => i.status == 'in_progress').toList();
    }
    return _allTickets;
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'new':
      case 'pending':
        return 'Tiếp nhận';
      case 'in_progress':
        return 'Đang sửa';
      case 'resolved':
        return 'Đã xong';
      default:
        return 'Chờ xử lý';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'new':
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy • HH:mm').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _allTickets.where((t) => t.isOpen).length;
    final content = Column(
      children: [
        SizedBox(height: widget.embedInShell ? 12 : 16),
        _buildFilterBar(),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchTickets,
            color: ManagerColors.primaryGreen,
            child: _buildBody(),
          ),
        ),
      ],
    );

    if (widget.embedInShell) {
      return content;
    }

    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(
        children: [
          const ManagerAppHeader(),
          content,
        ],
      ),
      bottomNavigationBar: ManagerBottomNav(
        currentIndex: 3,
        onTap: (index) => ManagerNav.bottomNav(context, index, currentIndex: 3),
        issueBadgeCount: openCount,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: ManagerColors.primaryGreen));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTickets,
              style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final issues = filteredIssues;
    if (issues.isEmpty) {
      return const Center(
        child: Text('Không có sự cố nào trong danh sách', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        return _buildIssueCard(issues[index]);
      },
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterTab('Tất cả'),
            const SizedBox(width: 12),
            _buildFilterTab('Tiếp nhận'),
            const SizedBox(width: 12),
            _buildFilterTab('Đang sửa'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final bool isActive = selectedFilter == label;
    int count = 0;
    if (label == 'Tất cả') count = _allTickets.length;
    else if (label == 'Tiếp nhận') count = _allTickets.where((t) => t.status == 'new').length;
    else if (label == 'Đang sửa') count = _allTickets.where((t) => t.status == 'in_progress').length;

    final displayLabel = count > 0 ? '$label ($count)' : label;

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? ManagerColors.primaryGreen : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildLocationPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(TicketModel issue) {
    final statusText = _getStatusText(issue.status);
    final statusColor = _getStatusColor(issue.status);
    final hasImage = issue.images != null && issue.images!.isNotEmpty;

    return InkWell(
      onTap: () {
        context.pushSlide(IssueDetailPage(issue: issue)).then((_) => _fetchTickets());
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 15, offset: Offset(0, 5))],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Thông tin phòng + badge trạng thái
          Row(
            children: [
              // Icon phòng
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ManagerColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home_work_outlined, color: ManagerColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              // Pill phòng + tầng
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildLocationPill(
                      icon: Icons.meeting_room_outlined,
                      label: issue.roomName ?? 'Chưa xác định',
                      color: ManagerColors.primaryGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge trạng thái
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mô tả sự cố', style: TextStyle(color: ManagerColors.subtitleGrey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(issue.description ?? 'Trống', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 12),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(issue.images![0].startsWith('http') 
                          ? issue.images![0] 
                          : 'http://10.0.2.2:3000${issue.images![0]}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [const Icon(Icons.calendar_today_outlined, size: 14, color: ManagerColors.primaryGreen), const SizedBox(width: 6), Text(_formatDate(issue.createdAt), style: const TextStyle(color: Colors.black45, fontSize: 12))]),
              Text('#T-${issue.id}', style: const TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                context.pushSlide(IssueDetailPage(issue: issue)).then((_) => _fetchTickets());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ManagerColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search, size: 18),
                  SizedBox(width: 8),
                  Text('Chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

}
