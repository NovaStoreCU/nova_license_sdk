import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'nova_logo.dart';

// Paleta clara (misma que el SDK Android).
const Color _bgTop = Color(0xFFF8FAFC);
const Color _bgBottom = Color(0xFFEDF2F7);
const Color _surface = Color(0xFFFFFFFF);
const Color _cardStroke = Color(0xFFE2E8F0);
const Color _textMain = Color(0xFF0F172A);
const Color _textSub = Color(0xFF475569);
const Color _textDim = Color(0xFF94A3B8);
const Color _codeGreen = Color(0xFF059669);
const Color _errorBg = Color(0xFFFEF2F2);
const Color _errorStroke = Color(0xFFFCA5A5);
const Color _errorText = Color(0xFFDC2626);

/// Full-screen shown when the device is not licensed for this app.
///
/// Displays the device code the user must activate: they open this app in
/// NovaStore, paste the device code when buying, and the purchase is bound to
/// that device id.
///
/// Pantalla de licencia NovaStore (tema claro, estilo UI moderna). Espejo
/// visual del `LicenseRequiredView` del SDK Android.
class LicenseRequiredScreen extends StatelessWidget {
  const LicenseRequiredScreen({
    super.key,
    required this.deviceCode,
    required this.storeUrl,
    this.offline = false,
    this.errorMessage,
    this.onRetry,
    this.onRefresh,
    this.brandColor,
  });

  /// The device id this app recognizes as "this device". It is the code the
  /// buyer pastes into NovaStore to bind the purchase.
  final String deviceCode;

  /// URL of the NovaStore storefront (app detail when the slug is known).
  final String storeUrl;

  /// When true the check failed because the network is unavailable; show a
  /// retry, and hint that the user can still open the store.
  final bool offline;

  final String? errorMessage;

  /// Called when the user taps "Reintentar" (only in [offline] mode).
  final VoidCallback? onRetry;

  /// Called when the user taps "Ya compré / comprobar" (online mode).
  final VoidCallback? onRefresh;

  /// Optional accent color (defaults to a store-like gradient if present).
  final Color? brandColor;

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: deviceCode.replaceAll(RegExp(r'[\s-]+'), '')));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código copiado al portapapeles.')),
      );
    }
  }

  Future<void> _openStore(BuildContext context) async {
    if (storeUrl.isNotEmpty) {
      final ok = await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir: $storeUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = brandColor ?? NovaLogo.kBrandBottom;
    final brandTop = brandColor ?? NovaLogo.kBrandTop;
    final brandBottom = brandColor != null ? _accentTone(brandColor!) : NovaLogo.kBrandBottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ----- Logo y Marca Superior -----
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const NovaLogo(size: 26, radius: 8),
                          const SizedBox(width: 8),
                          Text(
                            'NovaStore',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textMain,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ----- Header Hero (banner degradado de marca) -----
                    const SizedBox(height: 20),
                    _Hero(
                      brandTop: brandTop,
                      brandBottom: brandBottom,
                      offline: offline,
                    ),

                    // ----- Tarjeta de código de activación -----
                    const SizedBox(height: 16),
                    _CodeCard(
                      deviceCode: deviceCode,
                      accent: accent,
                      onCopy: () => _copyCode(context),
                    ),

                    // ----- Pasos de instrucciones en tarjeta -----
                    const SizedBox(height: 16),
                    _StepsCard(
                      offline: offline,
                      accent: accent,
                      brandTop: brandTop,
                      brandBottom: brandBottom,
                    ),

                    // ----- Tarjeta de error (si existe) -----
                    if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ErrorCard(errorMessage: errorMessage!),
                    ],

                    // ----- Botón principal de acción -----
                    const SizedBox(height: 18),
                    _GradientButton(
                      label: offline ? 'Reintentar Conexión' : 'Comprobar Licencia',
                      top: brandTop,
                      bottom: brandBottom,
                      onPressed: offline ? onRetry : onRefresh,
                    ),

                    // ----- Enlace web NovaStore -----
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => _openStore(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        child: Text(
                          'Abrir NovaStore en el navegador',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
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
    );
  }

  static Color _accentTone(Color color) => Color.fromRGBO(
        (color.r * 255.0 * 0.72).round().clamp(0, 255),
        (color.g * 255.0 * 0.72).round().clamp(0, 255),
        (color.b * 255.0 * 0.72).round().clamp(0, 255),
        1,
      );
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.brandTop,
    required this.brandBottom,
    required this.offline,
  });

  final Color brandTop;
  final Color brandBottom;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandTop, brandBottom],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brandTop.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const NovaLogo(size: 54, radius: 14, shadow: true),
          const SizedBox(height: 12),
          Text(
            offline ? 'SIN CONEXIÓN A INTERNET' : 'LICENCIA REQUERIDA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            offline
                ? 'Conéctate a una red para verificar tu licencia y comenzar a usar esta aplicación.'
                : 'Este dispositivo requiere una licencia activa para desbloquear esta aplicación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.deviceCode,
    required this.accent,
    required this.onCopy,
  });

  final String deviceCode;
  final Color accent;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return _surfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'CÓDIGO DE ACTIVACIÓN DE TU DISPOSITIVO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _textDim,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              children: [
                SelectableText(
                  deviceCode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: _codeGreen,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mantén presionado para copiar',
                  style: TextStyle(fontSize: 10, color: _textDim),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OutlineButton(
            label: 'Copiar Código',
            accent: accent,
            height: 40,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({
    required this.offline,
    required this.accent,
    required this.brandTop,
    required this.brandBottom,
  });

  final bool offline;
  final Color accent;
  final Color brandTop;
  final Color brandBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardStroke),
      ),
      child: offline
          ? _InfoRow(
              accent: accent,
              text:
                  'Verifica tu conexión a internet y pulsa Reintentar. Si el problema persiste, adquiere la app desde NovaStore.',
            )
          : Column(
              children: [
                _StepRow(number: '1', text: 'Abre la ficha oficial de esta app en NovaStore.', brandTop: brandTop, brandBottom: brandBottom),
                _StepRow(number: '2', text: 'Toca en «Activar Licencia» e ingresa tu código de activación.', brandTop: brandTop, brandBottom: brandBottom),
                _StepRow(number: '3', text: 'Regresa a esta app y presiona «Comprobar Licencia».', brandTop: brandTop, brandBottom: brandBottom),
              ],
            ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.text,
    required this.brandTop,
    required this.brandBottom,
  });

  final String number;
  final String text;
  final Color brandTop;
  final Color brandBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Círculo de tamaño exacto: nunca se recorta.
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brandTop, brandBottom],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: _textSub, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.accent, required this.text});

  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11.5, color: _textSub, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _errorStroke),
      ),
      child: Row(
        children: [
          Icon(Icons.error_rounded, size: 18, color: _errorText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(errorMessage, style: const TextStyle(fontSize: 11, color: _errorText, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.top,
    required this.bottom,
    required this.onPressed,
  });

  final String label;
  final Color top;
  final Color bottom;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, bottom],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.accent,
    required this.height,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _surface,
          side: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
      ),
    );
  }
}

Widget _surfaceCard({
  required double radius,
  required EdgeInsets padding,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _cardStroke),
      boxShadow: const [
        BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 1)),
      ],
    ),
    child: child,
  );
}