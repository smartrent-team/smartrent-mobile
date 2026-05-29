import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:dio/dio.dart';

class AddTenantPage extends StatefulWidget {
  const AddTenantPage({super.key});

  @override
  State<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends State<AddTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final TenantService _tenantService = TenantService();
  final TokenService _tokenService = TokenService();
  
  String? _managedBranchId;

  String? _selectedRole = 'tenant';
  String? _selectedBranch;
  String? _selectedRoom;
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _obscurePassword = true;

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
      print('DEBUG: Fetch branches error: $e');
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
      print('DEBUG: Fetch rooms error: $e');
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
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      final bool isRoomValid = _selectedRole != 'tenant' || _selectedRoom != null;
      final bool isEmailValid = _emailController.text.trim().isEmpty || 
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim());
      
      _isFormValid = _nameController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty &&
          _selectedBranch != null &&
          isRoomValid &&
          isEmailValid;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _tenantService.addTenant(
        phone: _phoneController.text.trim(),
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        branch: _selectedBranch!,
        role: _selectedRole ?? 'tenant',
        roomId: _selectedRoom,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm cư dân thành công!'),
            backgroundColor: ManagerColors.primaryGreen,
          ),
        );
        Navigator.pop(context, {
          "name": _nameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "date": "22/05/2026",
        });
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('error')) {
          errMsg = data['error'].toString();
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $errMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                    _buildFieldLabel("Họ và tên"),
                    _buildTextField(
                      controller: _nameController,
                      hintText: "Nguyễn Văn A",
                      icon: Icons.person_outline,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 20),
                    _buildFieldLabel("Số điện thoại"),
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
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(
                  color: ManagerColors.primaryGreen,
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
              onPressed: _isFormValid && !_isLoading ? _handleSubmit : null,
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
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      obscureText: obscureText,
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
