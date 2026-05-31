import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/config/theme.dart';
import 'package:flutter_app/screens/login_screen.dart';

void main() {
  testWidgets('SmartMenu login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const LoginScreen()),
    );

    expect(find.text('SmartMenu'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    expect(find.text('Login to Dashboard'), findsOneWidget);
  });
}
