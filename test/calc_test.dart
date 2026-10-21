import 'package:flutter_test/flutter_test.dart';
import 'package:milepost_app/core/calc.dart';
import 'package:milepost_app/core/format.dart';

void main() {
  test('fuel cost matches the website example', () {
    final r = fuelCost(300, 28, 3.45)!;
    expect(money(r.cost), '\$36.96');
  });

  test('mpg example', () {
    expect(fixed(mpgCalc(420, 13.5)!.mpg, 1), '31.1');
  });

  test('invalid input returns null', () {
    expect(fuelCost(100, 0, 3), isNull);
    expect(mpgCalc(double.nan, 5), isNull);
  });

  test('tire size parsing and comparison', () {
    final t = parseTireSize('225/45R17')!;
    expect([t.width, t.aspect, t.rim], [225, 45, 17]);
    expect(parseTireSize('abc'), isNull);
    final r = tireCompare(const Tire(225, 45, 17), const Tire(235, 40, 18), 60)!;
    expect(r.diffPct.abs() < 3, isTrue);
  });

  test('auto loan with zero APR splits evenly', () {
    final r = autoLoan(price: 12000, down: 0, trade: 0, taxPct: 0, apr: 0, months: 60)!;
    expect(r.monthly, 200);
  });

  test('horsepower conversion', () {
    final r = convertPower(100, PowerUnit.hp)!;
    expect(fixed(r[PowerUnit.kw]!, 1), '74.6');
  });

  test('number formatting', () {
    expect(money(1234567.891), '\$1,234,567.89');
    expect(numFmt(12.50, 2), '12.5');
    expect(signed(-3.2), '\u22123.2');
    expect(parse('1,200.5'), 1200.5);
    expect(parse('').isNaN, isTrue);
  });
}
