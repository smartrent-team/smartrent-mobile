import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/issue/data/models/ticket_model.dart';
import 'package:smartrent_mobile/manager/features/issue/data/services/ticket_service.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/constants/app_constants.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';

class IssueDetailPage extends StatefulWidget {
  final TicketModel issue;
  const IssueDetailPage({super.key, required this.issue});

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  final TicketService _ticketService = TicketService();
  late String _currentStatus;
  TicketModel? _ticketDetail;
  bool _isUpdating = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    String? status = widget.issue.status;
    if (status == 'in_progress') status = 'in-progress';
    _currentStatus = status ?? 'pending';
    _fetchTicketDetail();
  }

  Future<void> _fetchTicketDetail() async {
    setState(() => _isLoading = true);
    try {
      final response = await _ticketService.getTicketById(widget.issue.id!);
      if (response.statusCode == 200) {
        setState(() {
          _ticketDetail = TicketModel.fromJson(response.data['data']);
          String? status = _ticketDetail?.status;
          if (status == 'in_progress') status = 'in-progress';
          _currentStatus = status ?? 'pending';
        });
      }
    } catch (e) {
      debugPrint('Fetch ticket detail error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  String _getStatusText(String? status) {
    if (_isPending(status)) return 'Chưa tiếp nhận';
    if (_isInProgress(status)) return 'Đang sửa';
    if (_isResolved(status)) return 'Hoàn thành';
    return 'Chưa tiếp nhận';
  }

  Color _getStatusColor(String? status) {
    if (_isPending(status)) return const Color(0xFFF59E0B);
    if (_isInProgress(status)) return const Color(0xFF2563EB);
    if (_isResolved(status)) return const Color(0xFF10B981);
    return Colors.grey;
  }

  Color _getStatusBgColor(String? status) {
    if (_isPending(status)) return const Color(0xFFFEF3C7);
    if (_isInProgress(status)) return const Color(0xFFDBEAFE);
    if (_isResolved(status)) return const Color(0xFFD1FAE5);
    return Colors.grey.shade100;
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
                  'Vui lòng nhập số tiền sửa chữa cho sự cố này (nếu có). Nhập 0 hoặc để trống nếu không mất phí.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Số tiền (VNĐ)',
                    hintText: 'Ví dụ: 150000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus({String? directStatus}) async {
    String statusToSend = directStatus ?? _currentStatus;
    if (statusToSend == 'in_progress') statusToSend = 'in-progress';

    int? repairCost;
    if (statusToSend == 'resolved') {
      repairCost = await _showRepairCostDialog();
      if (repairCost == null) {
        return; // User cancelled
      }
    }

    setState(() => _isUpdating = true);

    try {
      final response = await _ticketService.updateTicketStatus(
        issue.id!,
        statusToSend,
        repairCost: repairCost,
      );

      if (response.statusCode == 200) {
        AppEventBus.instance.fire(AppEvent.ticketChanged);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật trạng thái thành công'),
              backgroundColor: ManagerColors.primaryGreen,
            ),
          );
          _fetchTicketDetail();
        }
      } else {
        throw Exception('Cập nhật thất bại');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật trạng thái. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  TicketModel get issue => _ticketDetail ?? widget.issue;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ManagerColors.bgLightGreen,
        appBar: AppBar(
          backgroundColor: ManagerColors.primaryGreen,
          title: const Text('Chi tiết sự cố', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: ManagerColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                children: [
                  _buildTimeSection(),
                  const SizedBox(height: 16),
                  _buildDescriptionSection(),
                  if (issue.images != null && issue.images!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildImageSection(),
                  ],
                  if (issue.repairCost != null) ...[
                    const SizedBox(height: 16),
                    _buildRepairCostSection(),
                  ],
                  const SizedBox(height: 16),
                  _buildStatusSection(),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'SmartRent • Quản lý sự cố',
                      style: TextStyle(fontSize: 12, color: Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: const BoxDecoration(
        color: ManagerColors.primaryGreen,
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const Text('Chi tiết sự cố', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('#T-${issue.id}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vị trí phòng sự cố', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      issue.roomName ?? 'Phòng N/A',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPending(issue.status)
                          ? Icons.access_time_rounded
                          : _isInProgress(issue.status)
                              ? Icons.engineering_rounded
                              : Icons.check_circle_rounded,
                      color: _getStatusColor(issue.status),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(issue.status),
                      style: TextStyle(
                        color: _getStatusColor(issue.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    String formattedDate = 'N/A';
    if (issue.createdAt != null) {
      try {
        DateTime dt = DateTime.parse(issue.createdAt!).toLocal();
        formattedDate = DateFormat('dd/MM/yyyy lúc HH:mm').format(dt);
      } catch (_) {}
    }

    return _buildCardWrapper(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_today_outlined, color: ManagerColors.primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THỜI GIAN GỬI BÁO HỎNG', style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(formattedDate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairCostSection() {
    if (issue.repairCost == null) return const SizedBox.shrink();

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0);
    final formattedCost = formatter.format(issue.repairCost);

    return _buildCardWrapper(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monetization_on_outlined,
              color: Colors.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHI PHÍ SỬA CHỮA',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedCost,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.description_outlined, color: Colors.orange, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('MÔ TẢ SỰ CỐ', style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          if (issue.title != null && issue.title!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              issue.title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
          const SizedBox(height: 8),
          Text(issue.description ?? 'Không có mô tả', style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildCardWrapper(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.image_outlined, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Text('ẢNH BÁO HỎNG', style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('${issue.images?.length ?? 0} ảnh', style: const TextStyle(color: Colors.black38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: issue.images?.length ?? 0,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final url = issue.images![index];
                return AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url.startsWith('http') ? url : '${AppConstants.baseUrl}$url',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final isResolved = _isResolved(issue.status);

    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.track_changes_outlined, color: ManagerColors.primaryGreen, size: 18),
              SizedBox(width: 8),
              Text('TIẾN TRÌNH XỬ LÝ', style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeline(),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (isResolved) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sự cố đã hoàn tất xử lý',
                          style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Không thể thay đổi trạng thái sau khi đã hoàn thành.',
                          style: TextStyle(color: Color(0xFF047857), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'Chuyển trạng thái xử lý:',
              style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildStatusDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final actualStatus = issue.status;
    final isPending = _isPending(actualStatus);

    // Nếu đang là Chưa tiếp nhận: được chọn "Chưa tiếp nhận" hoặc "Đang sửa" hoặc "Hoàn thành"
    // Nếu đang là Đang sửa: chỉ được chọn "Đang sửa" hoặc "Hoàn thành" (không được lùi về Chưa tiếp nhận)
    final items = <DropdownMenuItem<String>>[
      if (isPending)
        const DropdownMenuItem<String>(
          value: 'pending',
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: Color(0xFFF59E0B)),
              SizedBox(width: 10),
              Text('Chưa tiếp nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      const DropdownMenuItem<String>(
        value: 'in-progress',
        child: Row(
          children: [
            Icon(Icons.circle, size: 10, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text('Đang sửa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
      const DropdownMenuItem<String>(
        value: 'resolved',
        child: Row(
          children: [
            Icon(Icons.circle, size: 10, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Text('Hoàn thành', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusBgColor(_currentStatus),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(_currentStatus).withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentStatus == 'in_progress' ? 'in-progress' : _currentStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black45),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _currentStatus = newValue;
              });
            }
          },
          items: items,
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final status = issue.status;
    final isStep1 = true;
    final isStep2 = _isInProgress(status) || _isResolved(status);
    final isStep3 = _isResolved(status);

    return Row(
      children: [
        _buildTimelinePoint('Chưa tiếp nhận', isStep1, const Color(0xFFF59E0B)),
        _buildTimelineLine(isStep2),
        _buildTimelinePoint('Tiếp nhận', isStep2, const Color(0xFF2563EB)),
        _buildTimelineLine(isStep3),
        _buildTimelinePoint('Hoàn thành', isStep3, const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildTimelinePoint(String label, bool isCompleted, Color activeColor) {
    Color pointColor = isCompleted ? activeColor : Colors.grey.shade300;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: pointColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: pointColor, width: 2),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle_outlined,
              color: pointColor,
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isCompleted ? Colors.black87 : Colors.grey,
              fontSize: 11,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isCompleted) {
    return Container(
      width: 24,
      height: 2,
      color: isCompleted ? ManagerColors.primaryGreen : Colors.grey.shade300,
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildBottomButton() {
    final actualStatus = issue.status;
    final normalizedActual = (actualStatus == 'in_progress') ? 'in-progress' : (actualStatus ?? 'pending');
    bool hasDropdownChanged = _currentStatus != normalizedActual;

    // Trường hợp 1: Manager đổi dropdown trạng thái
    if (hasDropdownChanged) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isUpdating ? null : () => _updateStatus(),
            style: ElevatedButton.styleFrom(
              backgroundColor: ManagerColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isUpdating
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Lưu thay đổi trạng thái', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      );
    }

    // Trường hợp 2: Báo hỏng đang là "Chưa tiếp nhận"
    if (_isPending(actualStatus)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isUpdating ? null : () => _updateStatus(directStatus: 'in-progress'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isUpdating
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Tiếp nhận xử lý sự cố', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      );
    }

    // Trường hợp 3: Báo hỏng đang là "Tiếp nhận" (Đang xử lý)
    if (_isInProgress(actualStatus)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isUpdating ? null : () => _updateStatus(directStatus: 'resolved'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isUpdating
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Xác nhận hoàn thành', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      );
    }

    // Trường hợp 4: Đã hoàn thành
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
            SizedBox(width: 8),
            Text(
              'Sự cố này đã được giải quyết hoàn tất',
              style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
