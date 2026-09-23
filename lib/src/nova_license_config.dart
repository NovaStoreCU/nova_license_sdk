import 'package:http/http.dart' as http;

/// Global configuration for the NovaStore license gate.
class NovaLicenseGuardConfig {
  const NovaLicenseGuardConfig({
    required this.apiBase,
    required this.storeUrl,
    required this.packageName,
    this.storeSlug,
    this.deviceId,
    this.apkSha1,
    this.grace = const Duration(days: 3),
    this.httpTimeout = const Duration(seconds: 10),
    this.httpClient,
  });

  /// Base URL of the NovaStore API, e.g. `https://novastore.cu/api/v1`.
  final String apiBase;

  /// Public base URL of the NovaStore storefront, used by the buy button
  /// (e.g. `https://novastore.cu` or `https://novastore.cu/apps/{slug}`).
  final String storeUrl;

  /// Package name of this app as registered in NovaStore (e.g.
  /// `com.mycompany.game`). Used to validate the license.
  final String packageName;

  /// Optional store slug of this app. When present it is appended to
  /// [storeUrl] so the buy button lands on the app detail page.
  final String? storeSlug;

  /// Stable device identifier. When absent the SDK reads the persisted one or
  /// generates a new device_id on first run and stores it.
  final String? deviceId;

  /// Signing SHA-1 of the installed APK (the release certificate). When
  /// provided the store rejects re-signed APKs.
  final String? apkSha1;

  /// Offline grace: how long a previously valid license is trusted without
  /// network access. Defaults to 3 days.
  final Duration grace;

  /// HTTP timeout for the validation request.
  final Duration httpTimeout;

  /// Injectable HTTP client. Used by tests; when absent the SDK creates one.
  final http.Client? httpClient;
}