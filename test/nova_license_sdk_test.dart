import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nova_license_sdk/nova_license_sdk.dart';
import 'package:nova_license_sdk/nova_license_sdk.dart' as sdk;

void main() {
  testWidgets('LicenseRequiredScreen shows the device code', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LicenseRequiredScreen(
          deviceCode: '0123456789abcdef0123456789abcdef',
          storeUrl: 'https://novastore.cu',
          onRefresh: () {},
        ),
      ),
    );

    expect(find.text('Requiere licencia'), findsOneWidget);
    expect(find.text('0123456789abcdef0123456789abcdef'), findsOneWidget);
    expect(find.text('Copiar código'), findsOneWidget);
  });

  testWidgets('LicenseRequiredScreen shows retry when offline', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LicenseRequiredScreen(
          deviceCode: 'abc',
          storeUrl: 'https://novastore.cu',
          offline: true,
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Reintentar comprobación'), findsOneWidget);
    await tester.tap(find.text('Reintentar comprobación'));
    expect(retried, isTrue);
  });

  test('novaLicenseGuard is exported', () {
    expect(sdk.novaLicenseGuard, isA<Function>());
  });
}