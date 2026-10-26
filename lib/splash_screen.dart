import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'services/api_service.dart';

// Precomputed static ECG path data for ultra-smooth 60-120 FPS rendering
class _EcgData {
  static final Path path = () {
    final p = Path();
    p.moveTo(5, 39);
    p.lineTo(70, 39);
    p.lineTo(82, 38);
    p.lineTo(90, 20);
    p.lineTo(102, 58);
    p.lineTo(117, 6);
    p.lineTo(131, 61);
    p.lineTo(144, 27);
    p.lineTo(156, 39);
    p.lineTo(325, 39);
    return p;
  }();

  static final double totalLength = path.computeMetrics().first.length;
}

class SplashScreen extends StatefulWidget {
  final bool isResume;
  final VoidCallback? onFinished;

  const SplashScreen({
    super.key,
    this.isResume = false,
    this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _hasNavigated = false;
  bool _isStarted = false;

  // Exact total timeline: 4800ms
  static const int _totalMs = 4800;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    // Wait for Android window surface to finish mounting and drawing first frame,
    // so the animation starts strictly at frame 0 and the user sees the entire beginning!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_isStarted) {
          _isStarted = true;
          _anim.forward(from: 0.0);
        }
      });
    });
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    widget.onFinished?.call();

    if (widget.isResume) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final nextScreen = ApiService.instance.isAuthenticated
        ? const HomeScreen()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height * 0.43;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          widget.onFinished?.call();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToNext,
          child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final ms = _anim.value * _totalMs;

          // 1. Ambient Glows (starts at 200ms, fades in over 1500ms)
          final ambientOpacity = ((ms - 200) / 1500).clamp(0.0, 1.0);

          // 2. ECG line progress (1050ms to 2350ms)
          double ecgProgress = 0.0;
          double ecgOpacity = 0.0;
          if (ms >= 1050 && ms <= 2350) {
            final t = (ms - 1050) / 1300;
            if (t <= 0.15) {
              ecgOpacity = t / 0.15;
            } else if (t <= 0.75) {
              ecgOpacity = 1.0;
            } else {
              ecgOpacity = (1.0 - (t - 0.75) / 0.25).clamp(0.0, 1.0);
            }
            final drawT = (t / 0.75).clamp(0.0, 1.0);
            ecgProgress = const Cubic(0.65, 0.0, 0.35, 1.0).transform(drawT);
          }

          // 3. Text copy (0.5s - 1.2s in, 2.5s - 2.9s out)
          double copyOpacity = 0.0;
          double copyTranslateY = 0.0;
          if (ms >= 500 && ms < 2500) {
            final tIn = ((ms - 500) / 700).clamp(0.0, 1.0);
            copyOpacity = Curves.easeOut.transform(tIn);
            copyTranslateY = 8.0 * (1.0 - copyOpacity);
          } else if (ms >= 2500 && ms <= 2900) {
            final tOut = ((ms - 2500) / 400).clamp(0.0, 1.0);
            copyOpacity = (1.0 - Curves.easeIn.transform(tOut)).clamp(0.0, 1.0);
            copyTranslateY = -5.0 * tOut;
          }

          // 4. Capsule physics
          // Base Hovering: 0ms to 2180ms
          double capsuleHoverY = -6.0;
          double capsuleAngle = -12.0;
          double shadowScale = 0.72;
          double shadowOpacity = 0.35;
          double capsuleScaleX = 1.0;
          double capsuleScaleY = 1.0;
          double sceneTranslateY = 0.0;

          if (ms < 2180) {
            final hoverTime = math.max(0.0, ms - 200);
            final hoverPhase = (hoverTime / 1350) * math.pi;
            final norm = (1.0 - math.cos(hoverPhase)) / 2.0;
            capsuleHoverY = ui.lerpDouble(-6.0, 7.0, norm)!;
            capsuleAngle = ui.lerpDouble(-12.0, -9.0, norm)!;
            shadowScale = ui.lerpDouble(0.72, 1.08, norm)!;
            shadowOpacity = ui.lerpDouble(0.35, 0.85, norm)!;
          } else if (ms >= 2180 && ms < 2650) {
            // Charging squash (2180ms to 2650ms)
            final t = ((ms - 2180) / 470).clamp(0.0, 1.0);
            if (t <= 0.6) {
              final subT = t / 0.6;
              final c = Curves.easeInOut.transform(subT);
              capsuleScaleX = ui.lerpDouble(1.0, 1.12, c)!;
              capsuleScaleY = ui.lerpDouble(1.0, 0.65, c)!;
              capsuleHoverY = ui.lerpDouble(0.0, 25.0, c)!;
            } else {
              final subT = (t - 0.6) / 0.4;
              final c = Curves.easeInOut.transform(subT);
              capsuleScaleX = ui.lerpDouble(1.12, 0.90, c)!;
              capsuleScaleY = ui.lerpDouble(0.65, 1.10, c)!;
              capsuleHoverY = ui.lerpDouble(25.0, 16.0, c)!;
            }
            capsuleAngle = -10.0;
            shadowScale = ui.lerpDouble(1.08, 1.5, t)!;
            shadowOpacity = ui.lerpDouble(0.85, 0.95, t)!;
          } else {
            // Launch upwards (2650ms to 3750ms)
            final t = ((ms - 2650) / 1100).clamp(0.0, 1.0);
            capsuleAngle = -10.0;
            capsuleScaleX = 0.9;
            capsuleScaleY = 1.15;
            if (t <= 0.15) {
              final subT = t / 0.15;
              sceneTranslateY = ui.lerpDouble(16.0, 35.0, Curves.easeIn.transform(subT))!;
              shadowScale = 1.4;
            } else {
              final subT = (t - 0.15) / 0.85;
              final launchCurve = const Cubic(0.8, 0.0, 0.9, 0.38).transform(subT);
              sceneTranslateY = ui.lerpDouble(35.0, -950.0, launchCurve)!;
              shadowOpacity = (1.0 - subT * 2).clamp(0.0, 1.0);
              shadowScale = (1.4 - subT).clamp(0.1, 1.4);
            }
          }

          // 5. Launch exhaust trail (2820ms to 3540ms)
          double trailHeight = 0.0;
          double trailOpacity = 0.0;
          if (ms >= 2820 && ms <= 3540) {
            final t = (ms - 2820) / 720;
            final curve = const Cubic(0.1, 0.75, 0.3, 1.0).transform(t.clamp(0.0, 1.0));
            trailHeight = 280.0 * curve;
            if (t <= 0.15) {
              trailOpacity = t / 0.15;
            } else {
              trailOpacity = (1.0 - (t - 0.15) / 0.85).clamp(0.0, 1.0);
            }
          }

          // 6. Reveal beam expand (3450ms to 4200ms)
          double beamScaleX = 0.0;
          double beamOpacity = 0.0;
          if (ms >= 3450 && ms <= 4200) {
            final t = (ms - 3450) / 700;
            final curve = const Cubic(0.55, 0.0, 0.2, 1.0).transform(t.clamp(0.0, 1.0));
            beamScaleX = ui.lerpDouble(1.0, 240.0, curve)!;
            if (t <= 0.15) {
              beamOpacity = t / 0.15;
            } else {
              beamOpacity = 1.0;
            }
          }

          // 7. White flash scene reset (4400ms to 4800ms)
          double sceneFadeOut = 1.0;
          if (ms >= 4400) {
            sceneFadeOut = (1.0 - (ms - 4400) / 400).clamp(0.0, 1.0);
          }

          return Opacity(
            opacity: sceneFadeOut,
            child: SizedBox.expand(
              child: Stack(
                children: [
                  // 1. Ambient Glow One: Native RadialGradient (Zero GPU lag)
                  Positioned(
                    left: -90,
                    top: size.height * 0.35,
                    width: 200,
                    height: 200,
                    child: Opacity(
                      opacity: (ambientOpacity * 0.75).clamp(0.0, 1.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0x3852E1C4),
                              Color(0x1552E1C4),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Ambient Glow Two: Native RadialGradient
                  Positioned(
                    right: -80,
                    top: size.height * 0.25,
                    width: 180,
                    height: 180,
                    child: Opacity(
                      opacity: (ambientOpacity * 0.65).clamp(0.0, 1.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0x303EC0E1),
                              Color(0x123EC0E1),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. ECG Pulse Waveform (centered under capsule)
                  if (ecgOpacity > 0.001)
                    Positioned(
                      top: centerY + 79,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          width: 330,
                          height: 70,
                          child: CustomPaint(
                            painter: _EcgPainter(
                              progress: ecgProgress,
                              opacity: ecgOpacity,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 3. Launch Trail (Exhaust beam)
                  if (trailOpacity > 0.001)
                    Positioned(
                      top: centerY - trailHeight,
                      left: centerX - 3.5,
                      width: 7,
                      height: trailHeight,
                      child: Opacity(
                        opacity: trailOpacity.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xFFEAFFFF),
                                Color(0xFF4EE7D6),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 4. Capsule Scene (Centered at centerY - 85, centerX - 75)
                  Positioned(
                    top: centerY - 85,
                    left: centerX - 75,
                    width: 150,
                    height: 170,
                    child: Transform.translate(
                      offset: Offset(0, sceneTranslateY + capsuleHoverY),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Capsule Shadow (top: 104, left: 45, width: 60, height: 12)
                          Positioned(
                            top: 104 - capsuleHoverY * 0.3,
                            left: 45,
                            child: Transform.scale(
                              scale: shadowScale.clamp(0.1, 2.0),
                              child: Opacity(
                                opacity: shadowOpacity.clamp(0.0, 1.0),
                                child: Container(
                                  width: 60,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.elliptical(30, 6)),
                                    gradient: RadialGradient(
                                      colors: [
                                        Color(0x42239A95),
                                        Color(0x18239A95),
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.65, 1.0],
                                    ),














                                    
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Capsule Body (width: 106, height: 56)
                          Positioned(
                            top: 10,
                            left: 22,
                            child: Transform.rotate(
                              angle: capsuleAngle * math.pi / 180,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.diagonal3Values(
                                  capsuleScaleX.clamp(0.2, 3.0),
                                  capsuleScaleY.clamp(0.2, 3.0),
                                  1.0,
                                ),
                                child: Container(
                                  width: 106,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x3525A19A),
                                        blurRadius: 18,
                                        offset: Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Stack(
                                      children: [
                                        // Left half: linear-gradient(145deg, #c8fae5, #5cddbd)
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: 56,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.horizontal(
                                                left: Radius.circular(30),
                                              ),
                                              gradient: LinearGradient(
                                                begin: Alignment(-0.8, -0.6),
                                                end: Alignment(0.8, 0.6),
                                                colors: [Color(0xFFC8FAE5), Color(0xFF5CDDBD)],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Right half: linear-gradient(145deg, #57dce1, #1eacc7)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: 54,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.horizontal(
                                                right: Radius.circular(30),
                                              ),
                                              gradient: LinearGradient(
                                                begin: Alignment(-0.8, -0.6),
                                                end: Alignment(0.8, 0.6),
                                                colors: [Color(0xFF57DCE1), Color(0xFF1EACC7)],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Capsule Seam (center dividing line)
                                        Positioned(
                                          left: 54,
                                          top: 4,
                                          bottom: 4,
                                          width: 2,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Color(0x8CFFFFFF),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color(0x290A7A84),
                                                  offset: Offset(2, 0),
                                                  blurRadius: 3,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Capsule Shine Reflection
                                        Positioned(
                                          top: 7,
                                          left: 18,
                                          width: 65,
                                          height: 12,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.all(Radius.elliptical(32, 6)),
                                              color: Color(0x85FFFFFF),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Reveal Energy Beam (Laser flash expanding horizontally)
                  if (beamOpacity > 0.001)
                    Positioned.fill(
                      child: Center(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(
                            beamScaleX.clamp(1.0, 300.0),
                            1.0,
                            1.0,
                          ),
                          child: Opacity(
                            opacity: beamOpacity.clamp(0.0, 1.0),
                            child: Container(
                              width: 6,
                              height: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF61E6DB),
                                    Color(0xFFE8FFFF),
                                    Color(0xFF61E6DB),
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 6. Splash Copy: "YOUR HEALTH, IN MOTION"
                  if (copyOpacity > 0.001)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 74,
                      child: Transform.translate(
                        offset: Offset(0, copyTranslateY),
                        child: Opacity(
                          opacity: copyOpacity.clamp(0.0, 1.0),
                          child: Center(
                            child: Text(
                              'YOUR HEALTH, IN MOTION',
                              style: GoogleFonts.dmSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.2,
                                color: const Color(0xFF77AAA5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            );
          },
        ),
      ),
    ),
  );
}
}

// ECG PAINTER (Precomputed Path Metric for ultra-fast, 60fps native drawing)
class _EcgPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double opacity;

  static final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  _EcgPainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.001 || opacity <= 0.001) return;

    final currentLength = (_EcgData.totalLength * progress).clamp(0.0, _EcgData.totalLength);
    final drawnPath = _EcgData.path.computeMetrics().first.extractPath(0, currentLength);

    // Glow stroke (crisp outer glow without CPU blur penalty)
    _glowPaint.color = const Color(0xFF59E4D2).withValues(alpha: (0.35 * opacity).clamp(0.0, 1.0));
    canvas.drawPath(drawnPath, _glowPaint);

    // Line stroke (sharp neon line)
    _linePaint.color = const Color(0xFF42D5BD).withValues(alpha: opacity.clamp(0.0, 1.0));
    canvas.drawPath(drawnPath, _linePaint);
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}
