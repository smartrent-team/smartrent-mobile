import 'package:flutter/material.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';
import 'package:smartrent_mobile/manager/features/tenant/domain/models/tenant_detail.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/pages/edit_tenant_page.dart';

class TenantDetailPage extends StatefulWidget {
  final int tenantId;

  const TenantDetailPage({super.key, required this.tenantId});

  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> {
  final TenantService _tenantService = TenantService();

  TenantDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _tenantService.getTenantDetail(widget.tenantId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _detail = TenantDetail.fromJson(
            response.data['data'] as Map<String, dynamic>,
          );
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

  String _formatPhone(String phone) {
    final formatted = ManagerAppHeader.formatPhoneDisplay(phone);
    return formatted.isNotEmpty ? formatted : phone;
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
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _detail == null
          ? null
          : Container(
              width: double.infinity,
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ManagerColors.primaryGreen,
                  elevation: 8,
                  shadowColor: ManagerColors.primaryGreen.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
              ),
            ),
    );
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

    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
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
                    const SizedBox(width: 44),
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
                  valueWidget: const Text(
                    'Chưa cập nhật',
                    style: TextStyle(
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
                  label: 'KÝ HỢP ĐỒNG GIẤY',
                  valueWidget: Text(
                    detail.contractSignDate ?? detail.checkInDate,
                    style: const TextStyle(
                      color: ManagerColors.textCharcoal,
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

  Widget _buildContractImage(String imageUrl, String label) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
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

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 32);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 32,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
