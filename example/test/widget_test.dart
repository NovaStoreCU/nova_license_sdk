import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova_license_sdk_example/main.dart';

void main() {
  testWidgets('Demo app builds under the license gate', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(DemoApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsWidgets);
  });
}