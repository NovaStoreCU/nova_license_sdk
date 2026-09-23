import 'package:flutter/material.dart';

import 'package:nova_license_sdk/nova_license_sdk.dart';

void main() {
  runApp(
    novaLicenseGuard(
      config: const NovaLicenseGuardConfig(
        apiBase: 'http://192.168.1.17:8000/api/v1',
        storeUrl: 'http://192.168.1.17:8000',
        packageName: 'com.midemo.game',
        storeSlug: 'mi-juego',
      ),
      child: const DemoApp(),
    ),
  );
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NovaLicense SDK Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_rounded, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Licencia válida', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('La app protegida está desbloqueada en este dispositivo.'),
          ],
        ),
      ),
    );
  }
}