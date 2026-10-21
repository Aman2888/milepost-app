import 'package:flutter/widgets.dart';
import '../calculators/calculators_a.dart';
import '../calculators/calculators_b.dart';
import '../lookups/lookup_screens.dart';

/// slug -> screen body. Same slugs as the website routes.
final Map<String, Widget Function()> toolBuilders = {
  'fuel-cost-calculator': () => const FuelCostCalc(),
  'mpg-calculator': () => const MpgCalc(),
  'ev-charging-cost-calculator': () => const EvChargingCalc(),
  'road-trip-cost-calculator': () => const RoadTripCalc(),
  'tire-size-calculator': () => const TireSizeCalc(),
  'car-depreciation-calculator': () => const DepreciationCalc(),
  'wheel-offset-calculator': () => const WheelOffsetCalc(),
  'horsepower-converter': () => const HorsepowerCalc(),
  'cost-per-mile-calculator': () => const CostPerMileCalc(),
  'auto-loan-calculator': () => const AutoLoanCalc(),
  'vin-decoder': () => const VinDecoderScreen(),
  'recall-checker': () => const RecallCheckerScreen(),
  'vehicle-safety-ratings': () => const SafetyRatingsScreen(),
  'common-problems-lookup': () => const ComplaintsScreen(),
};
