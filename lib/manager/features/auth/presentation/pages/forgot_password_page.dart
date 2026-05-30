import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/auth/data/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _emailError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final email = _emailController.text.trim();

    setState(() {
      _emailError = email.isEmpty
          ? 'Vui lòng nhập email'
          : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)
              ? 'Email không hợp lệ'
              : null;
    });

    if (_emailError != null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.forgotPassword(email);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email lấy lại mật khẩu đã được gửi!'),
              backgroundColor: ManagerColors.primaryGreen,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _emailError = 'Lỗi máy chủ: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _emailError = 'Lỗi: ${e.toString()}';
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
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Lấy lại mật khẩu',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nhập email của bạn để nhận hướng dẫn lấy lại mật khẩu',
                  style: TextStyle(
                    fontSize: 16,
                    color: ManagerColors.subtitleGrey,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: ManagerColors.primaryGreen,
                  decoration: InputDecoration(
                    hintText: 'Nhập email của bạn',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: ManagerColors.subtitleGrey),
                    filled: true,
                    fillColor: const Color(0xFFFBFDFA),
                    errorText: _emailError,
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
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onSend,
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
                            'Gửi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
