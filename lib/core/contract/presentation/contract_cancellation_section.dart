import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/core/contract/data/contract_cancellation_service.dart';
import 'package:smartrent_mobile/core/contract/domain/contract_cancellation_request.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';
import 'package:smartrent_mobile/tenant/features/contract/domain/models/contract_model.dart';

class ContractCancellationSection extends StatefulWidget {
  final ContractModel contract;
  final String viewerRole;
  final Color primaryColor;
  final Color backgroundTint;
  final VoidCallback onChanged;

  const ContractCancellationSection({
    super.key,
    required this.contract,
    required this.viewerRole,
    required this.primaryColor,
    required this.backgroundTint,
    required this.onChanged,
  });

  @override
  State<ContractCancellationSection> createState() =>
      _ContractCancellationSectionState();
}

class _ContractCancellationSectionState
    extends State<ContractCancellationSection> {
  final ContractCancellationService _service = ContractCancellationService();
  bool _isSubmitting = false;

  ContractCancellationRequest? get _request =>
      widget.contract.cancellationRequest;

  bool get _isPending => _request?.isPending ?? false;

  bool get _requestedByMe =>
      _isPending && (_request?.isRequestedBy(widget.viewerRole) ?? false);

  bool get _canRespond =>
      _isPending && !(_request?.isRequestedBy(widget.viewerRole) ?? false);

  int get _contractId => int.tryParse(widget.contract.contractId) ?? 0;

  Future<void> _showReasonDialog() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Yêu cầu hủy hợp đồng',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vui lòng nhập lý do hủy hợp đồng. Yêu cầu sẽ được gửi tới bên còn lại để xác nhận.',
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Nhập lý do hủy hợp đồng...',
                filled: true,
                fillColor: widget.backgroundTint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do hủy hợp đồng')),
                );
                return;
              }
              Navigator.pop(ctx, text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Gửi yêu cầu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;
    await _submitRequest(reason);
  }

  Future<void> _submitRequest(String reason) async {
    if (_contractId <= 0) {
      _showError('Không xác định được hợp đồng');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _service.requestCancellation(
        contractId: _contractId,
        reason: reason,
      );
      final data = response.data;
      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        AppEventBus.instance.fire(AppEvent.contractChanged);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message']?.toString() ??
                    'Đã gửi yêu cầu hủy hợp đồng. Đang chờ bên còn lại xử lý.',
              ),
              backgroundColor: widget.primaryColor,
            ),
          );
          widget.onChanged();
        }
        return;
      }

      final message = data is Map
          ? data['error']?.toString() ?? 'Không thể gửi yêu cầu hủy hợp đồng'
          : 'Không thể gửi yêu cầu hủy hợp đồng';
      _showError(message);
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final message = errorData is Map
          ? errorData['error']?.toString() ?? 'Không thể gửi yêu cầu hủy hợp đồng'
          : 'Không thể kết nối máy chủ. Vui lòng thử lại.';
      _showError(message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _respond(String action) async {
    if (_contractId <= 0) {
      _showError('Không xác định được hợp đồng');
      return;
    }

    final isApprove = action == 'approve';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isApprove ? 'Đồng ý hủy hợp đồng?' : 'Từ chối yêu cầu hủy?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          isApprove
              ? 'Hợp đồng sẽ chuyển sang trạng thái Đã hủy sau khi bạn xác nhận.'
              : 'Hợp đồng sẽ tiếp tục ở trạng thái Đang hiệu lực.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.redAccent : widget.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isApprove ? 'Đồng ý' : 'Từ chối',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _service.respondCancellation(
        contractId: _contractId,
        action: action,
      );
      final data = response.data;
      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        AppEventBus.instance.fire(AppEvent.contractChanged);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message']?.toString() ??
                    (isApprove
                        ? 'Hợp đồng đã được hủy.'
                        : 'Đã từ chối yêu cầu hủy hợp đồng.'),
              ),
              backgroundColor: widget.primaryColor,
            ),
          );
          widget.onChanged();
        }
        return;
      }

      final message = data is Map
          ? data['error']?.toString() ?? 'Không thể xử lý yêu cầu'
          : 'Không thể xử lý yêu cầu';
      _showError(message);
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final message = errorData is Map
          ? errorData['error']?.toString() ?? 'Không thể xử lý yêu cầu'
          : 'Không thể kết nối máy chủ. Vui lòng thử lại.';
      _showError(message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.contract.isActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _canRespond
              ? Colors.orange.shade200
              : _requestedByMe
                  ? Colors.blue.shade100
                  : Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _canRespond
                    ? Icons.pending_actions_rounded
                    : Icons.gavel_outlined,
                color: _canRespond ? Colors.orangeAccent : widget.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Hủy hợp đồng 2 phía',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isPending) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _canRespond
                    ? Colors.orange.shade50
                    : widget.backgroundTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _requestedByMe
                        ? 'Đang chờ đối phương xử lý yêu cầu hủy hợp đồng của bạn.'
                        : '${_request!.requesterLabel(widget.viewerRole)} đã gửi yêu cầu hủy hợp đồng.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _canRespond ? Colors.orange.shade900 : Colors.black87,
                    ),
                  ),
                  if (_request!.reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Lý do: ${_request!.reason}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            const Text(
              'Gửi yêu cầu hủy hợp đồng. Bên còn lại cần đồng ý trước khi hợp đồng bị hủy.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          if (_canRespond)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => _respond('reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.primaryColor,
                      side: BorderSide(color: widget.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _respond('approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Đồng ý',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || _requestedByMe)
                    ? null
                    : _showReasonDialog,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
                label: Text(
                  _requestedByMe
                      ? 'Đã gửi yêu cầu hủy'
                      : 'Yêu cầu hủy hợp đồng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _requestedByMe ? Colors.grey : Colors.redAccent,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
