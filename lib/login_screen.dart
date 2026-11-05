import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'services/api_service.dart';
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsRegister;

  const LoginScreen({
    super.key,
    this.initialIsRegister = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _isRegister;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Login controllers
  final _loginCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController(text: '1234');
  final _loginFocus = FocusNode();
  final _passFocus = FocusNode();

  // Register controllers
  final _nameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _regEmailFocus = FocusNode();
  final _regPassFocus = FocusNode();
  final _regConfirmPassFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    _loginFocus.dispose();
    _passFocus.dispose();

    _nameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    _nameFocus.dispose();
    _regEmailFocus.dispose();
    _regPassFocus.dispose();
    _regConfirmPassFocus.dispose();

    super.dispose();
  }

  void _showSnack(String message, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitLogin() async {
    final login = _loginCtrl.text.trim();
    final password = _passCtrl.text;

    if (login.isEmpty || password.isEmpty) {
      _showSnack("Iltimos, login va parolni kiriting", Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.instance.login(login, password);

      if (!mounted) return;

      if (res['success'] == true) {
        _showSnack(
          res['message'] ?? "Muvaffaqiyatli kirildi",
          AppColors.green,
        );
        _enter();
      } else {
        _showSnack(
          res['message'] ?? "Login yoki parol noto'g'ri",
          Colors.redAccent,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack("Ulanishda xatolik yuz berdi: $e", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final password = _regPassCtrl.text;
    final confirm = _regConfirmPassCtrl.text;

    if (name.isEmpty) {
      _showSnack("Iltimos, to'liq ismingizni kiriting", Colors.orangeAccent);
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showSnack("Iltimos, to'g'ri elektron pochta kiriting", Colors.orangeAccent);
      return;
    }

    if (password.length < 4) {
      _showSnack("Parol kamida 4 ta belgidan iborat bo'lishi kerak", Colors.orangeAccent);
      return;
    }

    if (password != confirm) {
      _showSnack("Parollar bir-biriga mos kelmadi", Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.instance.register(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        _showSnack(
          res['message'] ?? "Ro'yxatdan muvaffaqiyatli o'tildi!",
          AppColors.green,
        );
        _enter();
      } else {
        _showSnack(
          res['message'] ?? "Ro'yxatdan o'tishda xatolik yuz berdi",
          Colors.redAccent,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack("Ulanishda xatolik yuz berdi: $e", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _enter() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondary) => const HomeScreen(),
        transitionsBuilder: (context, a, secondary, child) =>
            FadeTransition(opacity: a, child: child),
      ),
      (route) => false,
    );
  }

  Widget _field(
    String hint,
    IconData icon, {
    bool password = false,
    bool isConfirm = false,
    TextInputType keyboardType = TextInputType.text,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    final p = context.p;
    final isObscured = isConfirm ? _obscureConfirm : _obscure;
    final fieldBg = p.dark ? const Color(0xFF0E2236) : const Color(0xFFF8FAFB);

    return Container(
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: password && isObscured,
        style: TextStyle(color: p.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: p.muted, fontSize: 14),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppColors.teal, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          suffixIcon: password
              ? IconButton(
                  icon: Icon(
                    isObscured ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    color: isObscured ? p.muted : AppColors.teal,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirm) {
                        _obscureConfirm = !_obscureConfirm;
                      } else {
                        _obscure = !_obscure;
                      }
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _bio(IconData icon) {
    final p = context.p;
    return InkWell(
      onTap: _enter,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
        ),
        child: Icon(icon, color: AppColors.teal, size: 28),
      ),
    );
  }

  Widget _buildAuthSwitcher(Palette p) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.dark ? const Color(0xFF14304A) : const Color(0xFFF1F5F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isRegister) setState(() => _isRegister = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isRegister ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isRegister
                      ? [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Kirish',
                    style: TextStyle(
                      color: !_isRegister ? Colors.white : p.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isRegister) setState(() => _isRegister = true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isRegister ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isRegister
                      ? [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    "Ro'yxatdan o'tish",
                    style: TextStyle(
                      color: _isRegister ? Colors.white : p.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final solidBg = p.dark ? const Color(0xFF071524) : Colors.white;

    return Material(
      color: solidBg,
      child: Scaffold(
        backgroundColor: solidBg,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: solidBg,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Brand Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: p.dark ? const Color(0xFF0E2236) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: p.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800),
                          children: [
                            TextSpan(
                              text: 'KUmedFarm',
                              style: TextStyle(
                                color: p.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RAQAMLI TIBBIYOT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Tab Switcher (Kirish / Ro'yxatdan o'tish)
                _buildAuthSwitcher(p),

                const SizedBox(height: 18),

                // Title and Subtitle
                Text(
                  _isRegister ? "Yangi hisob yaratish" : "Xush kelibsiz",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRegister
                      ? "KUmedFarm ekotizimida ro'yxatdan o'ting"
                      : "Hisobingizga kiring",
                  style: TextStyle(
                    fontSize: 13,
                    color: p.muted,
                  ),
                ),

                const SizedBox(height: 20),

                // Form Fields
                if (!_isRegister) ...[
                  // LOGIN FORM
                  _field(
                    'Login yoki Email',
                    CupertinoIcons.person_fill,
                    controller: _loginCtrl,
                    focusNode: _loginFocus,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    'Parol',
                    CupertinoIcons.lock_fill,
                    password: true,
                    controller: _passCtrl,
                    focusNode: _passFocus,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Demo: admin / 1234',
                      style: TextStyle(color: p.muted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(color: AppColors.teal),
                          ),
                        )
                      : GradientButton(
                          label: 'Tizimga kirish',
                          onTap: _submitLogin,
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _bio(CupertinoIcons.viewfinder),
                      const SizedBox(width: 24),
                      _bio(CupertinoIcons.barcode_viewfinder),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hisobingiz yo'qmi?",
                        style: TextStyle(color: p.muted, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isRegister = true),
                        child: const Text(
                          "Ro'yxatdan o'tish",
                          style: TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // REGISTER FORM
                  _field(
                    'To\'liq ismingiz',
                    CupertinoIcons.person_crop_circle_fill,
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    'Elektron pochta (email)',
                    CupertinoIcons.mail_solid,
                    keyboardType: TextInputType.emailAddress,
                    controller: _regEmailCtrl,
                    focusNode: _regEmailFocus,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    'Parol (kamida 4 ta belgi)',
                    CupertinoIcons.lock_fill,
                    password: true,
                    controller: _regPassCtrl,
                    focusNode: _regPassFocus,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    'Parolni tasdiqlang',
                    CupertinoIcons.lock_shield_fill,
                    password: true,
                    isConfirm: true,
                    controller: _regConfirmPassCtrl,
                    focusNode: _regConfirmPassFocus,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(color: AppColors.teal),
                          ),
                        )
                      : GradientButton(
                          label: "Ro'yxatdan o'tish",
                          onTap: _submitRegister,
                        ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hisobingiz bormi?",
                        style: TextStyle(color: p.muted, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isRegister = false),
                        child: const Text(
                          "Kirish",
                          style: TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
