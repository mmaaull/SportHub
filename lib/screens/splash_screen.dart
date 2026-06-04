import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/brand_mark.dart';
import 'admin/admin_dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'user/user_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _entryController.forward();
    _pulseController.repeat(reverse: true);

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.loadCurrentUser();

    if (!mounted) return;

    if (authProvider.currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (authProvider.isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDarkGreen,
      body: Stack(
        children: [
          Positioned.fill(
            child: _SplashBackdrop(pulseController: _pulseController),
          ),
          Center(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _SplashContent(pulseController: _pulseController),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  final Animation<double> pulseController;

  const _SplashContent({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 640;
    final logoSize = compact ? 104.0 : 124.0;
    final titleSize = compact ? 29.0 : 34.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SplashLogoStage(
            logoSize: logoSize,
            pulseController: pulseController,
          ),
          SizedBox(height: compact ? 18 : 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'UNESA SportHub',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Reservasi fasilitas olahraga kampus',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: compact ? 13 : 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: compact ? 30 : 36),
          _SplashLoadingBar(animation: pulseController),
        ],
      ),
    );
  }
}

class _SplashLogoStage extends StatelessWidget {
  final double logoSize;
  final Animation<double> pulseController;

  const _SplashLogoStage({
    required this.logoSize,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(pulseController.value);

        return Transform.translate(
          offset: Offset(0, -5 * pulse),
          child: SizedBox(
            width: logoSize + 104,
            height: logoSize + 98,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.98 + (pulse * 0.06),
                  child: _LogoRing(
                    size: logoSize + 88,
                    opacity: 0.08 + (pulse * 0.04),
                    strokeWidth: 1.6,
                  ),
                ),
                Transform.scale(
                  scale: 1.03 - (pulse * 0.04),
                  child: _LogoRing(
                    size: logoSize + 54,
                    opacity: 0.2 - (pulse * 0.06),
                    strokeWidth: 2,
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 18,
                  child: Transform.translate(
                    offset: Offset(0, 6 * pulse),
                    child: const _FloatingSportTile(
                      icon: Icons.stadium_rounded,
                      size: 42,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 13,
                  child: Transform.translate(
                    offset: Offset(0, -5 * pulse),
                    child: const _FloatingSportTile(
                      icon: Icons.event_available_rounded,
                      size: 38,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.98 + (pulse * 0.02),
                  child: SportHubLogoMark(
                    size: logoSize,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                      BoxShadow(
                        color: AppColors.accentGreen.withValues(alpha: 0.2),
                        blurRadius: 34,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogoRing extends StatelessWidget {
  final double size;
  final double opacity;
  final double strokeWidth;

  const _LogoRing({
    required this.size,
    required this.opacity,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: strokeWidth,
        ),
      ),
    );
  }
}

class _FloatingSportTile extends StatelessWidget {
  final IconData icon;
  final double size;

  const _FloatingSportTile({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.86),
        size: size * 0.52,
      ),
    );
  }
}

class _SplashLoadingBar extends StatelessWidget {
  final Animation<double> animation;

  const _SplashLoadingBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(animation.value);

        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 164,
                height: 6,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    Align(
                      alignment: Alignment(-1 + (pulse * 2), 0),
                      child: FractionallySizedBox(
                        widthFactor: 0.42,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.45),
                                Colors.white,
                                AppColors.accentGreen,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'Menyiapkan akses...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  final Animation<double> pulseController;

  const _SplashBackdrop({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(pulseController.value);

        return Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _CourtLinePainter(opacity: 0.055 + (pulse * 0.02)),
              ),
            ),
            Positioned(
              top: -58,
              right: -54,
              child: _BackdropRing(size: 190, opacity: 0.14 - (pulse * 0.03)),
            ),
            Positioned(
              left: -76,
              bottom: 86,
              child: _BackdropRing(size: 170, opacity: 0.11 + (pulse * 0.02)),
            ),
            Positioned(
              right: 24,
              bottom: 56,
              child: Icon(
                Icons.stadium_outlined,
                color: Colors.white.withValues(alpha: 0.08),
                size: 124,
              ),
            ),
            Positioned(
              left: 24,
              top: 86,
              child: Icon(
                Icons.sports_basketball,
                color: Colors.white.withValues(alpha: 0.07),
                size: 58,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BackdropRing extends StatelessWidget {
  final double size;
  final double opacity;

  const _BackdropRing({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 24,
        ),
      ),
    );
  }
}

class _CourtLinePainter extends CustomPainter {
  final double opacity;

  const _CourtLinePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.04),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.82),
      Offset(size.width * 0.92, size.height * 0.66),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.5),
          width: size.width * 0.72,
          height: size.height * 0.34,
        ),
        const Radius.circular(32),
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.13,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CourtLinePainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
