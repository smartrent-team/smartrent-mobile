import 'package:flutter/material.dart';
import 'package:smartrent_mobile/core/contract/presentation/contract_cancellation_section.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';
import 'package:smartrent_mobile/manager/features/tenant/domain/models/tenant_detail.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/pages/edit_tenant_page.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/widgets/change_room_sheet.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/widgets/leave_room_sheet.dart';
import 'package:smartrent_mobile/tenant/features/contract/data/contract_repository.dart';
import 'package:smartrent_mobile/tenant/features/contract/domain/models/contract_model.dart';

class TenantDetailPage extends StatefulWidget {
  final int tenantId;

  const TenantDetailPage({super.key, required this.tenantId});

  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> {
  final TenantService _tenantService = TenantService();
  final ContractRepository _contractRepository = ContractRepository();

  TenantDetail? _detail;
  ContractModel? _contract;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail({bool bustCache = false, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _tenantService.getTenantDetail(
        widget.tenantId,
        bustCache: bustCache,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final detail = TenantDetail.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        ContractModel? contract;
        try {
          contract = await _contractRepository.fetchContractByTenantId(
            widget.tenantId,
            bustCache: bustCache,
          );
        } catch (_) {
          contract = null;
        }
        setState(() {
          _detail = detail;
          _contract = contract;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.data['error']?.toString() ?? 'Không thể tải chi tiết cư dân';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Không thể kết nối máy chủ. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadContract() async {
    try {
      final contract = await _contractRepository.fetchContractByTenantId(
        widget.tenantId,
        bustCache: true,
      );
      if (!mounted) return;
      setState(() => _contract = contract);
      await _loadDetail();
    } catch (_) {
      if (!mounted) return;
      await _loadDetail();
    }
  }

  String _formatPhone(String phone) {
    final formatted = ManagerAppHeader.formatPhoneDisplay(phone);
    return formatted.isNotEmpty ? formatted : phone;
  }

  String _formatMoney(int amount) {
    final raw = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer}đ';
  }

  void _applyRoomChangeResult(Map<String, dynamic> result) {
    if (_detail == null) return;

    final imagesRaw = result['contractImages'];
    final images = imagesRaw is List
        ? imagesRaw.map((e) => e.toString()).where((u) => u.isNotEmpty).toList()
        : _detail!.contractImages;

    setState(() {
      _detail = _detail!.copyWith(
        roomId: (result['newRoomId'] as num?)?.toInt() ?? _detail!.roomId,
        roomLabel: result['roomLabel']?.toString() ?? _detail!.roomLabel,
        checkInDate: result['checkInDate']?.toString() ?? _detail!.checkInDate,
        contractSignDate: result['checkInDate']?.toString() ?? _detail!.checkInDate,
        contractImages: images,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ManagerColors.primaryGreen),
            )
          : _errorMessage != null
              ? _buildError()
              : _detail == null
                  ? const SizedBox.shrink()
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context, _detail!),
                              const SizedBox(height: 20),
                              _buildPersonalInfoSection(_detail!),
                              const SizedBox(height: 24),
                              _buildRentalInfoSection(_detail!),
                              const SizedBox(height: 24),
                              _buildContractSection(_detail!),
                              if (_contract != null && _contract!.isActive) ...[
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: ContractCancellationSection(
                                    contract: _contract!,
                                    viewerRole: 'manager',
                                    primaryColor: ManagerColors.primaryGreen,
                                    backgroundTint: ManagerColors.bgMint,
                                    onChanged: _reloadContract,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              const Center(
                                child: Text(
                                  '© 2025 RMS · Phiên bản 2.4.1',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ManagerColors.textGrey,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 160),
                            ],
                          ),
                        ),
                        if (_detail != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _buildBottomActions(_detail!),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildBottomActions(TenantDetail detail) {
    // Lấy trạng thái yêu cầu trả phòng và số ngày còn lại
    final checkoutStatus = detail.checkoutRequestStatus;
    final remaining = detail.remainingContractDays;

    // Tình huống: Cư dân đã gửi yêu cầu, Manager chưa xác nhận
    final hasPendingRequest = checkoutStatus == 'requested';
    final isCheckoutPaymentBlocked =
        hasPendingRequest && detail.checkoutPaymentBlocked;
    // Tình huống: Đã xác nhận, chờ hệ thống xử lý khi hợp đồng hết hạn
    final isConfirmed = checkoutStatus == 'confirmed';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: ManagerColors.bgLightGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ------ Banner thông báo khi có yêu cầu trả phòng ------
            if (hasPendingRequest || isConfirmed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isCheckoutPaymentBlocked
                      ? Colors.red.shade50
                      : hasPendingRequest
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCheckoutPaymentBlocked
                        ? Colors.red.shade200
                        : hasPendingRequest
                        ? Colors.orange.shade200
                        : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasPendingRequest
                          ? isCheckoutPaymentBlocked
                              ? Icons.receipt_long_outlined
                              : Icons.notifications_active_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                      color: isCheckoutPaymentBlocked
                          ? Colors.red.shade700
                          : hasPendingRequest
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasPendingRequest
                            ? isCheckoutPaymentBlocked
                                ? 'Phòng chỉ còn cư dân này và còn ${detail.checkoutUnpaidInvoiceCount} hóa đơn chưa thanh toán (${_formatMoney(detail.checkoutUnpaidInvoiceTotal)}). Cần thanh toán trước khi xác nhận.'
                                : 'Cư dân đã gửi yêu cầu trả phòng. Vui lòng xác nhận.'
                            : remaining != null && remaining > 0
                                ? 'Yêu cầu đã xác nhận. Còn $remaining ngày đến hết HĐ.'
                                : 'Yêu cầu đã xác nhận. Hệ thống sẽ tự động xử lý thủ tục trả phòng.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isCheckoutPaymentBlocked
                              ? Colors.red.shade800
                              : hasPendingRequest
                              ? Colors.orange.shade800
                              : Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (detail.isActive) ...[
              Row(
                children: [
                  // Nút Đổi Phòng — ẩn nếu đang có yêu cầu trả phòng
                  if (!hasPendingRequest && !isConfirmed) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await ChangeRoomSheet.show(
                            context,
                            tenantId: widget.tenantId,
                            tenantName: detail.name,
                            currentRoomId: detail.roomId,
                            currentRoomLabel: detail.roomLabel,
                          );
                          if (result != null && mounted) {
                            _applyRoomChangeResult(result);
                            await _loadDetail(bustCache: true, silent: true);
                            AppEventBus.instance.fire(AppEvent.tenantChanged);
                            AppEventBus.instance.fire(AppEvent.roomChanged);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã đổi phòng thành công!'),
                                backgroundColor: ManagerColors.primaryGreen,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.swap_horiz, size: 20),
                        label: const Text('Đổi phòng'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ManagerColors.primaryGreen,
                          side: const BorderSide(color: ManagerColors.primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // --- Nút hành động chính phía phải ---
                  Expanded(
                    child: hasPendingRequest
                        // [1] Cư dân gửi yêu cầu → hiện nút XÁC NHẬN
                        ? isCheckoutPaymentBlocked
                            ? ElevatedButton.icon(
                                onPressed: _sendingPaymentReminder
                                    ? null
                                    : _sendCheckoutPaymentReminder,
                                icon: _sendingPaymentReminder
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 20),
                                label: Text(
                                  _sendingPaymentReminder ? 'Đang gửi...' : 'Yêu cầu thanh toán hóa đơn',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _confirmingCheckout ? null : () => _confirmCheckout(detail),
                                icon: _confirmingCheckout
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                label: Text(
                                  _confirmingCheckout ? 'Xử lý...' : 'Xác nhận yêu cầu trả phòng',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              )
                        : isConfirmed
                            ? OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.hourglass_top, size: 20),
                                label: Text(
                                  remaining != null && remaining > 0
                                      ? 'Chờ hết hạn ($remaining ngày)'
                                      : 'Chờ cron xử lý trả phòng',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey,
                                  side: const BorderSide(color: Colors.grey),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              )
                            // [3] Bình thường → nút TRẢ PHÒNG thông thường
                            : OutlinedButton.icon(
                                onPressed: () async {
                                  final left = await LeaveRoomSheet.show(
                                    context,
                                    tenantId: widget.tenantId,
                                    tenantName: detail.name,
                                    roomLabel: detail.roomLabel,
                                  );
                                  if (left == true && mounted) {
                                    _loadDetail();
                                    AppEventBus.instance.fire(AppEvent.tenantChanged);
                                    AppEventBus.instance.fire(AppEvent.roomChanged);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã xử lý trả phòng thành công!'),
                                        backgroundColor: ManagerColors.primaryGreen,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.logout, size: 20),
                                label: const Text('Trả phòng'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade400),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updated = await context.pushSlide<bool>(
                    EditTenantPage(tenantId: widget.tenantId),
                  );
                  if (updated == true && mounted) {
                    _loadDetail();
                  }
                },
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                label: const Text(
                  'Sửa thông tin cư dân',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ManagerColors.primaryGreen,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _confirmingCheckout = false;
  bool _sendingPaymentReminder = false;

  Future<void> _confirmCheckout(TenantDetail detail) async {
    setState(() => _confirmingCheckout = true);
    try {
      final response = await _tenantService.confirmCheckout(widget.tenantId);
      if (!mounted) return;
      if (response.statusCode == 200 && response.data['success'] == true) {
        AppEventBus.instance.fire(AppEvent.tenantChanged);
        AppEventBus.instance.fire(AppEvent.roomChanged);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận yêu cầu trả phòng thành công!'),
            backgroundColor: ManagerColors.primaryGreen,
          ),
        );
        await _loadDetail(bustCache: true, silent: true);
      } else {
        final errMsg = response.data['error']?.toString() ?? 'Không thể xác nhận.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối. Vui lòng thử lại.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _confirmingCheckout = false);
    }
  }

  Future<void> _sendCheckoutPaymentReminder() async {
    setState(() => _sendingPaymentReminder = true);
    try {
      final response = await _tenantService.sendCheckoutPaymentReminder(widget.tenantId);
      if (!mounted) return;

      if (response.statusCode == 200 && response.data['success'] == true) {
        final stillBlocked = response.data['paymentBlocked'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message']?.toString() ??
                  (stillBlocked
                      ? 'Đã gửi thông báo yêu cầu thanh toán hóa đơn.'
                      : 'Hóa đơn đã được thanh toán. Có thể xác nhận trả phòng.'),
            ),
            backgroundColor: stillBlocked ? ManagerColors.primaryGreen : Colors.blue.shade700,
          ),
        );
        await _loadDetail(bustCache: true, silent: true);
      } else {
        final errMsg = response.data['error']?.toString() ?? 'Không thể gửi thông báo.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối. Vui lòng thử lại.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sendingPaymentReminder = false);
    }
  }

  Future<void> _onBlockTenant(TenantDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Khóa tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn khóa tài khoản của ${detail.name}?\nCư dân sẽ không thể đăng nhập vào ứng dụng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ', style: TextStyle(color: ManagerColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Khóa',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await _tenantService.updateTenantStatus(widget.tenantId, 'block');
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã khóa tài khoản ${detail.name}'),
            backgroundColor: ManagerColors.primaryGreen,
          ),
        );
        _loadDetail(bustCache: true);
        AppEventBus.instance.fire(AppEvent.tenantChanged);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thao tác thất bại. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: ManagerColors.primaryGreen,
              ),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TenantDetail detail) {
    final statusColor = detail.isActive ? Colors.white : Colors.white70;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: ManagerColors.primaryGreen),
      child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Text(
                      'Chi tiết cư dân',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    detail.statusLabel == 'Khóa'
                        ? const SizedBox(width: 44)
                        : Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
                              onSelected: (val) {
                                if (val == 'block') {
                                  _onBlockTenant(detail);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'block',
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_outline, color: Colors.red, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Khóa tài khoản',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        detail.initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (detail.isRoomHead)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Chủ phòng',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (detail.isRoomHead) const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      detail.statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildPersonalInfoSection(TenantDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline, color: ManagerColors.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'THÔNG TIN CÁ NHÂN',
                style: TextStyle(
                  color: ManagerColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: ManagerColors.cardShadow,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.person_outline,
                  label: 'HỌ VÀ TÊN',
                  valueWidget: Text(
                    detail.name,
                    style: const TextStyle(
                      color: ManagerColors.textCharcoal,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.phone_outlined,
                  label: 'SỐ ĐIỆN THOẠI',
                  valueWidget: Text(
                    _formatPhone(detail.phone),
                    style: const TextStyle(
                      color: ManagerColors.primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (detail.email != null && detail.email!.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.email_outlined,
                    label: 'EMAIL',
                    valueWidget: Text(
                      detail.email!,
                      style: const TextStyle(
                        color: ManagerColors.textCharcoal,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                _buildDetailRow(
                  icon: Icons.assignment_ind_outlined,
                  label: 'CCCD / CMND',
                  valueWidget: Text(
                    (detail.identityNumber != null && detail.identityNumber!.isNotEmpty)
                        ? detail.identityNumber!
                        : 'Chưa cập nhật',
                    style: const TextStyle(
                      color: ManagerColors.textCharcoal,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalInfoSection(TenantDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.home_outlined, color: ManagerColors.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'THÔNG TIN THUÊ PHÒNG',
                style: TextStyle(
                  color: ManagerColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: ManagerColors.cardShadow,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.meeting_room_outlined,
                  label: 'PHÒNG ĐANG THUÊ',
                  valueWidget: Text(
                    detail.roomLabel,
                    style: const TextStyle(
                      color: ManagerColors.textCharcoal,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'NGÀY DỌN VÀO',
                  valueWidget: Text(
                    detail.checkInDate,
                    style: const TextStyle(
                      color: ManagerColors.textCharcoal,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.text_snippet_outlined,
                  label: 'HỢP ĐỒNG HIỆN HÀNH',
                  valueWidget: Text(
                    'Hợp đồng mới nhất đang hiệu lực',
                    style: const TextStyle(
                      color: ManagerColors.primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (detail.moveOutDate != null)
                  _buildDetailRow(
                    icon: Icons.logout_outlined,
                    label: 'NGÀY TRẢ PHÒNG',
                    valueWidget: Text(
                      detail.moveOutDate!,
                      style: const TextStyle(
                        color: ManagerColors.textCharcoal,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                _buildDetailRow(
                  icon: Icons.check_circle_outline,
                  label: 'TRẠNG THÁI THUÊ',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: detail.isActive
                              ? ManagerColors.bgMint
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: detail.isActive
                                    ? ManagerColors.primaryGreen
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              detail.statusLabel,
                              style: TextStyle(
                                color: detail.isActive
                                    ? ManagerColors.primaryGreen
                                    : Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractSection(TenantDetail detail) {
    final images = detail.contractImages;
    final countLabel = images.isEmpty ? '0 ảnh' : '${images.length} ảnh';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.text_snippet_outlined,
                      color: ManagerColors.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'HỢP ĐỒNG GIẤY',
                    style: TextStyle(
                      color: ManagerColors.textGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ManagerColors.bgMint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  countLabel,
                  style: const TextStyle(
                    color: ManagerColors.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: ManagerColors.cardShadow,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (images.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Chưa có ảnh hợp đồng',
                      style: TextStyle(color: ManagerColors.textGrey, fontSize: 14),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: List.generate(
                        images.length > 3 ? 3 : images.length,
                        (index) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                              child: _buildContractImage(
                                images[index],
                                'Trang ${index + 1}',
                                key: ValueKey('contract-${images[index]}'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (images.isNotEmpty) ...[
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  InkWell(
                    onTap: () => _showContractGallery(context, images),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.image_outlined,
                            color: ManagerColors.primaryGreen,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Xem ảnh hợp đồng',
                            style: TextStyle(
                              color: ManagerColors.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.chevron_right,
                            color: ManagerColors.primaryGreen,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContractGallery(BuildContext context, List<String> images) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ảnh hợp đồng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: images.length,
                  itemBuilder: (_, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          images[index],
                          key: ValueKey('gallery-${images[index]}'),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractImage(String imageUrl, String label, {Key? key}) {
    return AspectRatio(
      key: key,
      aspectRatio: 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              key: ValueKey('contract-thumb-$imageUrl'),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: ManagerColors.bgMint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: ManagerColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: ManagerColors.textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    valueWidget,
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 72, right: 16),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
      ],
    );
  }
}
