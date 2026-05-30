import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/otp_page.dart';
import 'package:smartrent_mobile/manager/features/auth/data/auth_service.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_shell_page.dart';
import 'package:smartrent_mobile/tenant/core/navigation/tenant_nav.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  final Widget? targetNav;
  const LoginPage({super.key, this.targetNav});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final TokenService _tokenService = TokenService();
  String? _identityError;
  String? _passwordError;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final identity = _identityController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _identityError = identity.isEmpty ? 'Vui lòng nhập số điện thoại hoặc email' : null;
      _passwordError = password.isEmpty ? 'Vui lòng nhập mật khẩu' : null;
    });

    if (_identityError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _identityError = null;
      _passwordError = null;
    });

    try {
      final response = await _authService.login(identity, password);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          final token = data['access_token'];
          final role = data['user']['role'];

          if (token != null) {
            await _tokenService.saveToken(token);
          }

          final user = data['user'] as Map<String, dynamic>?;
          final branchId = user?['branch_id'];
          if (branchId != null) {
            await _tokenService.saveBranchId(branchId.toString());
          }
          final savedPhone = ManagerAppHeader.formatPhoneDisplay(
            user?['phone']?.toString() ?? identity,
          );
          await _tokenService.saveUserProfile(
            phone: savedPhone.isNotEmpty ? savedPhone : identity,
            fullName: user?['full_name']?.toString(),
          );

          if (!mounted) return;

          Widget target;
          if (role == 'manager' || role == 'super_admin') {
            target = const ManagerShellPage(initialTab: 4);
          } else if (role == 'tenant') {
            target = const TenantNav();
          } else {
            setState(() {
              _passwordError = 'Vai trò người dùng không hợp lệ: $role';
            });
            return;
          }

          Navigator.pushAndRemoveUntil(
            context,
            AppPageRoutes.fade(target),
            (route) => false,
          );
        } else {
          setState(() {
            _passwordError = data['message'] ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại.';
          });
        }
      } else {
        setState(() {
          _passwordError = 'Lỗi máy chủ: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _passwordError = 'Lỗi kết nối hoặc sai thông tin: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, ManagerColors.bgMint],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                // Logo Section
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'logo/logo.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                // Sub-logo Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco_outlined,
                        size: 16, color: ManagerColors.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      'RESOURCE MANAGEMENT SYSTEM',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2.0,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Card Form
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: ManagerColors.cardShadow,
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chào mừng',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhập số điện thoại hoặc email và mật khẩu để tiếp tục',
                        style: TextStyle(
                          fontSize: 15,
                          color: ManagerColors.subtitleGrey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Số điện thoại hoặc Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _identityController,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: ManagerColors.primaryGreen,
                        decoration: InputDecoration(
                          hintText: 'Nhập số điện thoại hoặc email',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.person_outline,
                              color: ManagerColors.subtitleGrey),
                          filled: true,
                          fillColor: const Color(0xFFFBFDFA),
                          errorText: _identityError,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: ManagerColors.lightGreenBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: ManagerColors.primaryGreen, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Colors.redAccent, width: 1.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Colors.redAccent, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Mật khẩu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        cursorColor: ManagerColors.primaryGreen,
                        decoration: InputDecoration(
                          hintText: 'Nhập mật khẩu',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: ManagerColors.subtitleGrey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: ManagerColors.subtitleGrey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFBFDFA),
                          errorText: _passwordError,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: ManagerColors.lightGreenBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: ManagerColors.primaryGreen, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Colors.redAccent, width: 1.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Colors.redAccent, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              color: ManagerColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ManagerColors.primaryGreen,
                            elevation: 4,
                            shadowColor: ManagerColors.primaryGreen.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Đăng nhập để quản lý hệ thống của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: ManagerColors.subtitleGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                // Footer
                const Text(
                  '© 2025 RMS · Phiên bản 2.4.1',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
