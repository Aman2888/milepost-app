import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/fonts.dart';
import '../core/format.dart';
import '../core/theme.dart';

/* ------------------------------------------------------------------ */
/* State helper: keeps raw text (so a field can be cleared) + parsed n  */
/* ------------------------------------------------------------------ */

mixin NumsMixin<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _controllers = [];

  /// Creates a controller that rebuilds this State on every edit.
  TextEditingController nc(String initial) {
    final c = TextEditingController(text: initial)..addListener(_changed);
    _controllers.add(c);
    return c;
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}

extension NumValue on TextEditingController {
  double get n => parse(text);
}

/* ------------------------------------------------------------------ */
/* Inputs                                                              */
/* ------------------------------------------------------------------ */

class NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? unit, prefix, hint, placeholder;
  final bool numeric;

  const NumField({
    super.key,
    required this.label,
    required this.controller,
    this.unit,
    this.prefix,
    this.hint,
    this.placeholder,
    this.numeric = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      inputFormatters: numeric ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]'))] : null,
      autocorrect: false,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()]),
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        helperText: hint,
        helperMaxLines: 3,
        prefixText: prefix,
        prefixStyle: const TextStyle(fontSize: 18, color: C.inkSoft),
        suffixText: unit,
        suffixStyle: const TextStyle(fontSize: 14, color: C.inkSoft),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

/// Fields side by side.
class FieldRow extends StatelessWidget {
  final List<Widget> children;
  const FieldRow(this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class Segmented<T> extends StatelessWidget {
  final String label;
  final T value;
  final ValueChanged<T> onChanged;
  final List<(T, String)> options;

  const Segmented({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: C.inkSoft)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(o.$2),
                selected: o.$1 == value,
                showCheckmark: false,
                onSelected: (_) => onChanged(o.$1),
              ),
          ],
        ),
      ],
    );
  }
}

/// Tap-to-fill suggestions under a field.
class Chips extends StatelessWidget {
  final String label;
  final List<(String, String)> options; // (label, value)
  final ValueChanged<String> onPick;

  const Chips({super.key, required this.label, required this.options, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: C.inkSoft)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              ActionChip(
                label: Text(o.$1),
                onPressed: () => onPick(o.$2),
              ),
          ],
        ),
      ],
    );
  }
}

/* ------------------------------------------------------------------ */
/* Result panel (the "highway sign")                                   */
/* ------------------------------------------------------------------ */

class SignRow {
  final String label, value;
  const SignRow(this.label, this.value);
}

class _SignStyle {
  final Color box, shadow, text, sub, border, line;
  const _SignStyle(this.box, this.shadow, this.text, this.sub, this.border, this.line);
}

// The website only has three sign tones: blue (default), yellow (warning), green (all fine).
_SignStyle _signStyle(String tone) {
  switch (tone) {
    case 'yellow':
      return _SignStyle(C.hwy, const Color(0xFFB98614), C.ink, C.ink.withOpacity(0.75), C.ink, C.ink.withOpacity(0.25));
    case 'green':
      return _SignStyle(const Color(0xFF1F7A4D), const Color(0xFF145636), Colors.white, Colors.white.withOpacity(0.8),
          Colors.white, Colors.white.withOpacity(0.25));
    default:
      return _SignStyle(C.sign, C.signDeep, Colors.white, Colors.white.withOpacity(0.8), Colors.white,
          Colors.white.withOpacity(0.25));
  }
}

/// The result card: a flat, tonal Material card. Yellow warns, green means all fine.
class Sign extends StatelessWidget {
  final String label;
  final String? value; // null => show [empty]
  final String? unit;
  final List<SignRow> rows;
  final String tone;
  final String empty;
  final Widget? extra;
  final bool compact;

  const Sign({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.rows = const [],
    this.tone = 'blue',
    this.empty = 'Enter valid numbers to see your result.',
    this.extra,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = _signStyle(tone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: s.box,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: s.sub)),
                const SizedBox(height: 6),
                if (value == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(empty, style: disp(22, weight: FontWeight.w600, color: s.text, height: 1.25)),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(value!, style: disp(compact ? 32 : 48, weight: FontWeight.w800, color: s.text, height: 1.05, spacing: -0.5)),
                        ),
                      ),
                      if (unit != null) ...[
                        const SizedBox(width: 8),
                        Text(unit!, style: disp(19, weight: FontWeight.w600, color: s.sub)),
                      ],
                    ],
                  ),
                  if (rows.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    for (final r in rows)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: s.line))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(r.label, style: TextStyle(fontSize: 14.5, color: s.sub))),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(r.value,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: s.text)),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (extra != null) extra!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignNote extends StatelessWidget {
  final String text;
  final String tone;
  const SignNote(this.text, {super.key, this.tone = 'blue'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: _signStyle(tone).sub)),
    );
  }
}

/// Red-to-green scale with a marker. Used for MPG.
class Meter extends StatelessWidget {
  final double value, min, max;
  final String minLabel, maxLabel;
  const Meter({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.minLabel,
    required this.maxLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        children: [
          LayoutBuilder(builder: (context, c) {
            return SizedBox(
              height: 26,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(colors: [Color(0xFFCC4437), Color(0xFFF3B32A), Color(0xFF5E9A5B)]),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    left: pct * c.maxWidth - 3,
                    child: Container(
                      width: 6,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: C.ink, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              Text(maxLabel, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

/// One bar split into labelled parts, with a legend underneath. Lives inside a sign.
class StackBar extends StatelessWidget {
  final List<(String, double, String)> parts; // (label, value, display)
  const StackBar(this.parts, {super.key});

  static const _colors = [Color(0xFFF3B32A), Colors.white, Color(0xFF8CC4FF), Color(0xFF7FD18B)];

  @override
  Widget build(BuildContext context) {
    final total = parts.fold<double>(0, (s, p) => s + (p.$2 > 0 ? p.$2 : 0));
    if (total <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 14,
              color: Colors.white.withOpacity(0.2),
              child: Row(
                children: [
                  for (var i = 0; i < parts.length; i++)
                    if (parts[i].$2 > 0)
                      Expanded(
                        flex: (parts[i].$2 / total * 1000).round().clamp(1, 1000),
                        child: Container(color: _colors[i % _colors.length]),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < parts.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: _colors[i % _colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(parts[i].$1, style: const TextStyle(fontSize: 14, color: Colors.white))),
                Text(parts[i].$3, style: const TextStyle(fontSize: 14, color: Colors.white)),
              ]),
            ),
        ],
      ),
    );
  }
}

/// Result on top, inputs below in a card: the answer stays visible while typing.
class CalcLayout extends StatelessWidget {
  final Widget sign;
  final List<Widget> children;
  const CalcLayout({super.key, required this.sign, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sign,
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 18),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Card with an optional title, used for grouped inputs and lookup results.
class Panel extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color? color;
  const Panel({super.key, this.title, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? C.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: disp(20, weight: FontWeight.w600)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

IconData glyphIcon(String g) {
  switch (g) {
    case 'pump':
      return Icons.local_gas_station;
    case 'gauge':
      return Icons.speed;
    case 'plug':
      return Icons.ev_station;
    case 'route':
      return Icons.alt_route;
    case 'tire':
      return Icons.tire_repair;
    case 'trend':
      return Icons.trending_down;
    case 'offset':
      return Icons.compare_arrows;
    case 'bolt':
      return Icons.bolt;
    case 'coin':
      return Icons.attach_money;
    case 'key':
      return Icons.key;
    case 'scan':
      return Icons.qr_code_scanner;
    case 'alert':
      return Icons.warning_amber;
    case 'star':
      return Icons.star;
    case 'chat':
      return Icons.forum;
    default:
      return Icons.directions_car;
  }
}
