import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen shown when the device is not licensed for this app.
///
/// Displays the device code the user must activate: they open this app in
/// NovaStore, paste the device code when buying, and the purchase is bound to
/// that device id.
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

  void _openStore(BuildContext context) async {
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
    final colors = Theme.of(context);
    final accent = brandColor ?? colors.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 56, color: accent),
                  const SizedBox(height: 16),
                  Text(
                    'Requiere licencia',
                    textAlign: TextAlign.center,
                    style: colors.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offline
                        ? 'Este dispositivo todavía no tiene una licencia válida para esta app.'
                        : 'Este dispositivo todavía no tiene una licencia para esta app.',
                    textAlign: TextAlign.center,
                    style: colors.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Tu código de dispositivo',
                            style: colors.textTheme.labelLarge?.copyWith(color: colors.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            deviceCode,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _copyCode(context),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copiar código'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    offline
                        ? 'Sin conexión. Conéctate a internet y reintenta, o compra la '
                            'app desde NovaStore con este código.'
                        : '1. Abre la app en NovaStore.\n'
                            '2. Toca Comprar y pega este código como "Código de activación".\n'
                            '3. Al confirmar, esta app se desbloquea en este dispositivo.',
                    textAlign: TextAlign.start,
                    style: colors.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: offline ? onRetry : onRefresh,
                    icon: Icon(offline ? Icons.refresh_rounded : Icons.verified_rounded, size: 20),
                    label: Text(offline ? 'Reintentar comprobación' : 'Ya la compré, comprobar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _openStore(context),
                    child: const Text('Abrir NovaStore en el navegador'),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: colors.textTheme.bodySmall?.copyWith(color: colors.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}