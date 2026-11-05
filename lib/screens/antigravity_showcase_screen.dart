import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/antigravity_canvas.dart';

class AntigravityShowcaseScreen extends StatefulWidget {
  const AntigravityShowcaseScreen({super.key});

  @override
  State<AntigravityShowcaseScreen> createState() => _AntigravityShowcaseScreenState();
}

class _AntigravityShowcaseScreenState extends State<AntigravityShowcaseScreen> {
  double _gravityY = -35.0; // Inverted upward gravity
  int _particleCount = 28;
  bool _enableRepulsion = true;
  bool _showHud = true;
  Key _canvasKey = UniqueKey();

  void _resetSimulation() {
    setState(() {
      _canvasKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091413),
      body: Stack(
        children: [
          // 1. Antigravity Physics Engine Canvas
          Positioned.fill(
            child: AntigravityCanvas(
              key: _canvasKey,
              particleCount: _particleCount,
              gravityY: _gravityY,
              enableTouchRepulsion: _enableRepulsion,
              repulsionRadius: 220.0,
              repulsionForce: 110000.0,
              showFps: true,
              backgroundColor: const Color(0xFF071211),
            ),
          ),

          // 2. Interactive Floating Header & Controls Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(CupertinoIcons.back, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Antigravity Physics Engine',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Ekranni bosing yoki suring (Repulsion effect)',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: const Color(0xFF2DD4BF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showHud = !_showHud),
                        icon: Icon(
                          _showHud ? CupertinoIcons.slider_horizontal_3 : CupertinoIcons.eye_fill,
                          color: const Color(0xFF2DD4BF),
                        ),
                      ),
                      IconButton(
                        onPressed: _resetSimulation,
                        icon: const Icon(CupertinoIcons.arrow_clockwise, color: Colors.white70),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bottom Settings HUD Panel
                  if (_showHud)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2624).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Gravity Direction Control
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gravitatsiya yoʻnalishi:',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _gravityY < 0
                                    ? 'Yuqoriga (Antigravitatsiya)'
                                    : (_gravityY == 0 ? 'Nol (Kosmik muallaq)' : 'Pastga'),
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2DD4BF),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF2DD4BF),
                              inactiveTrackColor: Colors.white12,
                              thumbColor: Colors.white,
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: _gravityY,
                              min: -60.0,
                              max: 30.0,
                              onChanged: (val) {
                                setState(() => _gravityY = val);
                              },
                            ),
                          ),

                          // Particle Count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Jism soni (Particles):',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$_particleCount ta element',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF10B981),
                              inactiveTrackColor: Colors.white12,
                              thumbColor: Colors.white,
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: _particleCount.toDouble(),
                              min: 12,
                              max: 42,
                              divisions: 30,
                              onChanged: (val) {
                                setState(() {
                                  _particleCount = val.toInt();
                                  _resetSimulation();
                                });
                              },
                            ),
                          ),

                          // Repulsion toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tegilishda tarqalish (Touch Repulsion):',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              CupertinoSwitch(
                                value: _enableRepulsion,
                                activeTrackColor: const Color(0xFF2DD4BF),
                                onChanged: (val) => setState(() => _enableRepulsion = val),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

