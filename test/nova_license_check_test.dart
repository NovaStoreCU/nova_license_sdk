import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova_license_sdk/nova_license_sdk.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({required this.statusCode, this.valid = true});

  final int statusCode;
  final bool valid;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = jsonEncode({'data': {'valid': valid}});
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw http.ClientException('network down');
  }
}

NovaLicenseGuardConfig _config({required http.Client client, String? deviceId}) {
  return NovaLicenseGuardConfig(
    apiBase: 'https://novastore.cu/api/v1',
    storeUrl: 'https://novastore.cu',
    packageName: 'com.demo.game',
    deviceId: deviceId,
    httpClient: client,
  );
}

void main() {
  test('verify returns allowed=true for a valid license', () async {
    SharedPreferences.setMockInitialValues({});

    final result = await NovaLicense.verify(_config(client: _FakeHttpClient(statusCode: 200, valid: true)));

    expect(result.allowed, isTrue);
    expect(result.status, NovaLicenseStatus.valid);
    expect(result.deviceCode, isNotNull);
    expect(result.deviceCode!.length, 32);
  });

  test('verify returns allowed=false for a missing license', () async {
    SharedPreferences.setMockInitialValues({});

    final result = await NovaLicense.verify(_config(client: _FakeHttpClient(statusCode: 200, valid: false)));

    expect(result.allowed, isFalse);
    expect(result.status, NovaLicenseStatus.invalid);
  });

  test('verify reports offline error and keeps the device code', () async {
    SharedPreferences.setMockInitialValues({});

    final result = await NovaLicense.verify(_config(client: _ThrowingClient(), deviceId: 'abc123'));

    expect(result.status, NovaLicenseStatus.offline);
    expect(result.offline, isTrue);
    expect(result.allowed, isFalse);
    expect(result.deviceCode, 'abc123');
    expect(result.errorMessage, isNotNull);
  });

  test('verify uses the persisted cached license within grace', () async {
    SharedPreferences.setMockInitialValues({
      'nova_license_sdk_device_id': 'dev-1',
      'nova_license_sdk_cached_valid_at': DateTime.now().millisecondsSinceEpoch,
    });

    final result = await NovaLicense.verify(_config(client: _ThrowingClient(), deviceId: 'dev-1'));

    expect(result.status, NovaLicenseStatus.valid);
    expect(result.allowed, isTrue);
  });

  test('verify returns offline when cache is older than the grace period', () async {
    SharedPreferences.setMockInitialValues({
      'nova_license_sdk_device_id': 'dev-1',
      'nova_license_sdk_cached_valid_at':
          DateTime.now().subtract(const Duration(days: 10)).millisecondsSinceEpoch,
    });

    final result = await NovaLicense.verify(_config(client: _ThrowingClient(), deviceId: 'dev-1'));

    expect(result.status, NovaLicenseStatus.offline);
  });

  test('verify stores device id so a later call reuses it', () async {
    SharedPreferences.setMockInitialValues({});

    final first = await NovaLicense.verify(_config(client: _FakeHttpClient(statusCode: 200, valid: true)));
    final second = await NovaLicense.verify(_config(client: _FakeHttpClient(statusCode: 200, valid: true)));

    expect(second.deviceCode, first.deviceCode);
  });

  test('verify validates the whole JSON uri is built on the api base', () async {
    SharedPreferences.setMockInitialValues({});

    late Uri requested;
    final client = _RecordingClient((uri) => requested = uri);

    await NovaLicense.verify(_config(client: client));

    expect(requested.toString(), 'https://novastore.cu/api/v1/validate');
  });
}

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.onSend);

  final void Function(Uri uri) onSend;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    onSend(request.url);
    final body = jsonEncode({'data': {'valid': true}});
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}