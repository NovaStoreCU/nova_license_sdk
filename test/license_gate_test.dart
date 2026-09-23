import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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

Widget _gate({required http.Client client, String? deviceId}) {
  return novaLicenseGuard(
    config: NovaLicenseGuardConfig(
      apiBase: 'https://novastore.cu/api/v1',
      storeUrl: 'https://novastore.cu',
      packageName: 'com.demo.game',
      deviceId: deviceId,
      httpClient: client,
    ),
    child: const Scaffold(body: Center(child: Text('APP ABIERTA'))),
  );
}

void main() {
  testWidgets('valid license opens the app', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(MaterialApp(
      home: _gate(client: _FakeHttpClient(statusCode: 200, valid: true)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('APP ABIERTA'), findsOneWidget);
  });

  testWidgets('missing license shows the required screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(MaterialApp(
      home: _gate(client: _FakeHttpClient(statusCode: 200, valid: false)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Requiere licencia'), findsOneWidget);
    expect(find.text('Tu código de dispositivo'), findsOneWidget);
  });

  testWidgets('network error without cache shows the required screen offline',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(MaterialApp(
      home: _gate(client: _ThrowingClient()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reintentar comprobación'), findsOneWidget);
  });

  testWidgets('cached license survives network outage within grace', (tester) async {
    SharedPreferences.setMockInitialValues({
      'nova_license_sdk_device_id': 'abc123',
      'nova_license_sdk_cached_valid_at': DateTime.now().millisecondsSinceEpoch,
    });

    await tester.pumpWidget(MaterialApp(
      home: _gate(client: _ThrowingClient(), deviceId: 'abc123'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('APP ABIERTA'), findsOneWidget);
  });

  testWidgets('server error falls back to the offline screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(MaterialApp(
      home: _gate(
        client: _FakeHttpClient(statusCode: 500, valid: false),
        deviceId: 'abc123',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reintentar comprobación'), findsOneWidget);
  });
}