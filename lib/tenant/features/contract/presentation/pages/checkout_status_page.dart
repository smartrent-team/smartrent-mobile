import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/core/utils/vn_date.dart';

class CheckoutStatusPage extends StatefulWidget {
  const CheckoutStatusPage({super.key});

  @override
  State<CheckoutStatusPage> createState() => _CheckoutStatusPageState();
}

class _CheckoutStatusPageState extends State<CheckoutStatusPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _checkoutData;
  Map<String, dynamic>? _settlementData;

  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchCheckoutStatus();
  }

  Future<void> _fetchCheckoutStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ApiClient().dio;
      final res = await dio.get('/api/tenants/me/checkout-status');
      
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'];
        setState(() {
          _checkoutData = data;
          if (data['checkout_settlements'] != null && (data['checkout_settlements'] as List).isNotEmpty) {
            _settlementData = (data['checkout_settlements'] as List).first;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.data['error']?.toString() ?? 'Không thể tải dữ liệu';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['error']?.toString() ?? 'Lỗi kết nối máy chủ';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi không xác định';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmSettlement(bool isConfirm) async {
    String? disputeReason;

    if (!isConfirm) {
      disputeReason = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Lý do khiếu nại', style: TextStyle(fontSize: 16)),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do chi tiết...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Gửi'),
              ),
            ],
          );
        },
      );

      if (disputeReason == null || disputeReason.isEmpty) return;
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận quyết toán'),
          content: const Text('Bạn có chắc chắn đồng ý với bảng quyết toán này? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: TenantColors.primaryGreenAlt),
              child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final dio = ApiClient().dio;
      final res = await dio.post('/api/tenants/me/settlement/confirm', data: {
        'settlementId': _settlementData!['id'],
        'action': isConfirm ? 'confirm' : 'dispute',
        'disputeReason': disputeReason,
      });

      if (!mounted) return;
      Navigator.pop(context); // close loading

      if (res.statusCode == 200 && res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Thành công'), backgroundColor: Colors.green),
        );
        _fetchCheckoutStatus(); // reload data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['error'] ?? 'Lỗi'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiến độ trả phòng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: TenantColors.bgLightGreen,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: TenantColors.primaryGreenAlt))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_checkoutData == null) return const Center(child: Text('Không có dữ liệu'));

    final status = _checkoutData!['status'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusTimeline(status),
          const SizedBox(height: 24),
          if (_settlementData != null) _buildSettlementDetail(),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    final steps = [
      {'key': 'requested', 'label': 'Đã gửi yêu cầu'},
      {'key': 'inspecting', 'label': 'Đang kiểm tra'},
      {'key': 'pending_tenant_confirmation', 'label': 'Chờ xác nhận'},
      {'key': 'completed', 'label': 'Hoàn tất'},
    ];

    int currentIndex = steps.indexWhere((s) => s['key'] == status);
    if (status == 'pending_settlement') currentIndex = 1;
    if (status == 'disputed') currentIndex = 2; // Vẫn ở bước chờ xác nhận/xử lý

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạng thái hiện tại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Column(
            children: List.generate(steps.length, (index) {
              final isCompleted = index <= currentIndex;
              final isLast = index == steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted ? TenantColors.primaryGreenAlt : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 30,
                          color: isCompleted ? TenantColors.primaryGreenAlt : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      steps[index]['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementDetail() {
    final s = _settlementData!;
    final totalDebt = s['total_debt'] ?? 0;
    final deposit = s['deposit_amount'] ?? 0;
    final forfeited = s['deposit_forfeited'] ?? 0;
    final refund = s['deposit_refund'] ?? 0;
    final owes = s['amount_tenant_owes'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: TenantColors.primaryGreenAlt),
              const SizedBox(width: 8),
              const Text('Bảng quyết toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: s['status'] == 'completed' ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s['status'] == 'completed' ? 'Đã chốt' : (s['status'] == 'disputed' ? 'Đang khiếu nại' : 'Chờ xác nhận'),
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: s['status'] == 'completed' ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildRow('Tiền nhà còn nợ:', totalDebt > 0 ? _currency.format(s['unpaid_rent'] ?? 0) : '0đ'),
          _buildRow('Tiền điện nợ:', _currency.format(s['unpaid_electric'] ?? 0)),
          _buildRow('Tiền nước nợ:', _currency.format(s['unpaid_water'] ?? 0)),
          _buildRow('Chi phí sửa chữa:', _currency.format(s['damage_cost'] ?? 0)),
          const Divider(),
          _buildRow('Tổng nghĩa vụ (A):', _currency.format(totalDebt), isBold: true, color: Colors.red),
          const SizedBox(height: 16),
          _buildRow('Tiền cọc ban đầu:', _currency.format(deposit)),
          _buildRow('Cọc bị giữ (trả trước hạn):', _currency.format(forfeited)),
          const Divider(),
          _buildRow('Cọc còn lại để cấn trừ (B):', _currency.format(deposit - forfeited), isBold: true, color: Colors.blue),
          const SizedBox(height: 16),
          if (refund > 0)
            _buildRow('Số tiền bạn nhận lại (B - A):', _currency.format(refund), isBold: true, color: Colors.green),
          if (owes > 0)
            _buildRow('Số tiền bạn cần đóng thêm (A - B):', _currency.format(owes), isBold: true, color: Colors.red),
            
          if (s['status'] == 'pending_tenant_confirmation') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmSettlement(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Khiếu nại'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmSettlement(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TenantColors.primaryGreenAlt,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
          
          if (s['status'] == 'disputed') ...[
             const SizedBox(height: 16),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
               child: Text('Lý do khiếu nại: ${s['dispute_reason'] ?? ''}', style: TextStyle(color: Colors.red.shade900)),
             )
          ]
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
