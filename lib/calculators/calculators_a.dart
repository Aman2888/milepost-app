import 'package:flutter/material.dart';
import '../core/calc.dart';
import '../core/format.dart';
import '../widgets/ui.dart';

/* 1. Fuel cost */
class FuelCostCalc extends StatefulWidget {
  const FuelCostCalc({super.key});
  @override
  State<FuelCostCalc> createState() => _FuelCostState();
}

class _FuelCostState extends State<FuelCostCalc> with NumsMixin {
  late final distance = nc('300');
  late final mpg = nc('28');
  late final price = nc('3.45');

  @override
  Widget build(BuildContext context) {
    final r = fuelCost(distance.n, mpg.n, price.n);
    return CalcLayout(
      sign: Sign(
        label: 'Fuel for this trip',
        value: r == null ? null : money(r.cost),
        rows: r == null
            ? const []
            : [
                SignRow('Fuel needed', '${numFmt(r.gallons, 1)} gal'),
                SignRow('Cost per mile', money(r.perMile, 3)),
                SignRow('Cost per 100 miles', money(r.per100)),
              ],
      ),
      children: [
        FieldRow([
          NumField(label: 'Trip distance', controller: distance, unit: 'miles'),
          NumField(label: 'Fuel economy', controller: mpg, unit: 'MPG'),
        ]),
        NumField(label: 'Fuel price', controller: price, prefix: '\$', unit: 'per gallon'),
        Chips(
          label: 'Not sure of your MPG? Start from a typical one',
          onPick: (v) => mpg.text = v,
          options: const [
            ('Compact car, 32', '32'),
            ('Sedan, 28', '28'),
            ('SUV, 22', '22'),
            ('Pickup, 18', '18'),
          ],
        ),
      ],
    );
  }
}

/* 2. MPG */
class MpgCalc extends StatefulWidget {
  const MpgCalc({super.key});
  @override
  State<MpgCalc> createState() => _MpgState();
}

class _MpgState extends State<MpgCalc> with NumsMixin {
  late final miles = nc('420');
  late final gallons = nc('13.5');

  @override
  Widget build(BuildContext context) {
    final r = mpgCalc(miles.n, gallons.n);
    return CalcLayout(
      sign: Sign(
        label: 'Your fuel economy',
        value: r == null ? null : fixed(r.mpg, 1),
        unit: 'MPG',
        empty: 'Enter miles driven and gallons used (gallons above zero).',
        rows: r == null
            ? const []
            : [
                SignRow('Litres per 100 km', fixed(r.lPer100km, 1)),
                SignRow('Kilometres per litre', fixed(r.kmPerL, 1)),
              ],
        extra: r == null ? null : Meter(value: r.mpg, min: 10, max: 60, minLabel: '10 MPG', maxLabel: '60 MPG'),
      ),
      children: [
        NumField(
            label: 'Miles driven', controller: miles, unit: 'miles', hint: 'Since your last fill-up'),
        NumField(
            label: 'Fuel added',
            controller: gallons,
            unit: 'gallons',
            hint: 'What the pump says at the next fill-up'),
      ],
    );
  }
}

/* 3. EV charging */
class EvChargingCalc extends StatefulWidget {
  const EvChargingCalc({super.key});
  @override
  State<EvChargingCalc> createState() => _EvState();
}

class _EvState extends State<EvChargingCalc> with NumsMixin {
  late final battery = nc('60');
  late final rate = nc('0.16');
  late final from = nc('0');
  late final to = nc('100');
  late final eff = nc('90');
  late final mikwh = nc('3.5');

  @override
  Widget build(BuildContext context) {
    final r = evCharge(
        battery: battery.n,
        rate: rate.n,
        from: from.n,
        to: to.n,
        eff: eff.n,
        milesPerKwh: mikwh.n);
    final isFull = from.n == 0 && to.n == 100;
    return CalcLayout(
      sign: Sign(
        label: isFull ? 'Cost of a full charge' : 'Cost of this charge',
        value: r == null ? null : money(r.cost),
        empty: 'Start % must be lower than end %, and efficiency has to be between 1 and 100.',
        rows: r == null
            ? const []
            : [
                SignRow('Added to the battery', '${numFmt(r.added, 1)} kWh'),
                SignRow('Drawn from the wall', '${numFmt(r.drawn, 1)} kWh'),
                SignRow('Range added', '${numFmt(r.rangeAdded, 0)} miles'),
                SignRow('Cost per mile', r.costPerMile == null ? 'n/a' : money(r.costPerMile!, 3)),
                if (!isFull) SignRow('0 to 100% would cost', money(r.fullCost)),
              ],
      ),
      children: [
        FieldRow([
          NumField(label: 'Battery size', controller: battery, unit: 'kWh'),
          NumField(label: 'Electricity rate', controller: rate, prefix: '\$', unit: 'per kWh'),
        ]),
        Chips(
          label: 'Typical rates',
          onPick: (v) => rate.text = v,
          options: const [
            ('Home, \$0.16', '0.16'),
            ('Public Level 2, \$0.30', '0.30'),
            ('DC fast charger, \$0.48', '0.48'),
          ],
        ),
        FieldRow([
          NumField(label: 'Start charge', controller: from, unit: '%'),
          NumField(label: 'End charge', controller: to, unit: '%'),
        ]),
        FieldRow([
          NumField(
              label: 'Charging efficiency',
              controller: eff,
              unit: '%',
              hint: 'Energy that reaches the battery. 85 to 95% is common.'),
          NumField(
              label: 'Driving efficiency',
              controller: mikwh,
              unit: 'mi/kWh',
              hint: 'Used for range and cost per mile'),
        ]),
      ],
    );
  }
}

/* 4. Road trip */
class RoadTripCalc extends StatefulWidget {
  const RoadTripCalc({super.key});
  @override
  State<RoadTripCalc> createState() => _RoadTripState();
}

class _RoadTripState extends State<RoadTripCalc> with NumsMixin {
  late final miles = nc('500');
  late final mpg = nc('28');
  late final gas = nc('3.45');
  late final tolls = nc('12');
  late final other = nc('150');
  late final travelers = nc('2');
  bool roundTrip = true;

  @override
  Widget build(BuildContext context) {
    final r = roadTrip(
      miles: miles.n,
      mpg: mpg.n,
      gas: gas.n,
      tolls: tolls.n,
      other: other.n,
      travelers: travelers.n,
      roundTrip: roundTrip,
    );
    return CalcLayout(
      sign: Sign(
        label: roundTrip ? 'Total for the round trip' : 'Total for the trip',
        value: r == null ? null : money(r.total),
        empty: 'Enter a distance and MPG above zero.',
        rows: r == null
            ? const []
            : [
                SignRow('Each person pays', money(r.perPerson)),
                SignRow('Distance', '${numFmt(r.totalMiles, 0)} miles'),
                SignRow('Fuel used', '${numFmt(r.gallons, 1)} gal'),
                SignRow('All-in cost per mile', money(r.perMile, 3)),
              ],
        extra: r == null
            ? null
            : StackBar([
                ('Fuel', r.fuel, money(r.fuel)),
                ('Tolls', r.tollsTotal, money(r.tollsTotal)),
                ('Other costs', r.other, money(r.other)),
              ]),
      ),
      children: [
        Segmented<bool>(
          label: 'Trip type',
          value: roundTrip,
          onChanged: (v) => setState(() => roundTrip = v),
          options: const [(false, 'One way'), (true, 'Round trip')],
        ),
        FieldRow([
          NumField(label: 'One-way distance', controller: miles, unit: 'miles'),
          NumField(label: 'Fuel economy', controller: mpg, unit: 'MPG'),
        ]),
        FieldRow([
          NumField(label: 'Gas price', controller: gas, prefix: '\$', unit: '/gal'),
          NumField(
              label: 'Tolls, one way',
              controller: tolls,
              prefix: '\$',
              hint: 'Doubled for a round trip'),
        ]),
        FieldRow([
          NumField(
              label: 'Other costs', controller: other, prefix: '\$', hint: 'Food, lodging, parking'),
          NumField(label: 'People sharing the cost', controller: travelers),
        ]),
      ],
    );
  }
}

/* 5. Tire size */
class _TireBlock extends StatefulWidget {
  final String title;
  final TextEditingController width, aspect, rim;
  const _TireBlock(
      {required this.title, required this.width, required this.aspect, required this.rim});
  @override
  State<_TireBlock> createState() => _TireBlockState();
}

class _TireBlockState extends State<_TireBlock> {
  final paste = TextEditingController();

  @override
  void dispose() {
    paste.dispose();
    super.dispose();
  }

  void _onPaste(String text) {
    final t = parseTireSize(text);
    if (t != null) {
      widget.width.text = numFmt(t.width, 0).replaceAll(',', '');
      widget.aspect.text = numFmt(t.aspect, 0).replaceAll(',', '');
      widget.rim.text = numFmt(t.rim, 0).replaceAll(',', '');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bad = paste.text.trim().isNotEmpty && parseTireSize(paste.text) == null;
    return Panel(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: paste,
            onChanged: _onPaste,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Type or paste a size',
              hintText: '225/45R17',
              helperText: bad ? null : 'Or fill in the three boxes below',
              errorText: bad ? 'Use a format like 225/45R17' : null,
            ),
          ),
          const SizedBox(height: 12),
          FieldRow([
            NumField(label: 'Width', controller: widget.width, unit: 'mm'),
            NumField(label: 'Aspect', controller: widget.aspect, unit: '%'),
            NumField(label: 'Rim', controller: widget.rim, unit: 'in'),
          ]),
        ],
      ),
    );
  }
}

class TireSizeCalc extends StatefulWidget {
  const TireSizeCalc({super.key});
  @override
  State<TireSizeCalc> createState() => _TireState();
}

class _TireState extends State<TireSizeCalc> with NumsMixin {
  late final ow = nc('225');
  late final oa = nc('45');
  late final orim = nc('17');
  late final nw = nc('235');
  late final na = nc('40');
  late final nrim = nc('18');
  late final speed = nc('60');

  @override
  Widget build(BuildContext context) {
    final r = tireCompare(Tire(ow.n, oa.n, orim.n), Tire(nw.n, na.n, nrim.n), speed.n);
    final within = r == null ? true : r.diffPct.abs() <= 3;
    final tone = within ? 'green' : 'yellow';
    return CalcLayout(
      sign: Sign(
        tone: tone,
        label: 'Overall diameter change',
        value: r == null ? null : '${signed(r.diffPct, 1)}%',
        empty: 'Fill in every size box with a number above zero.',
        rows: r == null
            ? const []
            : [
                SignRow('Current diameter',
                    '${fixed(r.old.diameterIn, 1)} in (${numFmt(r.old.diameter, 0)} mm)'),
                SignRow('New diameter',
                    '${fixed(r.next.diameterIn, 1)} in (${numFmt(r.next.diameter, 0)} mm)'),
                SignRow('Difference', '${signed(r.diffMm, 1)} mm'),
                SignRow('Real speed when it reads ${numFmt(speed.n, 0)}',
                    '${fixed(r.actualSpeed, 1)} mph'),
                SignRow('Sidewall height', '${signed(r.sidewallDiff, 1)} mm'),
                SignRow('Tire width', '${signed(r.widthDiff, 0)} mm'),
              ],
        extra: r == null
            ? null
            : SignNote(
                within
                    ? 'Within about 3%, so the speedometer and gearing should stay close to stock.'
                    : 'More than 3% off. Expect a noticeable speedometer error, and check that the tire clears the fender and suspension.',
                tone: tone,
              ),
      ),
      children: [
        _TireBlock(title: 'Current tire', width: ow, aspect: oa, rim: orim),
        _TireBlock(title: 'New tire', width: nw, aspect: na, rim: nrim),
        NumField(
          label: 'Speedometer reading to check',
          controller: speed,
          unit: 'mph',
          hint: 'We show your real speed when the dash says this',
        ),
      ],
    );
  }
}
