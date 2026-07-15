import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/issue/data/models/ticket_model.dart';
import 'package:smartrent_mobile/manager/features/issue/data/services/ticket_service.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/constants/app_constants.dart';

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
    if (status == 'in-progress') status = 'in_progress';
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
          if (status == 'in-progress') status = 'in_progress';
          _currentStatus = status ?? 'pending';
        });
      }
    } catch (e) {
      debugPrint('Fetch ticket detail error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
              Icon(Icons.monetization_on, color: ManagerColors.primaryGreen),
              SizedBox(width: 10),
              Text(
                'Nhập chi phí sửa chữa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  decoration: InputDecoration(
                    labelText: 'Số tiền (VND)',
                    hintText: 'Ví dụ: 150000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.payments, color: Colors.grey),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus() async {
    String statusToSend = _currentStatus;
    if (statusToSend == 'in_progress') statusToSend = 'in-progress';
    
    int? repairCost;
    if (statusToSend == 'resolved') {
      repairCost = await _showRepairCostDialog();
      if (repairCost == null) {
        return; // Cancel status update
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật trạng thái thành công')),
          );
          _fetchTicketDetail(); // Refresh data from server
        }
      } else {
        throw Exception('Cập nhật thất bại');
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
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
          title: const Text('Đang tải...', style: TextStyle(color: Colors.white)),
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              child: Column(
                children: [
                  _buildTimeSection(),
                  const SizedBox(height: 20),
                  _buildDescriptionSection(),
                  if (issue.images != null && issue.images!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildImageSection(),
                  ],
                  if (issue.repairCost != null) ...[
                    const SizedBox(height: 20),
                    _buildRepairCostSection(),
                  ],
                  const SizedBox(height: 20),
                  _buildStatusSection(),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      '© 2025 RMS · Phiên bản 2.4.1',
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
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        color: ManagerColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
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
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vị trí sự cố', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      issue.roomName ?? 'Chưa xác định',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(_getStatusText(_currentStatus), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
        DateTime dt = DateTime.parse(issue.createdAt!);
        formattedDate = DateFormat('dd/MM/yyyy lúc HH:mm').format(dt);
      } catch (_) {}
    }

    return _buildCardWrapper(
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.calendar_today, color: ManagerColors.primaryGreen, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THỜI GIAN TẠO TICKET', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(formattedDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
            decoration: BoxDecoration(color: _getStatusColor(_currentStatus).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
            child: Text(_getStatusText(_currentStatus), style: TextStyle(color: _getStatusColor(_currentStatus), fontSize: 11, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _buildRepairCostSection() {
    if (issue.repairCost == null) return const SizedBox.shrink();
    
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
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
              Icons.monetization_on,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHI PHÍ SỬA CHỮA',
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedCost,
                  style: const TextStyle(
                    fontSize: 18,
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
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16)),
              const SizedBox(width: 8),
              const Text('MÔ TẢ SỰ CỐ', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(issue.description ?? 'Không có mô tả', style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
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
              Row(
                children: [
                  const Icon(Icons.image_outlined, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  const Text('ẢNH CƯ DÂN GỬI', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('${issue.images?.length ?? 0} ảnh', style: const TextStyle(color: Colors.black38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: issue.images?.length ?? 0,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final url = issue.images![index];
                return AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      url.startsWith('http') ? url : '${AppConstants.baseUrl}$url',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
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
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: ManagerColors.primaryGreen, size: 18),
              const SizedBox(width: 8),
              const Text('TRẠNG THÁI XỬ LÝ', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusDropdown(),
          const SizedBox(height: 24),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(_currentStatus).withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _getStatusColor(_currentStatus).withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black38),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _currentStatus = newValue;
              });
            }
          },
          items: [
            {'value': 'pending', 'label': 'Tiếp nhận'},
            {'value': 'in_progress', 'label': 'Đang sửa'},
            {'value': 'resolved', 'label': 'Đã xong'},
          ].map<DropdownMenuItem<String>>((Map<String, String> item) {
            return DropdownMenuItem<String>(
              value: item['value']!,
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: _getStatusColor(item['value'])),
                  const SizedBox(width: 12),
                  Text(item['label']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Row(
      children: [
        _buildTimelinePoint('Tiếp nhận', _currentStatus == 'pending' || _currentStatus == 'in_progress' || _currentStatus == 'resolved'),
        _buildTimelineLine(_currentStatus == 'in_progress' || _currentStatus == 'resolved'),
        _buildTimelinePoint('Đang sửa', _currentStatus == 'in_progress' || _currentStatus == 'resolved'),
        _buildTimelineLine(_currentStatus == 'resolved'),
        _buildTimelinePoint('Hoàn thành', _currentStatus == 'resolved'),
      ],
    );
  }

  Widget _buildTimelinePoint(String label, bool isCompleted) {
    Color pointColor = isCompleted ? _getStatusColor(_currentStatus) : Colors.grey.shade300;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: pointColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: pointColor, width: 2),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle_outlined,
              color: pointColor,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: pointColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isCompleted) {
    return Container(width: 30, height: 2, color: isCompleted ? _getStatusColor(_currentStatus) : Colors.grey.shade200);
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }

  Widget _buildBottomButton() {
    bool hasChanged = _currentStatus != issue.status;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: hasChanged ? ManagerColors.primaryGreen : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(16),
          boxShadow: hasChanged ? [BoxShadow(color: ManagerColors.primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))] : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (hasChanged && !_isUpdating) ? _updateStatus : null,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isUpdating)
                  const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else ...[
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Cập nhật trạng thái', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
