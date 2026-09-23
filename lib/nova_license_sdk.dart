/// NovaStore soft (lazy) license SDK. 2-line integration:
///
/// ```dart
/// void main() {
///   runApp(novaLicenseGuard(
///     config: NovaLicenseGuardConfig(
///       apiBase: 'https://novastore.cu/api/v1',
///       storeUrl: 'https://novastore.cu',
///       packageName: 'com.mycompany.game',
///     ),
///     child: const MyApp(),
///   ));
/// }
/// ```
///
/// The gate validates the license on device startup against `POST /validate`,
/// caches the result with a configurable offline grace period, and when the
/// license is missing shows a [LicenseRequiredScreen] that lets the user buy
/// the app on [NovaLicenseGuardConfig.storeUrl].
library;

export 'src/nova_license.dart';
export 'src/nova_license_config.dart';
export 'src/license_required_screen.dart';