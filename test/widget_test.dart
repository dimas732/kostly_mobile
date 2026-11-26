import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kost_ly/main.dart';

void main() {
  testWidgets('KostLy opens with its branded splash screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('KostLy'), findsOneWidget);
    expect(find.text('Find Your Best Living Space'), findsOneWidget);

    // Dispose the splash before its delayed navigation starts Firebase Auth.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
