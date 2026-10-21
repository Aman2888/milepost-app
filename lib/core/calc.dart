/// Pure calculation helpers, ported 1:1 from lib/calc.ts.
/// Each function returns null when the inputs can't give a sensible answer.
import 'dart:math' as math;

bool _finite(List<double> n) => n.every((x) => x.isFinite);

/* 1. Fuel cost */
class FuelCostResult {
  final double gallons, cost, perMile, per100;
  FuelCostResult(this.gallons, this.cost, this.perMile, this.per100);
}

FuelCostResult? fuelCost(double distance, double mpg, double price) {
  if (!_finite([distance, mpg, price]) || distance < 0 || mpg <= 0 || price < 0) return null;
  final gallons = distance / mpg;
  final perMile = price / mpg;
  return FuelCostResult(gallons, gallons * price, perMile, perMile * 100);
}

/* 2. MPG */
class MpgResult {
  final double mpg, lPer100km, kmPerL;
  MpgResult(this.mpg, this.lPer100km, this.kmPerL);
}

MpgResult? mpgCalc(double miles, double gallons) {
  if (!_finite([miles, gallons]) || miles < 0 || gallons <= 0) return null;
  final mpg = miles / gallons;
  return MpgResult(mpg, mpg > 0 ? 235.214583 / mpg : 0, mpg * 0.425144);
}

/* 3. EV charging */
class EvResult {
  final double added, drawn, cost, rangeAdded, fullCost;
  final double? costPerMile;
  EvResult(this.added, this.drawn, this.cost, this.rangeAdded, this.costPerMile, this.fullCost);
}

EvResult? evCharge({
  required double battery,
  required double rate,
  required double from,
  required double to,
  required double eff,
  required double milesPerKwh,
}) {
  if (!_finite([battery, rate, from, to, eff, milesPerKwh])) return null;
  if (battery <= 0 || rate < 0 || from < 0 || to > 100 || to <= from) return null;
  if (eff <= 0 || eff > 100 || milesPerKwh < 0) return null;
  final added = battery * (to - from) / 100;
  final drawn = added / (eff / 100);
  return EvResult(
    added,
    drawn,
    drawn * rate,
    added * milesPerKwh,
    milesPerKwh > 0 ? rate / ((eff / 100) * milesPerKwh) : null,
    (battery / (eff / 100)) * rate,
  );
}

/* 4. Road trip */
class RoadTripResult {
  final double totalMiles, gallons, fuel, tollsTotal, other, total, perPerson, perMile;
  final int people;
  RoadTripResult(this.totalMiles, this.gallons, this.fuel, this.tollsTotal, this.other,
      this.total, this.people, this.perPerson, this.perMile);
}

RoadTripResult? roadTrip({
  required double miles,
  required double mpg,
  required double gas,
  required double tolls,
  required double other,
  required double travelers,
  required bool roundTrip,
}) {
  if (!_finite([miles, mpg, gas, tolls, other, travelers])) return null;
  if (miles <= 0 || mpg <= 0 || gas < 0 || tolls < 0 || other < 0) return null;
  final legs = roundTrip ? 2 : 1;
  final people = math.max(1, travelers.round());
  final totalMiles = miles * legs;
  final gallons = totalMiles / mpg;
  final fuel = gallons * gas;
  final tollsTotal = tolls * legs;
  final total = fuel + tollsTotal + other;
  return RoadTripResult(totalMiles, gallons, fuel, tollsTotal, other, total, people,
      total / people, total / totalMiles);
}

/* 5. Tire size */
class Tire {
  final double width, aspect, rim;
  const Tire(this.width, this.aspect, this.rim);
}

class TireDims {
  final double sidewall, diameter, diameterIn, circumference, revsPerMile;
  TireDims(this.sidewall, this.diameter, this.diameterIn, this.circumference, this.revsPerMile);
}

TireDims tireDims(Tire t) {
  final sidewall = t.width * t.aspect / 100;
  final diameter = t.rim * 25.4 + 2 * sidewall;
  final circ = math.pi * diameter;
  return TireDims(sidewall, diameter, diameter / 25.4, circ, 1609344 / circ);
}

class TireCompare {
  final TireDims old, next;
  final double diffMm, diffPct, actualSpeed, widthDiff, sidewallDiff;
  TireCompare(this.old, this.next, this.diffMm, this.diffPct, this.actualSpeed,
      this.widthDiff, this.sidewallDiff);
}

TireCompare? tireCompare(Tire a, Tire b, double indicatedSpeed) {
  final all = [a.width, a.aspect, a.rim, b.width, b.aspect, b.rim, indicatedSpeed];
  if (!_finite(all) || all.any((x) => x <= 0)) return null;
  final A = tireDims(a);
  final B = tireDims(b);
  final ratio = B.diameter / A.diameter;
  return TireCompare(A, B, B.diameter - A.diameter, (ratio - 1) * 100,
      indicatedSpeed * ratio, b.width - a.width, B.sidewall - A.sidewall);
}

/// Reads "225/45R17", "225/45 ZR17", "225/45-17" and similar.
Tire? parseTireSize(String text) {
  final m = RegExp(r'^(\d{3})\s*/\s*(\d{2})\s*[A-Za-z-]*\s*(\d{2})$').firstMatch(text.trim());
  if (m == null) return null;
  return Tire(double.parse(m.group(1)!), double.parse(m.group(2)!), double.parse(m.group(3)!));
}

/* 6. Depreciation */
class DepPoint {
  final double year, value;
  DepPoint(this.year, this.value);
}

class DepResult {
  final double current, future, lostSoFar, lostByThen, lostByThenPct;
  final List<DepPoint> points;
  final int currentIndex;
  DepResult(this.current, this.future, this.lostSoFar, this.lostByThen, this.lostByThenPct,
      this.points, this.currentIndex);
}

DepResult? depreciation(double price, double age, double ratePct, double yearsAhead) {
  if (!_finite([price, age, ratePct, yearsAhead])) return null;
  if (price <= 0 || age < 0 || ratePct < 0 || ratePct >= 100 || yearsAhead < 0) return null;
  final keep = 1 - ratePct / 100;
  final double current = (price * math.pow(keep, age)).toDouble();
  final double future = (current * math.pow(keep, yearsAhead)).toDouble();
  final total = age + yearsAhead;
  final steps = math.max(1, math.min(40, total.round()));
  final points = List.generate(steps + 1, (i) {
    final year = total * i / steps;
    return DepPoint(year, price * math.pow(keep, year).toDouble());
  });
  final currentIndex = total > 0 ? (age / total * steps).round() : 0;
  return DepResult(current, future, price - current, price - future,
      (price - future) / price * 100, points, currentIndex);
}

/* 7. Wheel offset */
class Wheel {
  final double widthIn, offsetMm;
  const Wheel(this.widthIn, this.offsetMm);
}

class Edges {
  final double inner, outer;
  Edges(this.inner, this.outer);
}

Edges _wheelEdges(Wheel w) {
  final half = w.widthIn * 25.4 / 2;
  return Edges(half + w.offsetMm, half - w.offsetMm);
}

class WheelResult {
  final Edges old, next;
  final double innerShift, outerShift, widthChangeIn;
  WheelResult(this.old, this.next, this.innerShift, this.outerShift, this.widthChangeIn);
}

WheelResult? wheelOffset(Wheel a, Wheel b) {
  if (!_finite([a.widthIn, a.offsetMm, b.widthIn, b.offsetMm])) return null;
  if (a.widthIn <= 0 || b.widthIn <= 0) return null;
  final A = _wheelEdges(a);
  final B = _wheelEdges(b);
  return WheelResult(A, B, B.inner - A.inner, B.outer - A.outer, b.widthIn - a.widthIn);
}

/* 8. Horsepower converter */
enum PowerUnit { hp, kw, ps }

const _kwPer = {PowerUnit.hp: 0.745699872, PowerUnit.kw: 1.0, PowerUnit.ps: 0.73549875};

Map<PowerUnit, double>? convertPower(double value, PowerUnit from) {
  if (!value.isFinite || value < 0) return null;
  final kw = value * _kwPer[from]!;
  return {
    PowerUnit.hp: kw / _kwPer[PowerUnit.hp]!,
    PowerUnit.kw: kw,
    PowerUnit.ps: kw / _kwPer[PowerUnit.ps]!,
  };
}

/* 9. Cost per mile */
class CostPerMileResult {
  final double total, perMile, yearly, monthly, fuel, insurance, maintenance, other;
  CostPerMileResult(this.total, this.perMile, this.yearly, this.monthly, this.fuel,
      this.insurance, this.maintenance, this.other);
}

CostPerMileResult? costPerMile({
  required double miles,
  required double fuel,
  required double insurance,
  required double maintenance,
  required double other,
  required bool perMonth,
}) {
  if (!_finite([miles, fuel, insurance, maintenance, other])) return null;
  if (miles <= 0 || fuel < 0 || insurance < 0 || maintenance < 0 || other < 0) return null;
  final total = fuel + insurance + maintenance + other;
  final toYear = perMonth ? 12 : 1;
  return CostPerMileResult(total, total / miles, total * toYear, total * toYear / 12,
      fuel / miles, insurance / miles, maintenance / miles, other / miles);
}

/* 10. Auto loan */
class LoanResult {
  final double tax, financed, monthly, totalPaid, interest;
  final int months;
  LoanResult(this.tax, this.financed, this.monthly, this.totalPaid, this.interest, this.months);
}

LoanResult? autoLoan({
  required double price,
  required double down,
  required double trade,
  required double taxPct,
  required double apr,
  required double months,
}) {
  if (!_finite([price, down, trade, taxPct, apr, months])) return null;
  if (price <= 0 || down < 0 || trade < 0 || taxPct < 0 || apr < 0 || months < 1) return null;
  final n = months.round();
  final tax = price * taxPct / 100;
  final financed = math.max(0.0, price + tax - down - trade);
  final r = apr / 1200;
  final double monthly = financed == 0
      ? 0.0
      : r == 0
          ? financed / n
          : (financed * r) / (1 - math.pow(1 + r, -n).toDouble());
  final totalPaid = monthly * n;
  return LoanResult(tax, financed, monthly, totalPaid, totalPaid - financed, n);
}
