import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/network/ai_contract_service.dart';
import 'package:smartrent_mobile/core/network/ai_cccd_service.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';
import 'package:smartrent_mobile/core/services/token_service.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/widgets/contract_photo_upload.dart';
import 'package:dio/dio.dart';

class AddTenantPage extends StatefulWidget {
  const AddTenantPage({super.key});

  @override
  State<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends State<AddTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cccdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _depositController = TextEditingController();
  final TenantService _tenantService = TenantService();
  final TokenService _tokenService = TokenService();
  final AiContractService _contractAiService = AiContractService();
  final AiCccdService _cccdService = AiCccdService();
  final ImagePicker _imagePicker = ImagePicker();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  
  String? _managedBranchId;

  String? _selectedRole = 'tenant';
  String? _selectedBranch;
  String? _selectedRoom;
  bool _isLoading = false;
  bool _isScanningCccd = false;
  bool _isScanningContract = false;
  bool _isFormValid = false;
  List<String> _contractImageUrls = [];
  DateTime? _contractEndDate;
  final _contractEndDateController = TextEditingController();
  bool _obscurePassword = true;
  bool _aiDetectedDate = false;
  bool _aiScanFailed = false;

  final List<Map<String, String>> _roles = [
    {'label': 'Cư dân', 'id': 'tenant'},
    {'label': 'Chủ hộ', 'id': 'owner'},
  ];

  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _initData();
  }

  Future<void> _initData() async {
    await _loadManagedBranch();
    await _fetchBranches();
  }

  Future<void> _loadManagedBranch() async {
    final bId = await _tokenService.getBranchId();
    if (mounted) {
      setState(() {
        _managedBranchId = bId;
        // If we have a managed branch ID, we use it as default
        if (_managedBranchId != null && _selectedBranch == null) {
          _selectedBranch = _managedBranchId;
        }
      });
      _validateForm();
    }
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    try {
      final response = await _tenantService.getBranches();
      if (response.statusCode == 200) {
        final List<dynamic> docs = response.data['docs'];
        setState(() {
          _branches = docs.map((doc) => {
            'label': doc['name'].toString(),
            'id': doc['id'], // Keep original type (likely int for Postgres)
          }).toList();
          
          // Filter branches to only show the branch managed by this manager
          if (_managedBranchId != null) {
            _branches = _branches.where((b) => b['id'].toString() == _managedBranchId.toString()).toList();
          }
          
          // Pre-select if only one branch or if it matches managed branch
          if (_branches.length == 1) {
            _selectedBranch = _branches[0]['id']?.toString();
          } else if (_managedBranchId != null) {
            _selectedBranch = _managedBranchId;
          }
        });

        if (_selectedBranch != null) {
          await _fetchRooms(_selectedBranch);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Fallback: if fetch fails but we have a managed branch ID, add it to the list
          if (_managedBranchId != null && _branches.isEmpty) {
            _branches = [
              {'label': 'Chi nhánh của tôi', 'id': _managedBranchId!},
            ];
            _selectedBranch = _managedBranchId;
          }
        });
        
        if (_selectedBranch != null) {
          await _fetchRooms(_selectedBranch);
        }
        
        // If we still don't have a branch ID, show error
        if (_managedBranchId == null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi lấy danh sách chi nhánh: $e')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchRooms(dynamic branchId) async {
    if (branchId == null) return;
    setState(() {
      _isLoading = true;
      _rooms = [];
      _selectedRoom = null;
    });
    try {
      final roomService = RoomService();
      final response = await roomService.getRooms(
        branchId: branchId.toString(),
        status: 'available',
        limit: 100,
      );
      if (response.statusCode == 200) {
        final List<dynamic> docs = response.data['docs'];
        setState(() {
          _rooms = docs.map((doc) => {
            'label': doc['roomCode'].toString(),
            'id': doc['id'],
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy danh sách phòng: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _validateForm();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cccdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _depositController.dispose();
    _contractEndDateController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _canSubmit;
    });
  }

  bool get _canSubmit {
    final isRoomValid = _selectedRole != 'tenant' || _selectedRoom != null;
    final isEmailValid = _emailController.text.trim().isEmpty ||
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim());

    final needsContract = _selectedRole == 'tenant' && _selectedRoom != null;
    final contractOk = !needsContract || _contractImageUrls.isNotEmpty;

    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _selectedBranch != null &&
        isRoomValid &&
        isEmailValid &&
        contractOk;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    var tenantCreated = false;

    try {
      final response = await _tenantService.addTenant(
        phone: _phoneController.text.trim(),
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        branch: _selectedBranch!,
        role: _selectedRole ?? 'tenant',
        roomId: _selectedRoom,
        identityNumber: _cccdController.text.trim(),
        contractImages: _contractImageUrls.isNotEmpty ? _contractImageUrls : null,
        contractEndDate: _contractEndDate?.toIso8601String(),
        depositAmount: _depositController.text.trim().isNotEmpty
            ? int.tryParse(_depositController.text.trim())
            : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        tenantCreated = true;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm cư dân thành công!'),
            backgroundColor: ManagerColors.primaryGreen,
          ),
        );
        Navigator.pop(context, {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });
        return;
      }

      throw Exception(response.data['error'] ?? 'Không thể tạo cư dân');
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          if (data.containsKey('error')) {
            errMsg = data['error'].toString();
          }
          if (data['details'] != null) {
            errMsg = '$errMsg (${data['details']})';
          }
        }
      }
      if (mounted) {
        final message = tenantCreated
            ? 'Đã tạo cư dân nhưng không lưu được ảnh hợp đồng: $errMsg'
            : 'Lỗi: $errMsg';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: tenantCreated ? Colors.orange : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanCccd() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh CCCD'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null || !mounted) return;

      setState(() => _isScanningCccd = true);

      final bytes = await picked.readAsBytes();
      final result = await _cccdService.scanFromBytes(bytes);

      if (!mounted) return;
      setState(() {
        _nameController.text = result.fullName;
        _cccdController.text = result.cccdNumber;
        _isScanningCccd = false;
      });
      _validateForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã quét CCCD và điền thông tin'),
          backgroundColor: ManagerColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanningCccd = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _scanContractExpiryBatch(
    List<List<int>> imageBytesList,
    List<String> _,
  ) async {
    if (!mounted) return;

    setState(() {
      _isScanningContract = true;
      _aiScanFailed = false;
    });

    try {
      final result = await _contractAiService.scanFromBytesBatch(imageBytesList);
      final parsedDate = result.parsedDate;

      if (!mounted) return;

      if (parsedDate != null) {
        setState(() {
          _contractEndDate = parsedDate;
          _contractEndDateController.text =
              _dateFormat.format(parsedDate.toLocal());
          _aiDetectedDate = true;
          _aiScanFailed = false;
        });
        return;
      }

      throw Exception('Không đọc được ngày hết hạn từ ảnh hợp đồng');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiScanFailed = true;
      });
      if (_contractEndDate != null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI không nhận diện được ngày hết hạn. Vui lòng chọn thủ công.'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isScanningContract = false);
      }
    }
  }

  Future<void> _pickContractEndDate() async {
    final initialDate =
        _contractEndDate?.toLocal() ?? DateTime.now().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Chọn ngày hết hạn hợp đồng',
    );

    if (picked == null || !mounted) return;

    final normalized = DateTime.utc(picked.year, picked.month, picked.day);
    setState(() {
      _contractEndDate = normalized;
      _contractEndDateController.text = _dateFormat.format(normalized.toLocal());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ManagerColors.textCharcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thêm cư dân",
          style: TextStyle(
            color: ManagerColors.textCharcoal,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  ManagerColors.bgLightGreen.withOpacity(0.5),
                  ManagerColors.bgLightGreen,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Quét CCCD tự động điền'),
                    _buildScanCccdButton(),
                    const SizedBox(height: 20),
                    _buildFieldLabel('Họ và tên'),
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Nguyễn Văn A',
                      icon: Icons.person_outline,
                      enabled: !_isLoading && !_isScanningCccd,
                    ),
                    const SizedBox(height: 20),
                    _buildFieldLabel('Số CCCD/CMND'),
                    _buildTextField(
                      controller: _cccdController,
                      hintText: '079201012345',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading && !_isScanningCccd,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFieldLabel('Số điện thoại'),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: "0987654321",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 20),
                    _buildFieldLabel("Email"),
                    _buildTextField(
                      controller: _emailController,
                      hintText: "email@example.com",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 20),
                    _buildFieldLabel("Mật khẩu khởi tạo"),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: "Mật khẩu cho cư dân",
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: ManagerColors.textGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFieldLabel("Vai trò"),
                    _buildDropdownField(
                      value: _selectedRole,
                      items: _roles,
                      icon: Icons.shield_outlined,
                      enabled: !_isLoading,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                        _validateForm();
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildFieldLabel("Chi nhánh / Tòa nhà"),
                    _buildDropdownField(
                      value: _selectedBranch,
                      hintText: "Chọn chi nhánh",
                      items: _branches,
                      icon: Icons.business_outlined,
                      enabled: !_isLoading,
                      onChanged: (value) {
                        setState(() {
                          _selectedBranch = value;
                          _selectedRoom = null;
                          _rooms = [];
                        });
                        _fetchRooms(value);
                        _validateForm();
                      },
                    ),
                    if (_selectedRole == 'tenant' && _selectedBranch != null) ...[
                      const SizedBox(height: 20),
                      _buildFieldLabel("Phòng"),
                      _buildDropdownField(
                        value: _selectedRoom,
                        hintText: _rooms.isEmpty ? "Không có phòng trống" : "Chọn phòng",
                        items: _rooms,
                        icon: Icons.meeting_room_outlined,
                        enabled: !_isLoading && _rooms.isNotEmpty,
                        onChanged: (value) {
                          setState(() {
                            _selectedRoom = value;
                          });
                          _validateForm();
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildFieldLabel("Tiền đặt cọc (VND)"),
                      _buildTextField(
                        controller: _depositController,
                        hintText: "VD: 3000000",
                        icon: Icons.monetization_on_outlined,
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 20),
                      ContractPhotoUpload(
                        imageUrls: _contractImageUrls,
                        uploadFolder: 'contracts',
                        enabled: !_isLoading && !_isScanningCccd && !_isScanningContract,
                        onChanged: (urls) {
                          setState(() {
                            _contractImageUrls = urls;
                            if (urls.isEmpty) {
                              _contractEndDate = null;
                              _contractEndDateController.clear();
                              _aiDetectedDate = false;
                              _aiScanFailed = false;
                            }
                          });
                          _validateForm();
                        },
                        onUploadedBatch: _scanContractExpiryBatch,
                      ),
                      const SizedBox(height: 20),
                      _buildFieldLabel('Ngày hết hạn hợp đồng'),
                      _buildTextField(
                        controller: _contractEndDateController,
                        hintText: _aiScanFailed
                            ? 'AI thất bại — Bấm để chọn ngày'
                            : 'AI tự nhận diện hoặc bấm để chọn',
                        icon: Icons.event_outlined,
                        enabled: !_isLoading && !_isScanningCccd && !_isScanningContract,
                        readOnly: true,
                        onTap: _pickContractEndDate,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_month_outlined),
                          color: ManagerColors.textGrey,
                          onPressed: (!_isLoading && !_isScanningContract)
                              ? _pickContractEndDate
                              : null,
                        ),
                      ),
                      if (_isScanningContract) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ManagerColors.primaryGreen,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đang quét ảnh hợp đồng để lấy ngày hết hạn...',
                              style: TextStyle(
                                color: ManagerColors.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ] else if (_aiScanFailed && _contractEndDate == null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'AI không nhận diện được. Vui lòng bấm vào ô trên để chọn ngày thủ công.',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_contractEndDate != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              _aiDetectedDate
                                  ? Icons.auto_awesome
                                  : Icons.edit_calendar_outlined,
                              size: 14,
                              color: _aiDetectedDate
                                  ? ManagerColors.primaryGreen
                                  : ManagerColors.textGrey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _aiDetectedDate
                                  ? 'AI đã nhận diện — bạn có thể bấm vào ô trên để sửa'
                                  : 'Đã chọn thủ công',
                              style: TextStyle(
                                color: _aiDetectedDate
                                    ? ManagerColors.primaryGreen
                                    : ManagerColors.textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading || _isScanningCccd || _isScanningContract)
            Container(
              color: Colors.black12,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: ManagerColors.primaryGreen,
                    ),
                    if (_isScanningCccd) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Đang quét CCCD...',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else if (_isScanningContract) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Đang quét hợp đồng...',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed:
                  _canSubmit && !_isLoading && !_isScanningCccd && !_isScanningContract
                      ? _handleSubmit
                      : null,
              icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white, size: 20),
              label: const Text(
                "Tạo cư dân",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ManagerColors.primaryGreen,
                disabledBackgroundColor: ManagerColors.primaryGreen.withOpacity(0.3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanCccdButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: (_isLoading || _isScanningCccd) ? null : _scanCccd,
        icon: Icon(
          Icons.qr_code_scanner_rounded,
          color: _isScanningCccd ? ManagerColors.textGrey : const Color(0xFF1976D2),
        ),
        label: Text(
          _isScanningCccd ? 'Đang quét...' : 'Quét CCCD/CMND',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _isScanningCccd ? ManagerColors.textGrey : const Color(0xFF1976D2),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFE3F2FD),
          side: BorderSide(
            color: _isScanningCccd
                ? ManagerColors.lightGreenBorder.withOpacity(0.3)
                : const Color(0xFF90CAF9),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: ManagerColors.textGrey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onTap: onTap,
      style: const TextStyle(
        color: ManagerColors.textCharcoal,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: ManagerColors.textGrey.withOpacity(0.5),
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: ManagerColors.textGrey, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: ManagerColors.fieldBgTint.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ManagerColors.lightGreenBorder.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ManagerColors.lightGreenBorder.withOpacity(0.3)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ManagerColors.lightGreenBorder.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ManagerColors.primaryGreen, width: 1),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    String? value,
    String? hintText,
    required List<Map<String, dynamic>> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((Map<String, dynamic> item) {
        return DropdownMenuItem<String>(
          value: item['id']?.toString(),
          child: Text(item['label'] ?? ''),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      style: const TextStyle(
        color: ManagerColors.textCharcoal,
        fontSize: 16,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: ManagerColors.textGrey),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: ManagerColors.textGrey.withOpacity(0.5),
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: ManagerColors.textGrey, size: 22),
        filled: true,
        fillColor: ManagerColors.fieldBgTint.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ManagerColors.lightGreenBorder.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ManagerColors.lightGreenBorder.withOpacity(0.3)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ManagerColors.lightGreenBorder.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ManagerColors.primaryGreen, width: 1),
        ),
      ),
    );
  }
}
