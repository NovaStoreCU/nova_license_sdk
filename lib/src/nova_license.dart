import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'license_required_screen.dart';
import 'nova_license_config.dart';

/// Result of a license check.
enum NovaLicenseStatus {
  /// The license is valid: the protected app is shown.
  valid,

  /// The license is missing or the app is re-signed: the required screen is
  /// shown.
  invalid,

  /// Network is unavailable AND there is no cached license within the grace
  /// period.
  offline,

  /// An unexpected error happened while validating (not a plain offline).
  error,
}

/// Result of a license check, including the device code the end user must
/// paste into NovaStore to activate the purchase.
class NovaLicenseCheck {
  const NovaLicenseCheck(this.status, [this.errorMessage, this.deviceCode]);

  final NovaLicenseStatus status;
  final String? errorMessage;

  /// The device id used for this check. Empty until a check ran. Pass it
  /// along when you open NovaStore, or show it to the user as the
  /// "activation code" when [status] is not [NovaLicenseStatus.valid].
  final String? deviceCode;

  /// True when the app may open (license present).
  bool get allowed => status == NovaLicenseStatus.valid;

  /// True when the check failed because there is no network and no fresh
  /// cached license.
  bool get offline =>
      status == NovaLicenseStatus.offline || status == NovaLicenseStatus.error;
}

/// Programmatic license check (mirror of the Android `NovaLicense.check`).
///
/// Unlike [novaLicenseGuard] (which wraps the whole app in a gate), this lets
/// the developer decide WHAT to protect. Call it before opening premium
/// features and react on [NovaLicenseCheck.status]:
///
/// ```dart
/// final result = await NovaLicense.verify(config);
/// if (result.allowed) {
///   openPremium();
/// } else {
///   showMyOwnPaywall();  // you decide
/// }
/// ```
///
/// The backend does NOT change between modes: it always answers
/// valid/invalid per `device_id` (+ optional `apk_sha1`). This mode only
/// hands you that answer so you can implement tiered/premium logic.
abstract final class NovaLicense {
  static Future<NovaLicenseCheck> verify(
    NovaLicenseGuardConfig config,
  ) {
    return _checkLicense(config);
  }
}

/// Entry point: wraps the app in a license gate.
///
/// The returned widget shows a splash while checking, then either [child] or
/// a [LicenseRequiredScreen]. When the license is missing, the screen displays
/// the device code that the user must paste into NovaStore to activate the
/// purchase for this device.
Widget novaLicenseGuard({
  required NovaLicenseGuardConfig config,
  required Widget child,
  WidgetBuilder? splashBuilder,
  WidgetBuilder? errorBuilder,
}) {
  return _LicenseGate(
    config: config,
    splashBuilder: splashBuilder,
    errorBuilder: errorBuilder,
    child: child,
  );
}

/// Convenience default splash shown while validating.
class _DefaultSplash extends StatelessWidget {
  const _DefaultSplash();

  static Widget create(BuildContext context) => const _DefaultSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

const _prefsKeyDevice = 'nova_license_sdk_device_id';
const _prefsKeyCached = 'nova_license_sdk_cached_valid_at';

Future<String> _resolveDeviceId(
  NovaLicenseGuardConfig config,
  SharedPreferences prefs,
) async {
  if (config.deviceId != null && config.deviceId!.trim().isNotEmpty) {
    return config.deviceId!;
  }

  final persisted = prefs.getString(_prefsKeyDevice);
  if (persisted != null && persisted.isNotEmpty) {
    return persisted;
  }

  final fresh = _randomDeviceId();
  await prefs.setString(_prefsKeyDevice, fresh);

  return fresh;
}

String _randomDeviceId() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return hex;
}

/// Builds a random 32-char (16 bytes) hex device id.
Future<NovaLicenseCheck> _checkLicense(NovaLicenseGuardConfig config) async {
  final prefs = await SharedPreferences.getInstance();

  final deviceId = await _resolveDeviceId(config, prefs);

  final base = config.apiBase.replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.parse('$base/validate');

  final client = config.httpClient ?? http.Client();

  try {
    final response = await client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'package_name': config.packageName,
            'device_id': deviceId,
            if (config.apkSha1 != null &&
                config.apkSha1!.trim().isNotEmpty)
              'apk_sha1': config.apkSha1,
          }),
        )
        .timeout(config.httpTimeout);

    if (config.httpClient == null) {
      client.close();
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final valid = data?['valid'] == true;

      if (valid) {
        await prefs.setInt(_prefsKeyCached, DateTime.now().millisecondsSinceEpoch);
      } else {
        await prefs.remove(_prefsKeyCached);
      }

      return NovaLicenseCheck(
        valid ? NovaLicenseStatus.valid : NovaLicenseStatus.invalid,
        null,
        deviceId,
      );
    }

return await _offlineFallback(prefs, config, null, deviceId);
    } catch (e) {
      return await _offlineFallback(prefs, config, e.toString(), deviceId);
    }
}

Future<NovaLicenseCheck> _offlineFallback(
  SharedPreferences prefs,
  NovaLicenseGuardConfig config,
  String? error,
  String? deviceId,
) async {
  final cachedAt = prefs.getInt(_prefsKeyCached);
  if (cachedAt == null) {
    return NovaLicenseCheck(NovaLicenseStatus.offline, error, deviceId);
  }

  final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cachedAt));
  if (age <= config.grace) {
    return NovaLicenseCheck(NovaLicenseStatus.valid, null, deviceId);
  }

  return NovaLicenseCheck(NovaLicenseStatus.offline, error, deviceId);
}

class _LicenseGate extends StatefulWidget {
  const _LicenseGate({
    required this.config,
    required this.child,
    this.splashBuilder,
    this.errorBuilder,
  });

  final NovaLicenseGuardConfig config;
  final Widget child;
  final WidgetBuilder? splashBuilder;
  final WidgetBuilder? errorBuilder;

  @override
  State<_LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<_LicenseGate> {
  NovaLicenseStatus _status = NovaLicenseStatus.valid;
  bool _checking = true;
  String? _error;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _status = NovaLicenseStatus.valid;
      _error = null;
    });

    final result = await _checkLicense(widget.config);

    if (!mounted) {
      return;
    }

    setState(() {
      _checking = false;
      _status = result.status;
      _error = result.errorMessage;
      _deviceId = result.deviceCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return (widget.splashBuilder ?? _DefaultSplash.create)(context);
    }

    if (_status == NovaLicenseStatus.valid) {
      return widget.child;
    }

    final offline = _status == NovaLicenseStatus.offline || _status == NovaLicenseStatus.error;

    if (offline && widget.errorBuilder != null) {
      return widget.errorBuilder!(context);
    }

    return LicenseRequiredScreen(
      deviceCode: _deviceId ?? '- - -',
      storeUrl: _storeUrl(),
      offline: offline,
      errorMessage: _error,
      onRetry: offline ? _check : null,
      onRefresh: offline ? null : _check,
    );
  }

  String _storeUrl() {
    final config = widget.config;
    final base = config.storeUrl.replaceAll(RegExp(r'/+$'), '');
    final slug = config.storeSlug;

    return slug != null && slug.trim().isNotEmpty ? '$base/apps/$slug' : base;
  }
}