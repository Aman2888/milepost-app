import 'package:flutter/material.dart';
import '../core/calc.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../widgets/ui.dart';

/* 6. Depreciation */
class _ValueBars extends StatelessWidget {
  final List<DepPoint> points;
  final int currentIndex;
  const _ValueBars(this.points, this.currentIndex);

  @override
  Widget build(BuildContext context) {
    final max = points.first.value <= 0 ? 1.0 : points.first.value;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < points.length; i++)
                Expanded(
                  child: Tooltip(
                    message: 'Year ${fixed(points[i].year, 1)}: ${money(points[i].value, 0)}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: FractionallySizedBox(
                        heightFactor: (points[i].value / max).clamp(0.04, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                            color: i == currentIndex
                                ? C.hwy
                                : i > currentIndex
                                    ? Colors.white.withOpacity(0.95)
                                    : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('When new', style: TextStyle(fontSize: 12, color: Colors.white70)),
            Text('In ${numFmt(points.last.year, 1)} years from purchase',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ],
    ));
  }
}

class DepreciationCalc extends StatefulWidget {
  const DepreciationCalc({super.key});
  @override
  State<DepreciationCalc> createState() => _DepState();
}

class _DepState extends State<DepreciationCalc> with NumsMixin {
  late final price = nc('28000');
  late final age = nc('3');
  late final rate = nc('15');
  late final ahead = nc('2');

  @override
  Widget build(BuildContext context) {
    final r = depreciation(price.n, age.n, rate.n, ahead.n);
    return CalcLayout(
      sign: Sign(
        label: 'Estimated value today',
        value: r == null ? null : money(r.current, 0),
        empty: 'Enter a price above zero and a yearly rate below 100%.',
        rows: r == null
            ? const []
            : [
                SignRow('Value in ${numFmt(ahead.n, 1)} ${ahead.n == 1 ? "year" : "years"}',
                    money(r.future, 0)),
                SignRow('Lost so far', money(r.lostSoFar, 0)),
                SignRow('Lost by then',
                    '${money(r.lostByThen, 0)} (${fixed(r.lostByThenPct, 0)}%)'),
              ],
        extra: r == null ? null : _ValueBars(r.points, r.currentIndex),
      ),
      children: [
        NumField(label: 'Purchase price', controller: price, prefix: '\$'),
        FieldRow([
          NumField(label: 'Age of the car', controller: age, unit: 'years'),
          NumField(label: 'Years to look ahead', controller: ahead, unit: 'years'),
        ]),
        NumField(
          label: 'Yearly depreciation',
          controller: rate,
          unit: '% per year',
          hint: 'The share of its value the car loses each year',
        ),
        Chips(
          label: 'Quick picks',
          onPick: (v) => rate.text = v,
          options: const [('Slow, 10%', '10'), ('Typical, 15%', '15'), ('Fast, 20%', '20')],
        ),
      ],
    );
  }
}

/* 7. Wheel offset */
class WheelOffsetCalc extends StatefulWidget {
  const WheelOffsetCalc({super.key});
  @override
  State<WheelOffsetCalc> createState() => _WheelState();
}

class _WheelState extends State<WheelOffsetCalc> with NumsMixin {
  late final ow = nc('8');
  late final oo = nc('35');
  late final nw = nc('9');
  late final no = nc('30');

  @override
  Widget build(BuildContext context) {
    final r = wheelOffset(Wheel(ow.n, oo.n), Wheel(nw.n, no.n));
    final big = r != null && (r.outerShift.abs() > 12.7 || r.innerShift.abs() > 12.7);
    final outerUnit = (r == null || r.outerShift.abs() < 0.05)
        ? 'mm'
        : (r.outerShift > 0 ? 'mm out' : 'mm in');
    final innerText = r == null
        ? ''
        : r.innerShift.abs() < 0.05
            ? 'No change'
            : r.innerShift > 0
                ? '${fixed(r.innerShift, 1)} mm closer to the suspension'
                : '${fixed(-r.innerShift, 1)} mm more clearance';
    final tone = big ? 'yellow' : 'blue';
    return CalcLayout(
      sign: Sign(
        tone: tone,
        label: 'Outer edge of the wheel moves',
        value: r == null ? null : fixed(r.outerShift.abs(), 1),
        unit: r == null ? null : outerUnit,
        empty: 'Enter a width above zero and an offset for both wheels.',
        rows: r == null
            ? const []
            : [
                SignRow('Same shift in inches', '${fixed(r.outerShift.abs() / 25.4, 2)} in'),
                SignRow('Inner edge', innerText),
                SignRow('Backspacing',
                    '${fixed(r.old.inner / 25.4, 2)} to ${fixed(r.next.inner / 25.4, 2)} in'),
                SignRow('Wheel width', '${signed(r.widthChangeIn, 1)} in'),
              ],
        extra: (r != null && big)
            ? SignNote(
                'A shift of more than half an inch can rub on the fender or suspension. Check clearance before you buy.',
                tone: tone)
            : null,
      ),
      children: [
        Panel(
          title: 'Current wheel',
          child: FieldRow([
            NumField(label: 'Wheel width', controller: ow, unit: 'inches'),
            NumField(label: 'Offset (ET)', controller: oo, unit: 'mm', hint: 'On the back of the wheel'),
          ]),
        ),
        Panel(
          title: 'New wheel',
          child: FieldRow([
            NumField(label: 'Wheel width', controller: nw, unit: 'inches'),
            NumField(label: 'Offset (ET)', controller: no, unit: 'mm', hint: 'On the back of the wheel'),
          ]),
        ),
      ],
    );
  }
}

/* 8. Horsepower converter */
class HorsepowerCalc extends StatefulWidget {
  const HorsepowerCalc({super.key});
  @override
  State<HorsepowerCalc> createState() => _HpState();
}

class _HpState extends State<HorsepowerCalc> with NumsMixin {
  late final value = nc('300');
  PowerUnit unit = PowerUnit.hp;

  static const _label = {PowerUnit.hp: 'hp', PowerUnit.kw: 'kW', PowerUnit.ps: 'PS'};
  static const _name = {
    PowerUnit.hp: 'Horsepower (hp)',
    PowerUnit.kw: 'Kilowatts (kW)',
    PowerUnit.ps: 'Metric horsepower (PS)',
  };

  @override
  Widget build(BuildContext context) {
    final r = convertPower(value.n, unit);
    final others = PowerUnit.values.where((u) => u != unit).toList();
    return CalcLayout(
      sign: Sign(
        label: r == null ? 'Converted power' : '${fixed(value.n, 1)} ${_label[unit]} equals',
        value: r == null ? null : fixed(r[others[0]]!, 1),
        unit: _label[others[0]],
        empty: 'Enter a power figure of zero or more.',
        rows: r == null
            ? const []
            : [SignRow(_name[others[1]]!, '${fixed(r[others[1]]!, 1)} ${_label[others[1]]}')],
      ),
      children: [
        Segmented<PowerUnit>(
          label: 'Convert from',
          value: unit,
          onChanged: (u) => setState(() => unit = u),
          options: [for (final u in PowerUnit.values) (u, _name[u]!)],
        ),
        NumField(label: 'Power', controller: value, unit: _label[unit]),
        Chips(
          label: 'Common figures',
          onPick: (v) => value.text = v,
          options: [for (final v in ['100', '150', '200', '300', '500']) ('$v ${_label[unit]}', v)],
        ),
      ],
    );
  }
}

/* 9. Cost per mile */
class CostPerMileCalc extends StatefulWidget {
  const CostPerMileCalc({super.key});
  @override
  State<CostPerMileCalc> createState() => _CpmState();
}

class _CpmState extends State<CostPerMileCalc> with NumsMixin {
  late final miles = nc('12000');
  late final fuel = nc('1800');
  late final insurance = nc('1500');
  late final maintenance = nc('700');
  late final other = nc('300');
  bool perMonth = false;

  /// Switching period converts what is already typed, so the car stays the same.
  void _switch(bool month) {
    if (month == perMonth) return;
    final k = month ? 1 / 12 : 12.0;
    for (final c in [miles, fuel, insurance, maintenance, other]) {
      final v = c.n;
      if (v.isFinite) {
        final r = (v * k * 100).round() / 100;
        c.text = r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();
      }
    }
    setState(() => perMonth = month);
  }

  double _z(TextEditingController c) => c.text.trim().isEmpty ? 0 : c.n;

  @override
  Widget build(BuildContext context) {
    final r = costPerMile(
      miles: miles.n,
      fuel: _z(fuel),
      insurance: _z(insurance),
      maintenance: _z(maintenance),
      other: _z(other),
      perMonth: perMonth,
    );
    final per = perMonth ? 'month' : 'year';
    return CalcLayout(
      sign: Sign(
        label: 'What each mile really costs',
        value: r == null ? null : money(r.perMile, 2),
        unit: 'per mile',
        empty: 'Enter the miles you drive, above zero.',
        rows: r == null
            ? const []
            : [
                SignRow('Per year', money(r.yearly, 0)),
                SignRow('Per month', money(r.monthly, 0)),
              ],
        extra: r == null
            ? null
            : StackBar([
                ('Fuel', r.fuel, '${money(r.fuel, 3)} / mi'),
                ('Insurance', r.insurance, '${money(r.insurance, 3)} / mi'),
                ('Maintenance', r.maintenance, '${money(r.maintenance, 3)} / mi'),
                ('Other', r.other, '${money(r.other, 3)} / mi'),
              ]),
      ),
      children: [
        Segmented<bool>(
          label: 'I know my costs per',
          value: perMonth,
          onChanged: _switch,
          options: const [(false, 'Year'), (true, 'Month')],
        ),
        NumField(label: 'Miles driven per $per', controller: miles, unit: 'miles'),
        FieldRow([
          NumField(label: 'Fuel per $per', controller: fuel, prefix: '\$'),
          NumField(label: 'Insurance per $per', controller: insurance, prefix: '\$'),
        ]),
        FieldRow([
          NumField(
              label: 'Maintenance per $per',
              controller: maintenance,
              prefix: '\$',
              hint: 'Oil, tires, repairs'),
          NumField(
              label: 'Other per $per',
              controller: other,
              prefix: '\$',
              hint: 'Registration, parking, tolls, payments'),
        ]),
      ],
    );
  }
}

/* 10. Auto loan */
class AutoLoanCalc extends StatefulWidget {
  const AutoLoanCalc({super.key});
  @override
  State<AutoLoanCalc> createState() => _LoanState();
}

class _LoanState extends State<AutoLoanCalc> with NumsMixin {
  late final price = nc('32000');
  late final down = nc('4000');
  late final trade = nc('0');
  late final tax = nc('0');
  late final apr = nc('6.5');
  late final term = nc('60');

  double _z(TextEditingController c) => c.text.trim().isEmpty ? 0 : c.n;

  @override
  Widget build(BuildContext context) {
    final r = autoLoan(
      price: price.n,
      down: _z(down),
      trade: _z(trade),
      taxPct: _z(tax),
      apr: apr.n,
      months: term.n,
    );
    return CalcLayout(
      sign: Sign(
        label: 'Your monthly payment',
        value: r == null ? null : money(r.monthly),
        unit: 'a month',
        empty: 'Enter a price above zero, an APR (0 is fine) and a term of at least one month.',
        rows: r == null
            ? const []
            : [
                SignRow('Amount financed', money(r.financed, 0)),
                SignRow('Total interest', money(r.interest, 0)),
                SignRow('Total of all payments', money(r.totalPaid, 0)),
                SignRow('Loan length', '${r.months} months'),
              ],
        extra: (r == null || r.financed <= 0)
            ? null
            : StackBar([
                ('Principal', r.financed, money(r.financed, 0)),
                (
                  'Interest',
                  r.interest < 0 ? 0.0 : r.interest,
                  '${money(r.interest, 0)} (${fixed(r.interest / r.totalPaid * 100, 0)}%)'
                ),
              ]),
      ),
      children: [
        NumField(label: 'Vehicle price', controller: price, prefix: '\$'),
        FieldRow([
          NumField(label: 'Down payment', controller: down, prefix: '\$'),
          NumField(
              label: 'Trade-in value',
              controller: trade,
              prefix: '\$',
              hint: 'Leave at 0 if none'),
        ]),
        FieldRow([
          NumField(label: 'Interest rate (APR)', controller: apr, unit: '%'),
          NumField(label: 'Sales tax', controller: tax, unit: '%', hint: 'Optional. Added to the price.'),
        ]),
        NumField(label: 'Loan term', controller: term, unit: 'months'),
        Chips(
          label: 'Common terms',
          onPick: (v) => term.text = v,
          options: [for (final m in ['36', '48', '60', '72', '84']) ('$m months', m)],
        ),
      ],
    );
  }
}
