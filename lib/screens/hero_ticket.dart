import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/fonts.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/tools_data.dart';
import '../widgets/odometer.dart';
import 'tool_screen.dart';

/// A live mini fuel calculator. The cost rolls on odometer reels as you drag.
class HeroTicket extends StatefulWidget {
  const HeroTicket({super.key});
  @override
  State<HeroTicket> createState() => _HeroTicketState();
}

class _HeroTicketState extends State<HeroTicket> {
  double distance = 320;
  double mpg = 28;
  final price = TextEditingController(text: '3.45');

  @override
  void dispose() {
    price.dispose();
    super.dispose();
  }

  Widget _slider(String label, String value, double v, double min, double max,
      int div, ValueChanged<double> on) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
        Slider(value: v, min: min, max: max, divisions: div, onChanged: on),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = parse(price.text);
    final valid = p.isFinite && p >= 0;
    final cost = valid ? distance / mpg * p : 0.0;
    final fuelTool = tools.firstWhere((t) => t.slug == 'fuel-cost-calculator');

    return Container(
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color.fromARGB(255, 2, 13, 23),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trip ticket', style: disp(18, color: Colors.white)),
                const Text('Fuel only',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This drive will cost about',
                    style: TextStyle(color: C.inkSoft, fontSize: 14)),
                const SizedBox(height: 8),
                Odometer(value: cost, size: 46),
              ],
            ),
          ),
          // perforated ticket divider with the two notches
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: CustomPaint(
                      painter: _DashedLine(),
                      size: const Size(double.infinity, 2)),
                ),
                Positioned(left: -12, child: _notch()),
                Positioned(right: -12, child: _notch()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _slider('Distance', '${numFmt(distance, 0)} miles', distance,
                    10, 1500, 149, (v) => setState(() => distance = v)),
                _slider('Fuel economy', '${mpg.round()} MPG', mpg, 10, 60, 50,
                    (v) => setState(() => mpg = v)),
                const SizedBox(height: 4),
                const SizedBox(height: 4),
                TextField(
                  controller: price,
                  onChanged: (_) => setState(() {}),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                  ],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Price per gallon',
                    prefixText: '\$ ',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: C.ink.withOpacity(0.15)))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              children: [
                Text(
                  valid
                      ? '${money(p / mpg, 3)} per mile, ${numFmt(distance / mpg, 1)} gal'
                      : 'Enter a price',
                  style: const TextStyle(color: C.inkSoft, fontSize: 14),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF3B32A),
                    foregroundColor: const Color.fromARGB(255, 29, 29, 29),
                  ),
                  onPressed: () => openTool(context, fuelTool),
                  child: const Text('Open full calculator'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notch() => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: C.paper,
          shape: BoxShape.circle,
        ),
      );
}

class _DashedLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = C.ink.withOpacity(0.3)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 1), Offset(x + 5, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
