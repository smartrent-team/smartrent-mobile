import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'package:smartrent_mobile/core/services/token_service.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_shell_page.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/tenant/core/navigation/tenant_nav.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  final TokenService _tokenService = TokenService();
  final ApiClient _apiClient = ApiClient();

  // Controllers animation
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _dotController;
  late final AnimationController _shimmerController;

  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    // Fade + slide cho chữ "SmartRent"
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Dot loading animation
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Shimmer trên chữ
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _subtitleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _shimmerAnim = _shimmerController;

    // Mulai animasi
    _fadeController.forward();
    _slideController.forward();

    // Check session sau khi animation chạy xong
    Future.delayed(const Duration(milliseconds: 900), _checkSession);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _dotController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Auth logic ─────────────────────────────────────────────────────────────

  Future<void> _checkSession() async {
    final accessToken = await _tokenService.getToken();
    final refreshToken = await _tokenService.getRefreshToken();

    final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
    final hasRefreshToken = refreshToken != null && refreshToken.isNotEmpty;

    if (!hasAccessToken && !hasRefreshToken) {
      _goLogin();
      return;
    }

    final accessNeedsRefresh = _tokenService.isTokenExpiringSoon(accessToken);
    if (accessNeedsRefresh) {
      final refreshExpired = _tokenService.isTokenExpired(refreshToken);
      if (!hasRefreshToken || refreshExpired) {
        await _tokenService.clearToken();
        _goLogin();
        return;
      }

      final refreshed = await _apiClient.tryRefreshToken();
      if (!refreshed) {
        await _tokenService.clearToken();
        _goLogin();
        return;
      }
    }

    try {
      final response = await _apiClient.dio.get('/api/auth/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final role = response.data['user']?['role'] as String?;
        if (role != null) await _tokenService.saveRole(role);
        _navigateByRole(role);
        return;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final canRefresh = hasRefreshToken && !_tokenService.isTokenExpired(refreshToken);
        if (canRefresh) {
          final refreshed = await _apiClient.tryRefreshToken();
          if (refreshed) {
            try {
              final response = await _apiClient.dio.get('/api/auth/me');
              if (response.statusCode == 200 && response.data['success'] == true) {
                final role = response.data['user']?['role'] as String?;
                if (role != null) await _tokenService.saveRole(role);
                _navigateByRole(role);
                return;
              }
            } on DioException catch (retryError) {
              if (retryError.response?.statusCode != 401) {
                final cachedRole = await _tokenService.getRole();
                if (cachedRole != null && cachedRole.isNotEmpty) {
                  _navigateByRole(cachedRole);
                  return;
                }
              }
            }
          }
        }

        await _tokenService.clearToken();
        _goLogin();
        return;
      }

      final cachedRole = await _tokenService.getRole();
      if (cachedRole != null && cachedRole.isNotEmpty) {
        _navigateByRole(cachedRole);
        return;
      }
    } catch (_) {
      final cachedRole = await _tokenService.getRole();
      if (cachedRole != null && cachedRole.isNotEmpty) {
        _navigateByRole(cachedRole);
        return;
      }
    }

    await _tokenService.clearToken();
    _goLogin();
  }

  void _navigateByRole(String? role) {
    if (!mounted) return;
    Widget target;
    if (role == 'manager' || role == 'super_admin') {
      target = const ManagerShellPage(initialTab: 4);
    } else if (role == 'tenant') {
      target = const TenantNav();
    } else {
      _goLogin();
      return;
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => target,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _goLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
              Color(0xFF43A047),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Vòng tròn trang trí nền
            _buildDecorCircles(),

            // Nội dung chính
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Chữ SmartRent với shimmer
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildTitle(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'RESOURCE MANAGEMENT SYSTEM',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 64),

                  // Dot loading
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: _buildDotLoader(),
                  ),
                ],
              ),
            ),

            // Version ở dưới
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _subtitleFade,
                child: Text(
                  '© 2026 SmartRent · v2.4.1',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final shimmerX = _shimmerAnim.value * (bounds.width + 200) - 100;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.white,
                Colors.white,
                Color(0xFFB9F6CA), // xanh nhạt shimmer
                Colors.white,
                Colors.white,
              ],
              stops: [
                0.0,
                (shimmerX / bounds.width).clamp(0.0, 1.0),
                ((shimmerX + 80) / bounds.width).clamp(0.0, 1.0),
                ((shimmerX + 160) / bounds.width).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Smart',
              style: GoogleFonts.outfit(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            TextSpan(
              text: 'Rent',
              style: GoogleFonts.outfit(
                fontSize: 52,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotLoader() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Mỗi dot lệch pha 0.33
            final phase = ((_dotController.value - i * 0.33) % 1.0);
            final scale = phase < 0.5
                ? 0.6 + 0.8 * (phase / 0.5)
                : 1.4 - 0.8 * ((phase - 0.5) / 0.5);
            final opacity = phase < 0.5
                ? 0.3 + 0.7 * (phase / 0.5)
                : 1.0 - 0.7 * ((phase - 0.5) / 0.5);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale.clamp(0.6, 1.4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: opacity.clamp(0.3, 1.0)),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDecorCircles() {
    return Stack(
      children: [
        // Vòng lớn góc trên phải
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        // Vòng góc dưới trái
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}
