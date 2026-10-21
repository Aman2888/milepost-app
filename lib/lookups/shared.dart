import 'package:flutter/material.dart';
import '../core/nhtsa.dart';
import '../core/theme.dart';
import '../widgets/ui.dart';

/// Runs one lookup at a time and drops stale answers.
mixin LookupMixin<W extends StatefulWidget, T> on State<W> {
  bool busy = false;
  T? data;
  String? error;
  int _seq = 0;

  Future<void> run(Future<T> Function() job) async {
    final mine = ++_seq;
    setState(() {
      busy = true;
      error = null;
      data = null;
    });
    try {
      final d = await job();
      if (!mounted || mine != _seq) return;
      setState(() {
        data = d;
        busy = false;
      });
    } on NhtsaException catch (e) {
      if (!mounted || mine != _seq) return;
      setState(() {
        busy = false;
        error = e.message;
      });
    } catch (_) {
      if (!mounted || mine != _seq) return;
      setState(() {
        busy = false;
        error = 'Something went wrong. Please try again.';
      });
    }
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PrimaryButton(this.label, {super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: C.ink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final String tone; // blue | red | yellow | green | ink | plain
  const Pill(this.text, {super.key, this.tone = 'plain'});

  @override
  Widget build(BuildContext context) {
    final bg = tone == 'plain' ? C.paperDeep : C.tone(tone);
    final fg = tone == 'plain' ? C.ink : C.onTone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class Notice extends StatelessWidget {
  final String? title;
  final bool warn;
  final Widget child;
  const Notice({super.key, this.title, this.warn = false, required this.child});

  @override
  Widget build(BuildContext context) {
    final accent = warn ? C.hwy : C.sign;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(title!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          DefaultTextStyle.merge(style: const TextStyle(fontSize: 14, height: 1.4), child: child),
        ],
      ),
    );
  }
}

class Stars extends StatelessWidget {
  final int? value;
  const Stars(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return const Text('Not rated', style: TextStyle(fontSize: 13, color: C.inkSoft));
    }
    return Semantics(
      label: '$value out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(i <= value! ? Icons.star : Icons.star_border,
                size: 22, color: i <= value! ? C.hwy : C.ink.withOpacity(0.3)),
        ],
      ),
    );
  }
}

class LabelValue extends StatelessWidget {
  final String label, value;
  const LabelValue(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: C.inkSoft))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class SourceNote extends StatelessWidget {
  const SourceNote({super.key});
  @override
  Widget build(BuildContext context) =>
      const Text('Source: NHTSA', style: TextStyle(fontSize: 12, color: C.inkSoft));
}

/// The sign shown while loading / on error / before the first search.
Sign statusSign({
  required String label,
  required bool busy,
  required String? error,
  required String idle,
  required String busyText,
}) {
  if (error != null) return Sign(tone: 'yellow', label: label, value: null, empty: error);
  if (busy) return Sign(label: label, value: null, empty: busyText);
  return Sign(label: label, value: null, empty: idle);
}

/* ------------------------------------------------------------------ */
/* Year / make / model picker                                          */
/* ------------------------------------------------------------------ */

class Vehicle {
  final String year, make, model;
  const Vehicle(this.year, this.make, this.model);
}

class _Select extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final String Function(String)? display;
  final bool enabled;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _Select({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.display,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : null,
              hint: Text(hint),
              onChanged: enabled ? onChanged : null,
              items: [
                for (final i in items)
                  DropdownMenuItem(value: i, child: Text(display?.call(i) ?? i, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dropdowns fill in one after the other from NHTSA's own lists, so only
/// vehicles that really have data can be picked.
class VehiclePicker extends StatefulWidget {
  final VehicleKind kind;
  final bool busy;
  final ValueChanged<Vehicle> onSubmit;
  final String button;

  const VehiclePicker({
    super.key,
    required this.kind,
    required this.busy,
    required this.onSubmit,
    this.button = 'Look up',
  });

  @override
  State<VehiclePicker> createState() => _VehiclePickerState();
}

class _VehiclePickerState extends State<VehiclePicker> {
  static const _firstYear = 1990;
  late final List<String> years = () {
    final top = DateTime.now().year + 1;
    return [for (var y = top; y >= _firstYear; y--) '$y'];
  }();

  String? year, make, model;
  List<String> makes = [], models = [];
  String? loading; // 'makes' | 'models'
  String problem = '';
  int _makesSeq = 0, _modelsSeq = 0;

  Future<void> _loadMakes(String y) async {
    final mine = ++_makesSeq;
    setState(() {
      problem = '';
      loading = 'makes';
    });
    var items = <String>[];
    try {
      items = await Nhtsa.instance.names(widget.kind, y);
    } on NhtsaException catch (e) {
      if (mine == _makesSeq && mounted) problem = e.message;
    }
    if (!mounted || mine != _makesSeq) return;
    setState(() {
      makes = items;
      loading = null;
      if (items.isEmpty && problem.isEmpty) problem = 'NHTSA has no $y vehicles for this lookup.';
    });
  }

  Future<void> _loadModels(String y, String mk) async {
    final mine = ++_modelsSeq;
    setState(() {
      problem = '';
      loading = 'models';
    });
    var items = <String>[];
    try {
      items = await Nhtsa.instance.names(widget.kind, y, make: mk);
    } on NhtsaException catch (e) {
      if (mine == _modelsSeq && mounted) problem = e.message;
    }
    if (!mounted || mine != _modelsSeq) return;
    setState(() {
      models = items;
      loading = null;
    });
  }

  void _pickYear(String? y) {
    _modelsSeq++;
    setState(() {
      year = y;
      make = null;
      model = null;
      makes = [];
      models = [];
      problem = '';
    });
    if (y != null) _loadMakes(y);
  }

  void _pickMake(String? m) {
    setState(() {
      make = m;
      model = null;
      models = [];
      problem = '';
    });
    if (m != null && year != null) _loadModels(year!, m);
  }

  @override
  Widget build(BuildContext context) {
    final ready = year != null && make != null && model != null && !widget.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Select(label: 'Model year', value: year, items: years, hint: 'Pick a year', onChanged: _pickYear),
        const SizedBox(height: 14),
        _Select(
          label: 'Make',
          value: make,
          items: makes,
          display: prettyName,
          enabled: year != null && loading != 'makes',
          hint: loading == 'makes' ? 'Loading makes…' : 'Pick a make',
          onChanged: _pickMake,
        ),
        const SizedBox(height: 14),
        _Select(
          label: 'Model',
          value: model,
          items: models,
          display: prettyName,
          enabled: make != null && loading != 'models',
          hint: loading == 'models' ? 'Loading models…' : 'Pick a model',
          onChanged: (m) => setState(() => model = m),
        ),
        if (problem.isNotEmpty) ...[
          const SizedBox(height: 12),
          Notice(warn: true, child: Text(problem)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            PrimaryButton(widget.busy ? 'Looking up…' : widget.button,
                onPressed: ready ? () => widget.onSubmit(Vehicle(year!, make!, model!)) : null),
            if (widget.busy || loading != null) ...[
              const SizedBox(width: 14),
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
          ],
        ),
      ],
    );
  }
}

String vehicleLabel(Vehicle? v) =>
    v == null ? '' : '${v.year} ${prettyName(v.make)} ${prettyName(v.model)}';

/// "Show more" button used by the long lists.
class ShowMore extends StatelessWidget {
  final int left;
  final VoidCallback onTap;
  const ShowMore({super.key, required this.left, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: C.ink,
          side: const BorderSide(color: C.ink, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
        child: Text('Show more ($left left)', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
