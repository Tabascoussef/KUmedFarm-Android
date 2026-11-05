import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'services/gemini_scanner_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

class ScannerScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ScannerScreen({super.key, this.onBack});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _picker = ImagePicker();

  // Embedded Camera variables
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  String? _cameraError;
  bool _isTorchOn = false;

  bool _isCapturing = false;
  bool _isFlashShutter = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  /// Initialize embedded live camera inside this page
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() => _cameraError = 'Qurilmada kamera topilmadi');
        }
        return;
      }

      // Choose back camera
      final backCam = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        backCam,
        ResolutionPreset.medium, // 720p is crisp for OCR & 15x lighter/faster for Gemini API upload
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _cameraError = null;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _cameraError = 'Kamerani ishga tushirib boʻlmadi. Galereyadan tanlash mumkin.';
        });
      }
    }
  }

  /// Toggle camera flashlight (torch)
  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final nextMode = _isTorchOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(nextMode);
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (e) {
      debugPrint('Torch error: $e');
    }
  }

  /// Capture photo from live camera, trigger pending notification, and redirect to Notifications tab
  Future<void> _captureAndSend() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _isFlashShutter = true;
    });

    // Brief white flash effect
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isFlashShutter = false);
    });

    File? capturedFile;
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final x = await _cameraController!.takePicture();
        capturedFile = File(x.path);
      } else {
        // Fallback to ImagePicker if camera controller is unavailable
        final picked = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        if (picked != null) capturedFile = File(picked.path);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }

    if (capturedFile == null) {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
      return;
    }

    final file = capturedFile;

    // 1. "AI tahlili tayyorlanmoqda..." bildirishnomasini yaratish
    final notifId = await NotificationService.instance.startPendingGeminiAnalysis(
      imagePath: file.path,
    );

    // 2. Darhol "Xabarlar" (Notifications) boʻlimiga avtomatik redirect qilish!
    if (mounted) {
      HomeScreen.switchToTab(3);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    // 3. Orqa fonda Gemini AI multimodal tahlili bajariladi va xabar real vaqtda yangilanadi
    try {
      final res = await GeminiScannerService.instance.analyzePrescriptionImage(file);
      await NotificationService.instance.updateGeminiNotification(
        id: notifId,
        result: res,
      );
    } catch (e) {
      final fallbackRes = GeminiScanResult.fallback(
        'Rasm tahlilida xatolik yuz berdi. Iltimos, qaytadan aniqroq suratga oling.',
      );
      await NotificationService.instance.updateGeminiNotification(
        id: notifId,
        result: fallbackRes,
      );
    }
  }

  /// Pick image from gallery and redirect to Notifications
  Future<void> _pickGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (x == null) return;

    final file = File(x.path);

    // 1. "AI tahlili tayyorlanmoqda..." bildirishnomasini yaratish
    final notifId = await NotificationService.instance.startPendingGeminiAnalysis(
      imagePath: file.path,
    );

    // 2. Darhol "Xabarlar" (Notifications) boʻlimiga avtomatik redirect qilish!
    if (mounted) {
      HomeScreen.switchToTab(3);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    // 3. Orqa fonda Gemini AI tahlili
    try {
      final res = await GeminiScannerService.instance.analyzePrescriptionImage(file);
      await NotificationService.instance.updateGeminiNotification(
        id: notifId,
        result: res,
      );
    } catch (e) {
      final fallbackRes = GeminiScanResult.fallback(
        'Rasm tahlilida xatolik yuz berdi. Iltimos, qaytadan suratga oling.',
      );
      await NotificationService.instance.updateGeminiNotification(
        id: notifId,
        result: fallbackRes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.onBack != null) {
          widget.onBack!();
        }
      },
      child: Scaffold(
        backgroundColor: p.bg,
        body: Container(
          decoration: p.bgDecoration,
          child: SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD2E4DF), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(CupertinoIcons.back, color: p.text, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'AI Scanner',
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: p.text,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0E9B83), Color(0xFF1E88E5)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(CupertinoIcons.sparkles, color: Colors.white, size: 10),
                                      SizedBox(width: 4),
                                      Text(
                                        'Gemini AI',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Retsept & Dori qutisi jonli kamerasi',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: p.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isCameraReady)
                        GestureDetector(
                          onTap: _toggleTorch,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _isTorchOn ? const Color(0xFFFFFBEB) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isTorchOn ? const Color(0xFFF59E0B) : const Color(0xFFD2E4DF),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _isTorchOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
                                color: _isTorchOn ? const Color(0xFFD97706) : AppColors.teal,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Main Content View
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Viewfinder Box (Embedded Live Camera Preview)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _captureAndSend,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            height: 340,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF10A188).withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0E9B83).withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 1. Live Camera Preview
                                if (_isCameraReady &&
                                    _cameraController != null &&
                                    _cameraController!.value.isInitialized)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _cameraController!.value.previewSize?.height ?? 1080,
                                          height: _cameraController!.value.previewSize?.width ?? 1920,
                                          child: CameraPreview(_cameraController!),
                                        ),
                                      ),
                                    ),
                                  )
                                else if (_cameraError != null)
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.exclamationmark_triangle_fill,
                                          color: Color(0xFFF59E0B),
                                          size: 40,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _cameraError!,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.manrope(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _initCamera,
                                          icon: const Icon(Icons.refresh, size: 16),
                                          label: const Text('Qayta urinish'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0E9B83),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Kamera ishga tushmoqda...',
                                        style: GoogleFonts.manrope(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),

                                // 2. Animated Laser Scan line + Corner target brackets
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: AnimatedBuilder(
                                      animation: _ctrl,
                                      builder: (context, _) => CustomPaint(
                                        painter: _ScanPainter(_ctrl.value),
                                      ),
                                    ),
                                  ),
                                ),

                                // 3. White flash effect on capture
                                if (_isFlashShutter)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                  ),

                                // 4. Live camera status badge
                                if (_isCameraReady && !_isCapturing)
                                  Positioned(
                                    top: 14,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Dori qutisi yoki retseptni toʻgʻrilang',
                                            style: GoogleFonts.manrope(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // 5. Bottom tap hint inside viewfinder
                                Positioned(
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(CupertinoIcons.camera_fill, color: Color(0xFF10B981), size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Skanerlash uchun tugmani bosing',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11.5,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Shutter & Source Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _actionButton(
                                icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                                label: 'Galereya',
                                onTap: _pickGallery,
                              ),
                              GestureDetector(
                                onTap: _captureAndSend,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0E9B83), Color(0xFF10B981)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0E9B83).withValues(alpha: 0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: Center(
                                          child: _isCapturing
                                              ? const SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.8,
                                                    valueColor: AlwaysStoppedAnimation(Color(0xFF0E9B83)),
                                                  ),
                                                )
                                              : const Icon(
                                                  CupertinoIcons.camera_fill,
                                                  color: Color(0xFF0E9B83),
                                                  size: 34,
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Skanerlash',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0E9B83),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _actionButton(
                                icon: _isTorchOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
                                label: _isTorchOn ? 'Chiroq yoqiq' : 'Chiroq',
                                onTap: _toggleTorch,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Explanatory Guide Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD2E4DF)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0E9B83), Color(0xFF1E88E5)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.sparkles,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gemini AI Skaner',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: p.text,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Dori qutisi yoki retseptni toʻgʻrilang va "Skanerlash" tugmasini bosing. AI tahlil qilish uchun Xabarlar boʻlimiga yoʻnaltiradi.',
                                        style: GoogleFonts.dmSans(
                                          color: p.muted,
                                          fontSize: 11.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final p = context.p;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD2E4DF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.teal, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: p.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ScanPainter extends CustomPainter {
  final double t;
  _ScanPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.85;
    final h = size.height * 0.80;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );

    final p = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const l = 28.0;
    // Four corner target guides
    for (final c in [
      [rect.topLeft, 1.0, 1.0],
      [rect.topRight, -1.0, 1.0],
      [rect.bottomLeft, 1.0, -1.0],
      [rect.bottomRight, -1.0, -1.0],
    ]) {
      final o = c[0] as Offset;
      final dx = c[1] as double, dy = c[2] as double;
      canvas.drawLine(o, o + Offset(l * dx, 0), p);
      canvas.drawLine(o, o + Offset(0, l * dy), p);
    }

    // Glowing laser scan line
    final y = rect.top + rect.height * t;
    canvas.drawRect(
      Rect.fromLTRB(rect.left, y - 36, rect.right, y),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0),
            const Color(0xFF10B981).withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromLTRB(rect.left, y - 36, rect.right, y)),
    );

    canvas.drawLine(
      Offset(rect.left, y),
      Offset(rect.right, y),
      Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanPainter old) => old.t != t;
}
