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

    expect(find.text('LICENCIA REQUERIDA'), findsOneWidget);
    expect(find.text('0123456789abcdef0123456789abcdef'), findsOneWidget);
    expect(find.text('Copiar Código'), findsOneWidget);
    expect(find.text('Abrir NovaStore en el navegador'), findsOneWidget);
    expect(find.text('Abre la ficha oficial de esta app en NovaStore.'), findsOneWidget);
    expect(find.text('Toca en «Activar Licencia» e ingresa tu código de activación.'), findsOneWidget);
    expect(find.text('Regresa a esta app y presiona «Comprobar Licencia».'), findsOneWidget);
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

    expect(find.text('Reintentar Conexión'), findsOneWidget);
    expect(find.text('SIN CONEXIÓN A INTERNET'), findsOneWidget);
    await tester.ensureVisible(find.text('Reintentar Conexión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar Conexión'));
    expect(retried, isTrue);
  });

  testWidgets('LicenseRequiredScreen shows error message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LicenseRequiredScreen(
          deviceCode: 'abc',
          storeUrl: 'https://novastore.cu',
          errorMessage: 'La licencia no pudo verificarse.',
          onRefresh: () {},
        ),
      ),
    );

    expect(find.text('La licencia no pudo verificarse.'), findsOneWidget);
  });

  testWidgets('LicenseRequiredScreen shows the NovaStore brand', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LicenseRequiredScreen(
          deviceCode: 'abc',
          storeUrl: 'https://novastore.cu',
          onRefresh: () {},
        ),
      ),
    );

    expect(find.text('NovaStore'), findsOneWidget);
  });

  test('novaLicenseGuard is exported', () {
    expect(sdk.novaLicenseGuard, isA<Function>());
  });
}