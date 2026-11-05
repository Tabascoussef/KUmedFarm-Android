import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Item types rendered inside the Antigravity physical space
enum AntigravityItemType {
  pill,
  cross,
  card,
  orb,
  heartbeat,
  molecule,
}

/// Physical particle entity with mass, velocity, acceleration and angular momentum
class AntigravityParticle {
  Offset position;
  Offset velocity;
  Offset acceleration;
  double radius;
  double mass;
  double rotation;
  double rotationSpeed;
  Color primaryColor;
  Color secondaryColor;
  AntigravityItemType type;
  String? label;
  String? sublabel;
  double opacity;
  double pulsePhase;

  AntigravityParticle({
    required this.position,
    required this.velocity,
    this.acceleration = Offset.zero,
    required this.radius,
    required this.mass,
    this.rotation = 0.0,
    required this.rotationSpeed,
    required this.primaryColor,
    required this.secondaryColor,
    required this.type,
    this.label,
    this.sublabel,
    this.opacity = 0.85,
    this.pulsePhase = 0.0,
  });

  factory AntigravityParticle.random(Size bounds, math.Random rng) {
    final types = AntigravityItemType.values;
    final type = types[rng.nextInt(types.length)];
    final radius = 22.0 + rng.nextDouble() * 26.0;

    // Rich modern teal/emerald/cyan palette matching KUmedFarm
    final palettes = [
      [const Color(0xFF0E9B83), const Color(0xFF2DD4BF)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
      [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
      [const Color(0xFF6366F1), const Color(0xFF818CF8)],
      [const Color(0xFFF59E0B), const Color(0xFFFCD34D)],
      [const Color(0xFFEC4899), const Color(0xFFF472B6)],
    ];
    final selectedPalette = palettes[rng.nextInt(palettes.length)];

    final labels = ['KUmed', 'Rx', 'B12', 'Omega-3', '24/7', '75mg', 'Cardio', 'Pro'];
    final label = (type == AntigravityItemType.card || type == AntigravityItemType.pill)
        ? labels[rng.nextInt(labels.length)]
        : null;

    final x = radius + rng.nextDouble() * (math.max(10.0, bounds.width - radius * 2));
    final y = radius + rng.nextDouble() * (math.max(10.0, bounds.height - radius * 2));

    // Slow cosmic floating drift
    final vx = (rng.nextDouble() - 0.5) * 50.0;
    final vy = -15.0 - rng.nextDouble() * 45.0; // Inverted slight upward drift

    return AntigravityParticle(
      position: Offset(x, y),
      velocity: Offset(vx, vy),
      radius: radius,
      mass: (radius * radius) / 300.0,
      rotation: rng.nextDouble() * math.pi * 2,
      rotationSpeed: (rng.nextDouble() - 0.5) * 1.8,
      primaryColor: selectedPalette[0],
      secondaryColor: selectedPalette[1],
      type: type,
      label: label,
      sublabel: label != null ? '${(radius * 2).toInt()}mg' : null,
      opacity: 0.65 + rng.nextDouble() * 0.35,
      pulsePhase: rng.nextDouble() * math.pi * 2,
    );
  }
}

/// Standalone, high-performance interactive Antigravity Canvas widget
/// Renders 20-30 floating physics items with zero/inverted gravity,
/// soft boundary bouncing, particle-particle elastic interaction,
/// and touch repulsion deceleration. Locked at 60-120 FPS.
class AntigravityCanvas extends StatefulWidget {
  final int particleCount;
  final Widget? child;
  final bool enableTouchRepulsion;
  final double repulsionRadius;
  final double repulsionForce;
  final double gravityY; // Negative for upward/inverted gravity, 0 for zero gravity
  final bool showFps;
  final Color backgroundColor;

  const AntigravityCanvas({
    super.key,
    this.particleCount = 26,
    this.child,
    this.enableTouchRepulsion = true,
    this.repulsionRadius = 200.0,
    this.repulsionForce = 95000.0,
    this.gravityY = -35.0, // Inverted gravity drifting upward
    this.showFps = false,
    this.backgroundColor = const Color(0xFF091413),
  });

  @override
  State<AntigravityCanvas> createState() => _AntigravityCanvasState();
}

class _AntigravityCanvasState extends State<AntigravityCanvas>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<AntigravityParticle> _particles = [];
  final math.Random _rng = math.Random();
  Duration? _lastElapsed;
  Size _lastSize = Size.zero;
  Offset? _touchPosition;
  bool _isInteracting = false;

  // FPS metric
  double _fps = 60.0;
  int _frameCount = 0;
  double _fpsAccumulator = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initParticles(Size size) {
    _lastSize = size;
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(AntigravityParticle.random(size, _rng));
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastSize == Size.zero) return;

    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }

    final double dt = (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Clamp dt to avoid physics explosion on background pause/resume
    final safeDt = dt.clamp(0.001, 0.033);

    _updatePhysics(safeDt);

    // Track FPS
    if (widget.showFps) {
      _frameCount++;
      _fpsAccumulator += safeDt;
      if (_fpsAccumulator >= 0.5) {
        _fps = _frameCount / _fpsAccumulator;
        _frameCount = 0;
        _fpsAccumulator = 0;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _updatePhysics(double dt) {
    final w = _lastSize.width;
    final h = _lastSize.height;
    if (w <= 0 || h <= 0) return;

    const damping = 0.988; // Air viscosity damping
    const restitution = 0.84; // Soft bounce off boundaries

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];

      // 1. Inverted / Zero Gravity + Brownian noise drift
      final brownianX = math.sin(p.pulsePhase + p.position.dy * 0.02) * 12.0;
      p.acceleration = Offset(brownianX, widget.gravityY);
      p.pulsePhase += dt * 1.5;

      // 2. Interactive Touch / Drag Repulsion Field
      if (widget.enableTouchRepulsion && _touchPosition != null) {
        final delta = p.position - _touchPosition!;
        final dist = delta.distance;
        if (dist > 0.1 && dist < widget.repulsionRadius) {
          // Quadratic repulsion falloff with smoothing epsilon
          final factor = 1.0 - (dist / widget.repulsionRadius);
          final force = (widget.repulsionForce * factor * factor) / (dist + 20.0);
          final norm = delta / dist;
          p.acceleration += norm * (force / p.mass);

          // Impart angular spin based on tangential repulsion impact
          final crossSpin = (delta.dx * norm.dy - delta.dy * norm.dx);
          p.rotationSpeed += (crossSpin * 0.02).clamp(-6.0, 6.0);
        }
      }

      // 3. Integrate Velocity & Position (Euler-Verlet integration)
      p.velocity = (p.velocity + p.acceleration * dt) * damping;

      // Max velocity speed cap for stability
      const maxSpeed = 480.0;
      final speed = p.velocity.distance;
      if (speed > maxSpeed) {
        p.velocity = (p.velocity / speed) * maxSpeed;
      }

      p.position += p.velocity * dt;
      p.rotation += p.rotationSpeed * dt;
      p.rotationSpeed *= 0.992; // Rotational friction

      // 4. Soft Wall Bouncing
      final r = p.radius;
      // Horizontal bounds
      if (p.position.dx - r < 0) {
        p.position = Offset(r, p.position.dy);
        p.velocity = Offset(-p.velocity.dx * restitution, p.velocity.dy);
        p.rotationSpeed = -p.rotationSpeed * 0.8;
      } else if (p.position.dx + r > w) {
        p.position = Offset(w - r, p.position.dy);
        p.velocity = Offset(-p.velocity.dx * restitution, p.velocity.dy);
        p.rotationSpeed = -p.rotationSpeed * 0.8;
      }

      // Vertical bounds (Antigravity room ceiling and floor)
      if (p.position.dy - r < 0) {
        p.position = Offset(p.position.dx, r);
        p.velocity = Offset(p.velocity.dx, -p.velocity.dy * restitution);
      } else if (p.position.dy + r > h) {
        p.position = Offset(p.position.dx, h - r);
        p.velocity = Offset(p.velocity.dx, -p.velocity.dy * restitution);
      }
    }

    // 5. Elastic Particle-Particle Collisions (O(N^2) where N~26 takes < 0.1ms)
    for (int i = 0; i < _particles.length; i++) {
      for (int j = i + 1; j < _particles.length; j++) {
        final pA = _particles[i];
        final pB = _particles[j];
        final delta = pB.position - pA.position;
        final dist = delta.distance;
        final minDist = pA.radius + pB.radius;

        if (dist > 0 && dist < minDist) {
          final normal = delta / dist;
          // Overlap resolution separation
          final overlap = minDist - dist;
          pA.position -= normal * (overlap * 0.5);
          pB.position += normal * (overlap * 0.5);

          // Relative velocity along collision normal
          final rv = pB.velocity - pA.velocity;
          final velAlongNormal = rv.dx * normal.dx + rv.dy * normal.dy;

          // Only collide if moving toward each other
          if (velAlongNormal < 0) {
            const e = 0.85; // Restitution
            final impulse = -(1 + e) * velAlongNormal / ((1 / pA.mass) + (1 / pB.mass));
            final impulseVec = normal * impulse;
            pA.velocity -= impulseVec / pA.mass;
            pB.velocity += impulseVec / pB.mass;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_particles.isEmpty || _lastSize != size) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initParticles(size);
          });
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            setState(() {
              _touchPosition = details.localPosition;
              _isInteracting = true;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _touchPosition = details.localPosition;
            });
          },
          onPanEnd: (_) {
            setState(() {
              _touchPosition = null;
              _isInteracting = false;
            });
          },
          onTapDown: (details) {
            setState(() {
              _touchPosition = details.localPosition;
              _isInteracting = true;
            });
            // Temporary pulse release after tap
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted && !_isInteracting) {
                setState(() => _touchPosition = null);
              }
            });
          },
          onTapUp: (_) {
            setState(() {
              _touchPosition = null;
              _isInteracting = false;
            });
          },
          child: RepaintBoundary(
            child: Stack(
              children: [
                // Physical Canvas Scene
                CustomPaint(
                  size: size,
                  painter: _AntigravityPainter(
                    particles: _particles,
                    touchPoint: _touchPosition,
                    backgroundColor: widget.backgroundColor,
                  ),
                ),

                // Optional Foreground Content Layer
                if (widget.child != null) widget.child!,

                // FPS & Diagnostics HUD
                if (widget.showFps)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2DD4BF), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _fps > 55 ? const Color(0xFF10B981) : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_fps.toStringAsFixed(1)} FPS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
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

/// Custom GPU-optimized painter drawing 60-120 FPS physics particles
class _AntigravityPainter extends CustomPainter {
  final List<AntigravityParticle> particles;
  final Offset? touchPoint;
  final Color backgroundColor;

  _AntigravityPainter({
    required this.particles,
    required this.touchPoint,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background fill
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    // 2. Cosmic ambient grid glow
    final gridPaint = Paint()
      ..color = const Color(0xFF0E9B83).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    const step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Touch Repulsion Ripple Field
    if (touchPoint != null) {
      final ripplePaint = Paint()
        ..color = const Color(0xFF2DD4BF).withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(touchPoint!, 60, ripplePaint);

      final outerRipple = Paint()
        ..color = const Color(0xFF0E9B83).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(touchPoint!, 120, outerRipple);

      final centerDot = Paint()..color = const Color(0xFF2DD4BF);
      canvas.drawCircle(touchPoint!, 5, centerDot);
    }

    // 4. Render All Physics Particles
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);

      switch (p.type) {
        case AntigravityItemType.pill:
          _drawPill(canvas, p);
          break;
        case AntigravityItemType.cross:
          _drawCross(canvas, p);
          break;
        case AntigravityItemType.card:
          _drawCard(canvas, p);
          break;
        case AntigravityItemType.orb:
          _drawOrb(canvas, p);
          break;
        case AntigravityItemType.heartbeat:
          _drawHeartbeat(canvas, p);
          break;
        case AntigravityItemType.molecule:
          _drawMolecule(canvas, p);
          break;
      }

      canvas.restore();
    }
  }

  void _drawPill(Canvas canvas, AntigravityParticle p) {
    final w = p.radius * 2.0;
    final h = p.radius * 0.95;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular(h / 2),
    );

    // Soft drop glow
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = p.primaryColor.withValues(alpha: 0.25 * p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Left half (Primary color)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(-w / 2, -h / 2, w / 2, h));
    canvas.drawRRect(
      rrect,
      Paint()..color = p.primaryColor.withValues(alpha: p.opacity),
    );
    canvas.restore();

    // Right half (Secondary white/tint)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -h / 2, w / 2, h));
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.white.withValues(alpha: 0.9 * p.opacity),
    );
    canvas.restore();

    // Outline stroke
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Pill divide line
    canvas.drawLine(
      Offset(0, -h / 2),
      Offset(0, h / 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1.2,
    );

    // Pill specular light highlight
    final highlight = Path()
      ..moveTo(-w * 0.35, -h * 0.25)
      ..lineTo(w * 0.35, -h * 0.25);
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * p.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCross(Canvas canvas, AntigravityParticle p) {
    final r = p.radius;
    final thickness = r * 0.45;

    // Cross shadow
    final crossPath = Path()
      ..addRect(Rect.fromCenter(center: Offset.zero, width: r * 1.8, height: thickness))
      ..addRect(Rect.fromCenter(center: Offset.zero, width: thickness, height: r * 1.8));

    canvas.drawPath(
      crossPath,
      Paint()
        ..color = p.secondaryColor.withValues(alpha: 0.3 * p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Cross body
    canvas.drawPath(
      crossPath,
      Paint()..color = p.primaryColor.withValues(alpha: p.opacity),
    );

    // Inner bright cross
    final innerThickness = thickness * 0.5;
    final innerPath = Path()
      ..addRect(Rect.fromCenter(center: Offset.zero, width: r * 1.4, height: innerThickness))
      ..addRect(Rect.fromCenter(center: Offset.zero, width: innerThickness, height: r * 1.4));
    canvas.drawPath(
      innerPath,
      Paint()..color = Colors.white.withValues(alpha: 0.7 * p.opacity),
    );
  }

  void _drawCard(Canvas canvas, AntigravityParticle p) {
    final w = p.radius * 2.2;
    final h = p.radius * 1.4;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      const Radius.circular(12),
    );

    // Glass card glow
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = p.primaryColor.withValues(alpha: 0.3 * p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Card fill with gradient
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.primaryColor.withValues(alpha: 0.85 * p.opacity),
            p.secondaryColor.withValues(alpha: 0.9 * p.opacity),
          ],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: w, height: h)),
    );

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Card Label
    if (p.label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: p.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: p.radius * 0.42,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
    }
  }

  void _drawOrb(Canvas canvas, AntigravityParticle p) {
    final r = p.radius * 0.85;

    // Glowing outer halo
    canvas.drawCircle(
      Offset.zero,
      r * 1.4,
      Paint()
        ..color = p.secondaryColor.withValues(alpha: 0.2 * p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Radial gradient sphere
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [
            Colors.white.withValues(alpha: 0.95 * p.opacity),
            p.secondaryColor.withValues(alpha: 0.85 * p.opacity),
            p.primaryColor.withValues(alpha: 0.9 * p.opacity),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );

    // Rim highlight
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawHeartbeat(Canvas canvas, AntigravityParticle p) {
    final r = p.radius;
    final path = Path();
    path.moveTo(-r, 0);
    path.lineTo(-r * 0.4, 0);
    path.lineTo(-r * 0.2, -r * 0.6);
    path.lineTo(0, r * 0.7);
    path.lineTo(r * 0.25, -r * 0.4);
    path.lineTo(r * 0.45, 0);
    path.lineTo(r, 0);

    // Heartbeat glow line
    canvas.drawPath(
      path,
      Paint()
        ..color = p.secondaryColor.withValues(alpha: 0.4 * p.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.95 * p.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawMolecule(Canvas canvas, AntigravityParticle p) {
    final r = p.radius;
    final atomCount = 3;
    final angleStep = (math.pi * 2) / atomCount;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 * p.opacity)
      ..strokeWidth = 2.0;

    for (int i = 0; i < atomCount; i++) {
      final a = angleStep * i;
      final atomOffset = Offset(math.cos(a) * r * 0.65, math.sin(a) * r * 0.65);
      canvas.drawLine(Offset.zero, atomOffset, linePaint);

      canvas.drawCircle(
        atomOffset,
        r * 0.28,
        Paint()..color = p.secondaryColor.withValues(alpha: p.opacity),
      );
    }

    // Center atom
    canvas.drawCircle(
      Offset.zero,
      r * 0.4,
      Paint()..color = p.primaryColor.withValues(alpha: p.opacity),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.8 * p.opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _AntigravityPainter old) => true;
}
