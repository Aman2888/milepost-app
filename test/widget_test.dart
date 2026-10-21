import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milepost_app/main.dart';

void main() {
  testWidgets('home lists tools and opens the fuel calculator', (tester) async {
    await tester.pumpWidget(const MilepostApp());
    expect(find.text('Calculators'), findsOneWidget);
    await tester.tap(find.text('Fuel Cost Calculator'));
    await tester.pumpAndSettle();
    expect(find.text('\$36.96'), findsOneWidget);
  });
}
