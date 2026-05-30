import 'package:flutter/material.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_shell_page.dart';
import 'package:smartrent_mobile/manager/features/auth/data/auth_service.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';
import 'package:smartrent_mobile/tenant/core/navigation/tenant_nav.dart';

class OtpPage extends StatefulWidget {
  final String? phoneNumber;
  const OtpPage({super.key, this.phoneNumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final AuthService _authService = AuthService();
  final TokenService _tokenService = TokenService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((e) => e.text).join();

  Future<void> _onVerify() async {
    final otp = _otp;
    if (otp.length < 6) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ mã OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.verifyOtp(widget.phoneNumber ?? '', otp);
      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final role = data['user']['role'];

        if (token != null) {
          await _tokenService.saveToken(token);
        }

        final branchData = data['user']['branch'];
        if (branchData != null) {
          String? bId;
          if (branchData is Map) {
            bId = branchData['id']?.toString();
          } else {
            bId = branchData.toString();
          }
          if (bId != null) {
            await _tokenService.saveBranchId(bId);
          }
        }

        if (!mounted) return;

        Widget target;
        if (role == 'manager') {
          target = const ManagerShellPage(initialTab: 4);
        } else if (role == 'tenant') {
          target = const TenantNav();
        } else {
          setState(() {
            _errorMessage = 'Vai trò người dùng không hợp lệ';
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
          _errorMessage = 'Xác thực OTP thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
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
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black54),
                    label: const Text(
                      'Quay lại',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: ManagerColors.primaryGreen,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'RMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('RESOURCE MANAGEMENT SYSTEM', style: TextStyle(fontSize: 11, letterSpacing: 1.5)),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(color: ManagerColors.cardShadow, blurRadius: 30, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Xác thực OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Mã đã gửi tới ${widget.phoneNumber ?? ""}'),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: 45,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              decoration: InputDecoration(
                                counterText: "",
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ManagerColors.primaryGreen)),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ManagerColors.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Xác nhận OTP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(onPressed: () {}, child: const Text('Gửi lại mã OTP', style: TextStyle(color: ManagerColors.primaryGreen))),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                const Text('© 2025 RMS · Phiên bản 2.4.1', style: TextStyle(fontSize: 12, color: Colors.black38)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
