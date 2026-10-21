import 'package:flutter/material.dart';
import '../core/fonts.dart';
import '../core/theme.dart';

/// One wheel of the odometer: digits sit in a column that slides into place.
class _Reel extends StatelessWidget {
  final int digit;
  final double size;
  const _Reel({super.key, required this.digit, required this.size});

  @override
  Widget build(BuildContext context) {
    final h = size * 1.1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.14),
      child: Container(
        height: h,
        width: size * 0.66,
        color: C.ink,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: digit.toDouble()),
          duration: const Duration(milliseconds: 750),
          curve: const Cubic(0.2, 0.8, 0.2, 1),
          builder: (context, v, _) => OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: h * 10,
            child: Transform.translate(
              offset: Offset(0, -v * h),
              child: Column(
                children: [
                  for (var d = 0; d < 10; d++)
                    SizedBox(
                      height: h,
                      child: Center(
                        child: Text('$d', style: disp(size, color: C.card, height: 1.0)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A money value shown on rolling odometer reels. Reels are keyed from the
/// right, so the cents wheel stays the cents wheel when the number grows.
class Odometer extends StatelessWidget {
  final double value;
  final int decimals;
  final String prefix;
  final double size;
  const Odometer({super.key, required this.value, this.decimals = 2, this.prefix = '\$', this.size = 46});

  @override
  Widget build(BuildContext context) {
    final safe = value.isFinite && value >= 0 ? value : 0.0;
    final parts = safe.toStringAsFixed(decimals).split('.');
    final whole = parts[0];
    final frac = parts.length > 1 ? parts[1] : '';

    final wholeChars = whole.split('').reversed.toList();
    final wholeReels = <Widget>[];
    for (var i = 0; i < wholeChars.length; i++) {
      wholeReels.add(Row(
        key: ValueKey('w$i'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Reel(digit: int.parse(wholeChars[i]), size: size),
          if (i > 0 && i % 3 == 0)
            Padding(
              padding: EdgeInsets.only(left: size * 0.03, bottom: size * 0.05),
              child: Text(',', style: disp(size, color: C.ink, height: 1.0)),
            ),
        ],
      ));
    }
    // built right to left (so keys follow place value), shown left to right
    final shownWhole = wholeReels.reversed.toList();

    return Semantics(
      label: '$prefix${safe.toStringAsFixed(decimals)}',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(prefix, style: disp(size, color: C.ink, height: 1.0)),
            SizedBox(width: size * 0.08),
            for (var i = 0; i < shownWhole.length; i++) ...[
              shownWhole[i],
              SizedBox(width: size * 0.06),
            ],
            if (decimals > 0) ...[
              Padding(
                padding: EdgeInsets.only(bottom: size * 0.05),
                child: Text('.', style: disp(size, color: C.ink, height: 1.0)),
              ),
              for (var i = 0; i < frac.length; i++) ...[
                SizedBox(width: size * 0.06),
                _Reel(key: ValueKey('f$i'), digit: int.parse(frac[i]), size: size),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
