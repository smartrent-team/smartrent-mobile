import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/otp_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: ManagerColors.primaryGreen,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: ManagerColors.cardShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'RMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
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
                const SizedBox(height: 60),
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
                        'Nhập số điện thoại để tiếp tục',
                        style: TextStyle(
                          fontSize: 15,
                          color: ManagerColors.subtitleGrey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Số điện thoại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Custom TextField
                      SizedBox(
                        height: 56,
                        child: TextField(
                          keyboardType: TextInputType.phone,
                          cursorColor: ManagerColors.primaryGreen,
                          decoration: InputDecoration(
                            hintText: '0979789878',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.phone_outlined,
                                color: ManagerColors.subtitleGrey),
                            filled: true,
                            fillColor: const Color(0xFFFBFDFA),
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
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OtpPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ManagerColors.primaryGreen,
                            elevation: 4,
                            shadowColor: ManagerColors.primaryGreen.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Tiếp tục',
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
                          'Chúng tôi sẽ gửi mã OTP tới số điện thoại của bạn',
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
