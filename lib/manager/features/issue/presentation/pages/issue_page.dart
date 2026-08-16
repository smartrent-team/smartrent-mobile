import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_nav.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_shell_scope.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_bottom_nav.dart';
import 'package:smartrent_mobile/manager/features/issue/presentation/pages/issue_detail_page.dart';
import 'package:smartrent_mobile/manager/features/issue/data/services/ticket_service.dart';
import 'package:smartrent_mobile/manager/features/issue/data/models/ticket_model.dart';
import 'package:smartrent_mobile/core/services/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/constants/app_constants.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';

class IssuePage extends StatefulWidget {
  final bool embedInShell;

  const IssuePage({super.key, this.embedInShell = false});

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  final TicketService _ticketService = TicketService();
  final TokenService _tokenService = TokenService();
  String selectedFilter = 'Chưa tiếp nhận';
  List<TicketModel> _allTickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _actionLoadingIds = {};
  late final StreamSubscription<AppEvent> _eventSub;

  final List<String> _filterList = [
    'Chưa tiếp nhận',
    'Tiếp nhận',
    'Hoàn thành',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTickets();
    _eventSub = AppEventBus.instance.on(AppEvent.ticketChanged, () {
      if (mounted) _fetchTickets();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = ManagerShellScope.maybeOf(context);
    if (shell != null) {
      shell.activeTab.removeListener(_onTabChanged);
      shell.activeTab.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    final shell = ManagerShellScope.maybeOf(context);
    if (shell != null && shell.activeTab.value == 3 && mounted) {
      _fetchTickets();
    }
  }

  @override
  void dispose() {
    _eventSub.cancel();
    ManagerShellScope.maybeOf(context)?.activeTab.removeListener(_onTabChanged);
    super.dispose();
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

  bool _isPending(String? status) {
    final s = status?.toLowerCase();
    return s == 'new' || s == 'pending' || s == null || s.isEmpty;
  }

  bool _isInProgress(String? status) {
    final s = status?.toLowerCase();
    return s == 'in_progress' || s == 'in-progress';
  }

  bool _isResolved(String? status) {
    final s = status?.toLowerCase();
    return s == 'resolved' || s == 'closed';
  }

  List<TicketModel> get filteredIssues {
    if (selectedFilter == 'Chưa tiếp nhận') {
      return _allTickets.where((i) => _isPending(i.status)).toList();
    } else if (selectedFilter == 'Tiếp nhận') {
      return _allTickets.where((i) => _isInProgress(i.status)).toList();
    } else if (selectedFilter == 'Hoàn thành') {
      return _allTickets.where((i) => _isResolved(i.status)).toList();
    }
    return _allTickets;
  }

  String _getStatusText(String? status) {
    if (_isPending(status)) return 'Chưa tiếp nhận';
    if (_isInProgress(status)) return 'Đang sửa';
    if (_isResolved(status)) return 'Hoàn thành';
    return 'Chưa tiếp nhận';
  }

  Color _getStatusColor(String? status) {
    if (_isPending(status)) return const Color(0xFFF59E0B); // Amber/Orange
    if (_isInProgress(status)) return const Color(0xFF2563EB); // Blue
    if (_isResolved(status)) return const Color(0xFF10B981); // Emerald/Green
    return Colors.grey;
  }

  Color _getStatusBgColor(String? status) {
    if (_isPending(status)) return const Color(0xFFFEF3C7);
    if (_isInProgress(status)) return const Color(0xFFDBEAFE);
    if (_isResolved(status)) return const Color(0xFFD1FAE5);
    return Colors.grey.shade100;
  }

  IconData _getStatusIcon(String? status) {
    if (_isPending(status)) return Icons.access_time_rounded;
    if (_isInProgress(status)) return Icons.engineering_rounded;
    if (_isResolved(status)) return Icons.check_circle_rounded;
    return Icons.help_outline_rounded;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy • HH:mm').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _quickAcceptTicket(TicketModel issue) async {
    if (issue.id == null) return;
    setState(() => _actionLoadingIds.add(issue.id!));
    try {
      final response = await _ticketService.updateTicketStatus(issue.id!, 'in-progress');
      if (response.statusCode == 200) {
        AppEventBus.instance.fire(AppEvent.ticketChanged);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tiếp nhận sự cố thành công!'),
              backgroundColor: Color(0xFF2563EB),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tiếp nhận sự cố. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionLoadingIds.remove(issue.id!));
      }
    }
  }

  Future<int?> _showRepairCostDialog() async {
    final TextEditingController costController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shadowColor: ManagerColors.cardShadow,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.monetization_on_outlined, color: ManagerColors.primaryGreen),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Chi phí sửa chữa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhập chi phí phát sinh nếu có để ghi nhận vào hệ thống (để trống hoặc 0 nếu miễn phí):',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Số tiền (VNĐ)',
                    hintText: 'Ví dụ: 150000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.payments_outlined, color: Colors.grey),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final val = int.tryParse(value.trim());
                      if (val == null || val < 0) {
                        return 'Vui lòng nhập số tiền hợp lệ';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final text = costController.text.trim();
                  final val = text.isEmpty ? 0 : int.parse(text);
                  Navigator.of(context).pop(val);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ManagerColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Xác nhận hoàn thành', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _quickResolveTicket(TicketModel issue) async {
    if (issue.id == null) return;
    final repairCost = await _showRepairCostDialog();
    if (repairCost == null) return; // User canceled

    setState(() => _actionLoadingIds.add(issue.id!));
    try {
      final response = await _ticketService.updateTicketStatus(
        issue.id!,
        'resolved',
        repairCost: repairCost,
      );
      if (response.statusCode == 200) {
        AppEventBus.instance.fire(AppEvent.ticketChanged);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xác nhận hoàn thành sự cố thành công!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật sự cố. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionLoadingIds.remove(issue.id!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _allTickets.where((t) => t.isOpen).length;
    final content = Column(
      children: [
        SizedBox(height: widget.embedInShell ? 8 : 12),
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
          Expanded(child: content),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            ),
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
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        return _buildIssueCard(issues[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    IconData icon = Icons.inbox_outlined;
    String title = 'Không có sự cố nào';
    String subtitle = 'Danh sách sự cố hiện đang trống';

    if (selectedFilter == 'Chưa tiếp nhận') {
      icon = Icons.mark_email_read_outlined;
      title = 'Tuyệt vời! Không có sự cố chờ xử lý';
      subtitle = 'Tất cả các báo hỏng đều đã được tiếp nhận và xử lý';
    } else if (selectedFilter == 'Tiếp nhận') {
      icon = Icons.engineering_outlined;
      title = 'Không có sự cố nào đang sửa';
      subtitle = 'Các sự cố đã tiếp nhận sẽ hiển thị tại đây';
    } else if (selectedFilter == 'Hoàn thành') {
      icon = Icons.task_alt_outlined;
      title = 'Chưa có sự cố nào hoàn thành';
      subtitle = 'Các sự cố đã xử lý xong sẽ lưu lại tại đây';
    }

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 54, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filterList.map((tab) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _buildFilterTab(tab),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final bool isActive = selectedFilter == label;
    int count = 0;
    Color activeBgColor = ManagerColors.primaryGreen;

    if (label == 'Chưa tiếp nhận') {
      count = _allTickets.where((t) => _isPending(t.status)).length;
      activeBgColor = const Color(0xFFF59E0B);
    } else if (label == 'Tiếp nhận') {
      count = _allTickets.where((t) => _isInProgress(t.status)).length;
      activeBgColor = const Color(0xFF2563EB);
    } else if (label == 'Hoàn thành') {
      count = _allTickets.where((t) => _isResolved(t.status)).length;
      activeBgColor = const Color(0xFF10B981);
    }

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeBgColor : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeBgColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withOpacity(0.25) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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
    final statusBgColor = _getStatusBgColor(issue.status);
    final statusIcon = _getStatusIcon(issue.status);
    final hasImage = issue.images != null && issue.images!.isNotEmpty;
    final isActionLoading = issue.id != null && _actionLoadingIds.contains(issue.id!);
    final isPendingStatus = _isPending(issue.status);
    final isInProgressStatus = _isInProgress(issue.status);
    final isResolvedStatus = _isResolved(issue.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: ManagerColors.cardShadow,
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            context.pushSlide(IssueDetailPage(issue: issue)).then((_) => _fetchTickets());
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Thông tin phòng + Badge trạng thái
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ManagerColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_work_outlined, color: ManagerColors.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildLocationPill(
                            icon: Icons.meeting_room_outlined,
                            label: issue.roomName ?? 'Phòng N/A',
                            color: ManagerColors.primaryGreen,
                          ),
                          if (issue.floor != null && issue.floor!.isNotEmpty)
                            _buildLocationPill(
                              icon: Icons.layers_outlined,
                              label: 'Tầng ${issue.floor}',
                              color: Colors.blueGrey,
                            ),
                          if (issue.isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, size: 12, color: Colors.red.shade700),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Khẩn cấp',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge trạng thái
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 2: Tiêu đề & Mô tả sự cố + Ảnh đính kèm
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (issue.title != null && issue.title!.isNotEmpty) ...[
                            Text(
                              issue.title!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            issue.description ?? 'Không có mô tả chi tiết',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          issue.images![0].startsWith('http')
                              ? issue.images![0]
                              : '${AppConstants.baseUrl}${issue.images![0]}',
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 68,
                            height: 68,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Chi phí sửa chữa nếu đã hoàn thành
                if (isResolvedStatus && issue.repairCost != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined, size: 15, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Text(
                          'Chi phí: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(issue.repairCost)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 10),

                // Row 3: Thời gian & Mã Ticket
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(_formatDate(issue.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    Text('#T-${issue.id}', style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 4: Nút thao tác nhanh theo trạng thái
                if (isPendingStatus) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.pushSlide(IssueDetailPage(issue: issue)).then((_) => _fetchTickets());
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Chi tiết', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isActionLoading ? null : () => _quickAcceptTicket(issue),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: isActionLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_outlined, size: 16),
                                    SizedBox(width: 4),
                                    Text('Tiếp nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ] else if (isInProgressStatus) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.pushSlide(IssueDetailPage(issue: issue)).then((_) => _fetchTickets());
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Chi tiết', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isActionLoading ? null : () => _quickResolveTicket(issue),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: isActionLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.task_alt, size: 16),
                                    SizedBox(width: 4),
                                    Text('Hoàn thành', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        context.pushSlide(IssueDetailPage(issue: issue)).then((_) => _fetchTickets());
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 16, color: Colors.black54),
                          SizedBox(width: 6),
                          Text('Xem chi tiết sự cố', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
