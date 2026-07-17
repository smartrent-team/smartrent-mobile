import 'package:flutter/material.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';

/// Màn hình đổi mật khẩu mới.
/// Nhận [code] (PKCE flow) hoặc [tokenHash] (OTP flow) từ deep link.
class ResetPasswordPage extends StatefulWidget {
  /// PKCE flow: Supabase gửi ?code=xxx trong email link
  final String? code;
  /// OTP flow: Supabase gửi ?token_hash=xxx&type=recovery
  final String? tokenHash;

  const ResetPasswordPage({super.key, this.code, this.tokenHash})
      : assert(code != null || tokenHash != null,
            'Phải có code hoặc tokenHash');

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  final _apiClient = ApiClient();

  bool _isLoading     = false;
  bool _obscurePass   = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    final confirm  = _confirmController.text.trim();

    if (password.length < 6) {
      setState(() => _error = 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      // Gửi code hoặc token_hash tuỳ flow
      final Map<String, dynamic> payload = {'password': password};
      if (widget.code != null) {
        payload['code'] = widget.code;
      } else {
        payload['token_hash'] = widget.tokenHash;
      }

      final response = await _apiClient.dio.post(
        '/api/auth/reset-password',
        data: payload,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
            backgroundColor: ManagerColors.primaryGreen,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else {
        setState(() => _error = response.data['error'] ?? 'Đổi mật khẩu thất bại');
      }
    } catch (e) {
      setState(() => _error = 'Lỗi kết nối. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    color: ManagerColors.bgMint, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: ManagerColors.primaryGreen, size: 32),
                ),
                const SizedBox(height: 24),
                const Text('Đặt mật khẩu mới',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                const Text('Nhập mật khẩu mới cho tài khoản của bạn.',
                    style: TextStyle(fontSize: 15, color: ManagerColors.subtitleGrey)),
                const SizedBox(height: 40),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],

                const Text('Mật khẩu mới',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                _buildTextField(_passwordController, 'Tối thiểu 6 ký tự', _obscurePass,
                    () => setState(() => _obscurePass = !_obscurePass)),
                const SizedBox(height: 20),

                const Text('Xác nhận mật khẩu',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                _buildTextField(_confirmController, 'Nhập lại mật khẩu mới', _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm)),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ManagerColors.primaryGreen,
                      disabledBackgroundColor: ManagerColors.primaryGreen.withValues(alpha: 0.6),
                      elevation: 4,
                      shadowColor: ManagerColors.primaryGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Cập nhật mật khẩu',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      cursorColor: ManagerColors.primaryGreen,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: ManagerColors.subtitleGrey),
          onPressed: toggle,
        ),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ManagerColors.primaryGreen, width: 1.5)),
      ),
    );
  }
}
