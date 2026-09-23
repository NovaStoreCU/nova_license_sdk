/// NovaStore soft (lazy) license SDK.
///
/// Two integration styles, same backend (`POST /validate`):
///
/// 1. **All-or-nothing gate** (2 lines): wrap the whole app with
///    [novaLicenseGuard]. Without a valid license the user only sees the
///    license screen.
///
/// ```dart
/// void main() {
///   runApp(novaLicenseGuard(
///     config: const NovaLicenseGuardConfig(
///       apiBase: 'https://novastore.cu/api/v1',
///       storeUrl: 'https://novastore.cu',
///       packageName: 'com.mycompany.game',
///     ),
///     child: const MyApp(),
///   ));
/// }
/// ```
///
/// 2. **Programmatic check** (the developer decides): call [NovaLicense.verify]
///    and decide what to protect. Great for premium tiers, feature-level
///    gating or trial logic:
///
/// ```dart
/// final result = await NovaLicense.verify(config);
/// if (result.allowed) {
///   openPremium();
/// } else {
///   hidePremium();
/// }
/// ```
///
/// In both styles the store answers valid/invalid per `device_id`, with an
/// optional `apk_sha1` anti re-signing check, and a configurable offline
/// grace period.
library;

export 'src/nova_license.dart';
export 'src/nova_license_config.dart';
export 'src/license_required_screen.dart';
export 'src/nova_logo.dart';