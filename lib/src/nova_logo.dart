import 'package:flutter/material.dart';

/// Logo de NovaStore dibujado con [CustomPaint] (sin dependencias externas).
///
/// Espejo visual del `NovaLogoView` del SDK Android: un cuadrado redondeado
/// con degradado verde → azul, la marca "N" en trazo blanco y el pequeño
/// punto de la esquina superior derecha.
class NovaLogo extends StatelessWidget {
  /// Brand colors por defecto de NovaStore (verde → azul).
  static const Color kBrandTop = Color(0xFF00C853);
  static const Color kBrandBottom = Color(0xFF0091EA);

  const NovaLogo({
    super.key,
    this.size = 28,
    this.radius = 8,
    this.shadow = false,
    this.topColor = kBrandTop,
    this.bottomColor = kBrandBottom,
  });

  final double size;
  final double radius;
  final bool shadow;
  final Color topColor;
  final Color bottomColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, bottomColor],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: topColor.withValues(alpha: 0.35),
                  blurRadius: size * 0.4,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _NovaMarkPainter()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.center,
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NovaMarkPainter extends CustomPainter {
  const _NovaMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    if (s <= 0) return;
    final p = s * 0.28;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = s * 0.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(p, s - p)
        ..lineTo(p, p)
        ..lineTo(s - p, s - p)
        ..lineTo(s - p, p),
      paint,
    );

    final c = Offset(s * 0.85, s * 0.17);
    final r = s * 0.07;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _NovaMarkPainter oldDelegate) => false;
}