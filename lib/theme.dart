import 'package:flutter/material.dart';

/// Global theme mode. Default is light.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// Brand accent colors (same in both modes)
class AppColors {
  static const green = Color(0xFF14C97E);
  static const teal = Color(0xFF12B5B0);
  static const blue = Color(0xFF2B9CE8);
  static const navy = Color(0xFF06192B);

  static const gradient = LinearGradient(
    colors: [green, teal, blue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Mode dependent colors. Use `context.p` inside build methods.
class Palette {
  final bool dark;
  final Color bg, card, cardAlt, border, text, muted;
  final List<Color> bgGradient;

  const Palette._(
      {required this.dark,
      required this.bg,
      required this.card,
      required this.cardAlt,
      required this.border,
      required this.text,
      required this.muted,
      required this.bgGradient});

  static const light = Palette._(
    dark: false,
    bg: Colors.white,
    card: Colors.white,
    cardAlt: Color(0xFFF8FAFB),
    border: Color(0xFFEEF2F4),
    text: Color(0xFF0C2433),
    muted: Color(0xFF7E8E98),
    bgGradient: [Colors.white, Colors.white, Colors.white],
  );

  static const darkP = Palette._(
    dark: true,
    bg: Color(0xFF071524),
    card: Color(0xFF0E2236),
    cardAlt: Color(0xFF14304A),
    border: Color(0xFF1C3D58),
    text: Color(0xFFE8F3FA),
    muted: Color(0xFF7D95A9),
    bgGradient: [Color(0xFF0A2A3A), Color(0xFF071524), Color(0xFF040C16)],
  );

  BoxDecoration get bgDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
}

extension PaletteX on BuildContext {
  Palette get p => Theme.of(this).brightness == Brightness.dark
      ? Palette.darkP
      : Palette.light;
}

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Palette.darkP : Palette.light;
  return ThemeData(
    brightness: b,
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: b,
      surface: p.card,
    ),
    useMaterial3: true,
  );
}

/// Gradient filled button
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  const GradientButton(
      {super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: AppColors.green.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.dark
            ? null
            : [
                BoxShadow(
                    color: const Color(0xFF0B2236).withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
      ),
      child: child,
    );
  }
}
