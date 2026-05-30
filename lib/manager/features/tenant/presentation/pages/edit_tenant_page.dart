import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';
import 'package:smartrent_mobile/manager/features/tenant/domain/models/tenant_detail.dart';

class EditTenantPage extends StatefulWidget {
  final int tenantId;

  const EditTenantPage({super.key, required this.tenantId});

  @override
  State<EditTenantPage> createState() => _EditTenantPageState();
}

class _EditTenantPageState extends State<EditTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final TenantService _tenantService = TenantService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _headerInitial = 'C';
  String _headerName = '';
  String _headerRoomLabel = '';
  String? _roomCode;
  int? _floor;
  DateTime? _moveInDate;

  String _selectedStatus = 'Đang thuê';
  final List<String> _contractImageUrls = [];

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
        final detail = TenantDetail.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _applyDetail(detail);
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _errorMessage =
              response.data['error']?.toString() ?? 'Không thể tải thông tin cư dân';
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

  void _applyDetail(TenantDetail detail) {
    _headerInitial = detail.initial;
    _headerName = detail.name;
    _headerRoomLabel = detail.roomLabel;
    _roomCode = detail.roomCode;
    _floor = detail.floor;
    _nameController.text = detail.name;
    _phoneController.text = _phoneForEdit(detail.phone);
    _moveInDate = _parseViDate(detail.checkInDate);
    if (_moveInDate != null) {
      _dateController.text = _formatDateForField(_moveInDate!);
    } else if (detail.checkInDate != 'Chưa cập nhật') {
      _dateController.text = detail.checkInDate;
    }
    _selectedStatus = detail.isActive ? 'Đang thuê' : 'Đã trả phòng';
    _contractImageUrls
      ..clear()
      ..addAll(detail.contractImages);
  }

  String _phoneForEdit(String phone) {
    if (phone == 'Chưa cập nhật') return '';
    final digits = phone.replaceAll(RegExp(r'\s'), '');
    if (digits.startsWith('+84') && digits.length > 3) {
      return '0${digits.substring(3)}';
    }
    return digits;
  }

  DateTime? _parseViDate(String value) {
    if (value.isEmpty || value == 'Chưa cập nhật') return null;
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0].trim());
    final month = int.tryParse(parts[1].trim());
    final year = int.tryParse(parts[2].trim());
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _formatDateForField(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final response = await _tenantService.updateTenant(widget.tenantId, {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim().replaceAll(RegExp(r'\s'), ''),
        'moveInDate': _dateController.text.trim(),
        'isActive': _selectedStatus == 'Đang thuê',
        'contractImages': _contractImageUrls,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin cư dân thành công!'),
            backgroundColor: ManagerColors.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      final message =
          response.data['error']?.toString() ?? 'Không thể lưu thông tin cư dân';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data['error']?.toString() ??
              'Không thể lưu thông tin cư dân')
          : 'Không thể kết nối máy chủ. Vui lòng thử lại.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ManagerColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: ManagerColors.textCharcoal,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ManagerColors.primaryGreen,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _moveInDate = picked;
        _dateController.text = _formatDateForField(picked);
      });
    }
  }

  void _addNewContractPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload ảnh từ app sẽ được bổ sung sau. Bạn có thể xóa ảnh hiện có.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeContractPhoto(int index) {
    setState(() {
      _contractImageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: ManagerColors.bgLightGreen,
        body: Center(
          child: CircularProgressIndicator(color: ManagerColors.primaryGreen),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: ManagerColors.bgLightGreen,
        appBar: AppBar(
          backgroundColor: ManagerColors.primaryGreen,
          foregroundColor: Colors.white,
          title: const Text('Sửa thông tin cư dân'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ManagerColors.textCharcoal),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDetail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ManagerColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Profile Header
                  _buildHeader(context),
                  const SizedBox(height: 20),

                  // 2. Personal Information Section
                  _buildPersonalInfoForm(context),
                  const SizedBox(height: 24),

                  // 3. Contract Photo Upload Section
                  _buildContractSection(),
                  const SizedBox(height: 24),

                  // 4. Fixed Location Info Card
                  _buildFixedLocationCard(),
                  const SizedBox(height: 24),

                  // 5. Footer Text
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
                  const SizedBox(height: 100), // Height buffer for fixed action button
                ],
              ),
            ),
          ),
        ],
      ),
      // 6. Fixed Bottom Action Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check, color: Colors.white, size: 20),
          label: Text(
            _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ManagerColors.primaryGreen,
            elevation: 8,
            shadowColor: ManagerColors.primaryGreen.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: ManagerColors.primaryGreen,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Text(
                      "Sửa thông tin cư dân",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 44), // Symmetry placeholder
                  ],
                ),
                const SizedBox(height: 24),

                // Profile Quick Summary
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _headerInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
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
                            _headerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _headerRoomLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
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
        ),
      ),
    );
  }

  Widget _buildPersonalInfoForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Section Title Header
          Row(
            children: const [
              Icon(Icons.person_outline, color: ManagerColors.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                "THÔNG TIN CÁ NHÂN",
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

          // Cards with custom light green input container borders
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
                // Field 1: Họ và tên
                _buildFormInputWrapper(
                  label: "Họ và tên",
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin_outlined, color: ManagerColors.primaryGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                            color: ManagerColors.primaryGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Họ và tên không được trống';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Field 2: Số điện thoại
                _buildFormInputWrapper(
                  label: "Số điện thoại",
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: ManagerColors.primaryGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: ManagerColors.primaryGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Số điện thoại không được trống';
                            }
                            if (value.trim().length < 9) {
                              return 'Số điện thoại không hợp lệ';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Field 3: Ngày dọn vào
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildFormInputWrapper(
                    label: "Ngày dọn vào",
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, color: ManagerColors.primaryGreen, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: IgnorePointer(
                            child: TextFormField(
                              controller: _dateController,
                              style: const TextStyle(
                                color: ManagerColors.primaryGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng chọn ngày';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined, color: ManagerColors.textGrey, size: 16),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Field 4: Trạng thái thuê
                _buildFormInputWrapper(
                  label: "Trạng thái thuê",
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedStatus = newValue;
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: "Đang thuê",
                        child: Text("Đang thuê"),
                      ),
                      DropdownMenuItem(
                        value: "Đã trả phòng",
                        child: Text("Đã trả phòng"),
                      ),
                    ],
                    style: const TextStyle(
                      color: ManagerColors.primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: ManagerColors.textGrey),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.check_circle_outline, color: ManagerColors.primaryGreen, size: 20),
                      prefixIconConstraints: BoxConstraints(minWidth: 32, maxHeight: 20),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormInputWrapper({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ManagerColors.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ManagerColors.fieldBgTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ManagerColors.primaryGreen.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildContractSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Section Title Row with Image count badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.text_snippet_outlined, color: ManagerColors.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "HỢP ĐỒNG GIẤY",
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
                  '${_contractImageUrls.length} ảnh',
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

          // Contract Card container containing the images, action button and description
          Container(
            padding: const EdgeInsets.all(16),
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
                // Horizontal scrollable contract images with overlays
                if (_contractImageUrls.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "Không có ảnh hợp đồng nào",
                        style: TextStyle(color: ManagerColors.textGrey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Row(
                    children: List.generate(_contractImageUrls.length, (index) {
                      final url = _contractImageUrls[index];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == _contractImageUrls.length - 1 ? 0 : 12.0,
                          ),
                          child: _buildInteractiveContractImage(
                            index,
                            url,
                            'Trang ${index + 1}',
                          ),
                        ),
                      );
                    }),
                  ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 16),

                // Outlined add photo button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _addNewContractPhoto,
                    icon: const Icon(Icons.add, color: ManagerColors.primaryGreen, size: 20),
                    label: const Text(
                      "Thêm ảnh hợp đồng",
                      style: TextStyle(
                        color: ManagerColors.primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ManagerColors.primaryGreen.withOpacity(0.3), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Guide hint caption
                const Text(
                  "Chụp hoặc chọn ảnh từ thư viện. Mỗi trang hợp đồng thêm một ảnh riêng.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ManagerColors.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveContractImage(int index, String imageUrl, String label) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The main rounded contract image placeholder
          Positioned.fill(
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

                  // Dark semi-transparent bottom strip with label and action
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Xóa ảnh",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating circular red close button on top right corner
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _removeContractPhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
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
            // Read-Only field 1: Phòng
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: ManagerColors.bgMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home_work_outlined, color: ManagerColors.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phòng',
                          style: TextStyle(
                            color: ManagerColors.textGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _roomCode != null ? 'Phòng $_roomCode' : 'Chưa có phòng',
                          style: const TextStyle(
                            color: ManagerColors.textCharcoal,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "Không thể thay đổi",
                    style: TextStyle(
                      color: ManagerColors.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 72, right: 16),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),

            // Read-Only field 2: Tầng
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: ManagerColors.bgMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.layers_outlined, color: ManagerColors.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tầng',
                          style: TextStyle(
                            color: ManagerColors.textGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _floor != null ? 'Tầng $_floor' : '—',
                          style: const TextStyle(
                            color: ManagerColors.textCharcoal,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "Không thể thay đổi",
                    style: TextStyle(
                      color: ManagerColors.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Beautiful Quadratic Bezier Curve Clipper for Header
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
