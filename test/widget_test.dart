import 'package:flutter_test/flutter_test.dart';
import 'package:milepost_app/main.dart';

void main() {
  testWidgets('home lists tools and opens the fuel calculator', (tester) async {
    await tester.pumpWidget(const MilepostApp());
    // Splash animates ~1100ms then fades to home (~300ms).
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Calculators'), findsWidgets);

    await tester.tap(find.text('Calculators').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fuel Cost Calculator'));
    await tester.pumpAndSettle();
    expect(find.text('\$36.96'), findsOneWidget);
  });
}
