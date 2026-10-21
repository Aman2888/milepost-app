import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/format.dart';
import '../core/nhtsa.dart';
import '../core/theme.dart';
import '../widgets/ui.dart';
import 'shared.dart';

/* ================================================================== */
/* VIN decoder                                                         */
/* ================================================================== */

typedef _Row = (String key, String label, String Function(String)? fmt);

String _litres(String v) => double.tryParse(v) != null ? '${double.parse(v).toStringAsFixed(1)} L' : v;

final List<(String, List<_Row>)> _vinGroups = [
  ('Vehicle', [
    ('ModelYear', 'Model year', null),
    ('Make', 'Make', prettyName),
    ('Model', 'Model', null),
    ('Trim', 'Trim', null),
    ('Series', 'Series', null),
    ('VehicleType', 'Vehicle type', prettyName),
    ('BodyClass', 'Body type', null),
    ('Doors', 'Doors', null),
    ('Seats', 'Seats', null),
    ('GVWR', 'Gross weight class', null),
  ]),
  ('Engine and fuel', [
    ('DisplacementL', 'Engine size', _litres),
    ('EngineCylinders', 'Cylinders', null),
    ('EngineConfiguration', 'Layout', null),
    ('EngineHP', 'Power', (v) => '$v hp'),
    ('EngineModel', 'Engine model', null),
    ('Turbo', 'Turbo', null),
    ('FuelTypePrimary', 'Fuel', null),
    ('FuelTypeSecondary', 'Second fuel', null),
    ('ElectrificationLevel', 'Electrification', null),
  ]),
  ('Drivetrain', [
    ('DriveType', 'Drive', null),
    ('TransmissionStyle', 'Transmission', null),
    ('TransmissionSpeeds', 'Gears', null),
  ]),
  ('Safety equipment', [
    ('ABS', 'Anti-lock brakes', null),
    ('ESC', 'Stability control', null),
    ('TractionControl', 'Traction control', null),
    ('TPMS', 'Tire pressure monitor', null),
    ('AirBagLocFront', 'Front airbags', null),
    ('AirBagLocSide', 'Side airbags', null),
    ('AirBagLocCurtain', 'Curtain airbags', null),
    ('AirBagLocKnee', 'Knee airbags', null),
    ('ForwardCollisionWarning', 'Forward collision warning', null),
    ('LaneDepartureWarning', 'Lane departure warning', null),
    ('BlindSpotMon', 'Blind spot monitor', null),
    ('AdaptiveCruiseControl', 'Adaptive cruise control', null),
    ('RearVisibilitySystem', 'Rear camera', null),
  ]),
  ('Built by', [
    ('Manufacturer', 'Manufacturer', null),
    ('PlantCompanyName', 'Plant', null),
    ('PlantCity', 'City', prettyName),
    ('PlantState', 'State', prettyName),
    ('PlantCountry', 'Country', prettyName),
  ]),
];

class VinDecoderScreen extends StatefulWidget {
  const VinDecoderScreen({super.key});
  @override
  State<VinDecoderScreen> createState() => _VinState();
}

class _VinState extends State<VinDecoderScreen> with LookupMixin<VinDecoderScreen, VinResult> {
  static final _ok = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
  static const _example = '1HGCM82633A004352';
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  bool get valid => _ok.hasMatch(ctrl.text);

  void _submit() {
    if (!valid) return;
    FocusScope.of(context).unfocus();
    run(() => Nhtsa.instance.decodeVin(ctrl.text));
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    final f = d?.fields ?? const <String, String>{};
    final decoded = d != null && (f['Make'] ?? '').isNotEmpty && ((f['Model'] ?? '').isNotEmpty || (f['ModelYear'] ?? '').isNotEmpty);

    Widget sign;
    if (error != null || busy || d == null) {
      sign = statusSign(
          label: 'VIN decoder',
          busy: busy,
          error: error,
          idle: 'Enter a 17-character VIN to see what it says.',
          busyText: 'Asking NHTSA…');
    } else if (!decoded) {
      sign = const Sign(
          tone: 'yellow', label: 'VIN decoder', value: null, empty: 'NHTSA could not match this VIN to a vehicle.');
    } else {
      final title = [f['ModelYear'], prettyName(f['Make']!), f['Model']]
          .where((e) => e != null && e.isNotEmpty)
          .join(' ');
      final engine = [
        if ((f['DisplacementL'] ?? '').isNotEmpty) _litres(f['DisplacementL']!),
        if ((f['EngineCylinders'] ?? '').isNotEmpty) '${f['EngineCylinders']}-cyl',
        if ((f['EngineHP'] ?? '').isNotEmpty) '${f['EngineHP']} hp',
      ].join(' · ');
      sign = Sign(
        label: 'This VIN is a',
        value: title,
        compact: true,
        rows: [
          if ((f['BodyClass'] ?? '').isNotEmpty) SignRow('Body type', f['BodyClass']!),
          if (engine.isNotEmpty) SignRow('Engine', engine),
          if ((f['FuelTypePrimary'] ?? '').isNotEmpty) SignRow('Fuel', f['FuelTypePrimary']!),
          if ((f['DriveType'] ?? '').isNotEmpty) SignRow('Drive', f['DriveType']!),
        ],
        extra: SignNote('${(f['Trim'] ?? '').isNotEmpty ? 'Trim: ${f['Trim']}. ' : ''}Decoded from NHTSA’s vPIC database.'),
      );
    }

    final notes = (d?.errorText ?? '').split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final hasProblem = d != null && d.errorCode.split(',').any((c) => c.trim().isNotEmpty && c.trim() != '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalcLayout(sign: sign, children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vehicle identification number (VIN)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: ctrl,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(17),
                  TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 1.2),
                decoration: InputDecoration(
                  hintText: '17 letters and numbers',
                  suffixText: '${ctrl.text.length}/17',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Find it on the dashboard by the windshield, on the driver’s door jamb sticker, or on your registration and insurance card.',
                  style: TextStyle(fontSize: 12, color: C.inkSoft),
                ),
              ),
            ],
          ),
          if (ctrl.text.length == 17 && !valid)
            const Notice(
              warn: true,
              child: Text('VINs never contain the letters I, O or Q. Check for a 1 or 0 that was typed as a letter.'),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(busy ? 'Decoding…' : 'Decode VIN', onPressed: (!valid || busy) ? null : _submit),
          ),
          Chips(
            label: 'Just want to see how it works?',
            options: const [('Try an example: $_example', _example)],
            onPick: (v) {
              ctrl.text = v;
              _submit();
            },
          ),
        ]),
        if (d != null && hasProblem && notes.isNotEmpty) ...[
          Notice(
            warn: !decoded,
            title: 'Notes from NHTSA about this VIN',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final n in notes) Text('•  $n')],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (decoded)
          for (final g in _vinGroups)
            if (g.$2.any((r) => (f[r.$1] ?? '').isNotEmpty)) ...[
              Panel(
                title: g.$1,
                child: Column(children: [
                  for (final r in g.$2)
                    if ((f[r.$1] ?? '').isNotEmpty) LabelValue(r.$2, r.$3 != null ? r.$3!(f[r.$1]!) : f[r.$1]!),
                ]),
              ),
              const SizedBox(height: 14),
            ],
      ],
    );
  }
}

/* ================================================================== */
/* Recall checker                                                      */
/* ================================================================== */

class RecallCheckerScreen extends StatefulWidget {
  const RecallCheckerScreen({super.key});
  @override
  State<RecallCheckerScreen> createState() => _RecallState();
}

class _RecallState extends State<RecallCheckerScreen> with LookupMixin<RecallCheckerScreen, List<Recall>> {
  static const _page = 8;
  Vehicle? vehicle;
  int shown = _page;

  void _search(Vehicle v) {
    vehicle = v;
    shown = _page;
    run(() => Nhtsa.instance.recalls(v.year, v.make, v.model));
  }

  (String, String) _split(String raw) {
    final parts = raw.split(':').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    if (parts.isEmpty) return ('Recall', '');
    return (prettyComponent(parts.first), parts.skip(1).map(prettyComponent).join(' › '));
  }

  Widget _card(Recall r) {
    final part = _split(r.component);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.ink.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(part.$1, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          if (part.$2.isNotEmpty) Text(part.$2, style: const TextStyle(fontSize: 13, color: C.inkSoft)),
          const SizedBox(height: 4),
          Text(
            [if (r.date != null) formatDate(r.date), if (r.campaign.isNotEmpty) 'Campaign ${r.campaign}'].join(' · '),
            style: const TextStyle(fontSize: 13, color: C.inkSoft),
          ),
          if (r.parkIt || r.parkOutside || r.ota) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (r.parkIt) const Pill('Do not drive', tone: 'red'),
              if (r.parkOutside) const Pill('Park outside', tone: 'yellow'),
              if (r.ota) const Pill('Fixed by software update', tone: 'blue'),
            ]),
          ],
          if (r.summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.summary, style: const TextStyle(height: 1.4)),
          ],
          if (r.consequence.isNotEmpty || r.remedy.isNotEmpty || r.notes.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: const Text('What could happen and how it is fixed',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                children: [
                  if (r.consequence.isNotEmpty) _detail('What could happen', r.consequence),
                  if (r.remedy.isNotEmpty) _detail('The fix', r.remedy),
                  if (r.notes.isNotEmpty) _detail('Notes', r.notes),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detail(String t, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.4, color: C.inkSoft)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final items = data;
    final label = vehicleLabel(vehicle);
    Widget sign;
    if (items == null) {
      sign = statusSign(
          label: 'Recall checker',
          busy: busy,
          error: error,
          idle: 'Pick a year, make and model to see its safety recalls.',
          busyText: 'Checking NHTSA’s recall records…');
    } else {
      final count = items.length;
      final latest = items.where((i) => i.date != null).map((i) => i.date).firstOrNull;
      sign = Sign(
        tone: count > 0 ? 'yellow' : 'green',
        label: 'Recalls for the $label',
        value: '$count',
        unit: count == 1 ? 'recall' : 'recalls',
        rows: count > 0
            ? [
                SignRow('Do not drive warnings', '${items.where((i) => i.parkIt).length}'),
                SignRow('Park outside warnings', '${items.where((i) => i.parkOutside).length}'),
                SignRow('Fixed by software update', '${items.where((i) => i.ota).length}'),
                if (latest != null) SignRow('Most recent', formatDate(latest)),
              ]
            : const [],
        extra: SignNote(
          '${count == 0 ? 'NHTSA has no recalls on file for this model year. ' : 'These are the recalls issued for this model year. '}'
          'They do not say whether one particular car has already been repaired. To check a single car, enter its VIN at nhtsa.gov/recalls.',
          tone: count > 0 ? 'yellow' : 'green',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalcLayout(sign: sign, children: [
          VehiclePicker(kind: VehicleKind.recalls, busy: busy, onSubmit: _search, button: 'Check recalls'),
        ]),
        if (items != null && items.isNotEmpty) ...[
          Row(children: [
            Expanded(
              child: Text('${items.length} ${items.length == 1 ? 'recall' : 'recalls'}, newest first',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SourceNote(),
          ]),
          const SizedBox(height: 12),
          for (final r in items.take(shown)) _card(r),
          if (shown < items.length)
            Align(
              alignment: Alignment.centerLeft,
              child: ShowMore(left: items.length - shown, onTap: () => setState(() => shown += _page)),
            ),
        ],
      ],
    );
  }
}

/* ================================================================== */
/* Safety ratings                                                      */
/* ================================================================== */

String? _range(Iterable<int?> values) {
  final v = values.whereType<int>().toList();
  if (v.isEmpty) return null;
  v.sort();
  final lo = v.first, hi = v.last;
  return lo == hi ? '$lo ${lo == 1 ? 'star' : 'stars'}' : '$lo to $hi stars';
}

class SafetyRatingsScreen extends StatefulWidget {
  const SafetyRatingsScreen({super.key});
  @override
  State<SafetyRatingsScreen> createState() => _SafetyState();
}

class _SafetyState extends State<SafetyRatingsScreen> with LookupMixin<SafetyRatingsScreen, List<Rating>> {
  Vehicle? vehicle;

  void _search(Vehicle v) {
    vehicle = v;
    run(() => Nhtsa.instance.ratings(v.year, v.make, v.model));
  }

  Widget _starRow(String label, int? value, {String? sub}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (sub != null) Text(sub, style: const TextStyle(fontSize: 12, color: C.inkSoft)),
            ]),
          ),
          Stars(value),
        ]),
      );

  Widget _feature(String v) {
    final t = v.toLowerCase();
    if (t.contains('standard')) return const Pill('Standard', tone: 'blue');
    if (t.contains('optional')) return const Pill('Optional', tone: 'yellow');
    return Pill(v);
  }

  Widget _variant(Rating r) {
    final feats = [
      ('Electronic stability control', r.esc),
      ('Forward collision warning', r.fcw),
      ('Lane departure warning', r.ldw),
    ].where((f) => f.$2.isNotEmpty).toList();
    final sideDetail = (r.sideDriver != null || r.sidePassenger != null)
        ? 'Driver ${r.sideDriver ?? 'n/a'}, passenger ${r.sidePassenger ?? 'n/a'}'
        : null;
    final frontDetail = (r.frontDriver != null || r.frontPassenger != null)
        ? 'Driver ${r.frontDriver ?? 'n/a'}, passenger ${r.frontPassenger ?? 'n/a'}'
        : null;
    final onFile = [
      ('Recalls', r.recalls),
      ('Owner complaints', r.complaints),
      ('Investigations', r.investigations),
    ].where((x) => x.$2 != null).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Panel(
        title: prettyName(r.description).isEmpty ? 'Vehicle' : prettyName(r.description),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14)),
            child: _starRow('Overall', r.overall),
          ),
          const SizedBox(height: 8),
          _starRow('Frontal crash', r.front, sub: frontDetail),
          _starRow('Side crash', r.side, sub: sideDetail),
          if (r.pole != null) _starRow('Side pole crash', r.pole),
          _starRow('Rollover', r.rollover,
              sub: r.rolloverChance != null
                  ? 'About ${(r.rolloverChance! * 100).toStringAsFixed(1)}% chance of rolling over in a single-vehicle crash'
                  : null),
          if (feats.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Recommended safety technology', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            for (final f in feats)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [Expanded(child: Text(f.$1)), _feature(f.$2)]),
              ),
          ],
          if (onFile.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('On file with NHTSA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            for (final x in onFile) LabelValue(x.$1, numFmt(x.$2!.toDouble(), 0)),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = data;
    final label = vehicleLabel(vehicle);
    Widget sign;
    if (items == null) {
      sign = statusSign(
          label: 'Safety ratings',
          busy: busy,
          error: error,
          idle: 'Pick a year, make and model to see its crash-test stars.',
          busyText: 'Checking NHTSA’s crash-test results…');
    } else {
      final overall = _range(items.map((i) => i.overall));
      if (overall == null) {
        sign = Sign(
            tone: 'yellow',
            label: label.isEmpty ? 'Safety ratings' : label,
            value: null,
            empty: items.isEmpty
                ? 'NHTSA has no crash-test ratings for this vehicle.'
                : 'NHTSA has not given this vehicle an overall star rating.');
      } else {
        final best = items.map((i) => i.overall ?? 0).reduce((a, b) => a > b ? a : b);
        final tone = best >= 4 ? 'green' : 'yellow';
        sign = Sign(
          tone: tone,
          label: 'NHTSA overall rating, $label',
          value: overall,
          rows: [
            SignRow('Frontal crash', _range(items.map((i) => i.front)) ?? 'Not rated'),
            SignRow('Side crash', _range(items.map((i) => i.side)) ?? 'Not rated'),
            SignRow('Rollover', _range(items.map((i) => i.rollover)) ?? 'Not rated'),
          ],
          extra: SignNote(
              'Five stars is best. Compare cars of a similar size and weight, because the crash ratings are not meant to be compared across very different vehicles.',
              tone: tone),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalcLayout(sign: sign, children: [
          VehiclePicker(kind: VehicleKind.ratings, busy: busy, onSubmit: _search, button: 'Show ratings'),
        ]),
        if (items != null) ...[for (final r in items) _variant(r), const Align(alignment: Alignment.centerLeft, child: SourceNote())],
      ],
    );
  }
}

/* ================================================================== */
/* Common problems (owner complaints)                                  */
/* ================================================================== */

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsState();
}

class _ComplaintsState extends State<ComplaintsScreen> with LookupMixin<ComplaintsScreen, ComplaintResult> {
  static const _page = 10;
  Vehicle? vehicle;
  int shown = _page;

  void _search(Vehicle v) {
    vehicle = v;
    shown = _page;
    run(() => Nhtsa.instance.complaints(v.year, v.make, v.model));
  }

  Widget _card(Complaint c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.ink.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          c.components.isEmpty ? 'Complaint' : c.components.map(prettyComponent).join(' · '),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          [if (c.filed != null) 'Filed ${formatDate(c.filed)}', if (c.id.isNotEmpty) 'ODI ${c.id}'].join(' · '),
          style: const TextStyle(fontSize: 12, color: C.inkSoft),
        ),
        if (c.crash || c.fire || c.injuries > 0 || c.deaths > 0) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (c.crash) const Pill('Crash', tone: 'red'),
            if (c.fire) const Pill('Fire', tone: 'red'),
            if (c.injuries > 0) Pill('${c.injuries} injured', tone: 'yellow'),
            if (c.deaths > 0) Pill('${c.deaths} died', tone: 'red'),
          ]),
        ],
        if (c.summary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(c.summary, style: const TextStyle(height: 1.4)),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = data;
    final label = vehicleLabel(vehicle);
    Widget sign;
    if (done == null) {
      sign = statusSign(
          label: 'Common problems',
          busy: busy,
          error: error,
          idle: 'Pick a year, make and model to see what owners report.',
          busyText: 'Reading NHTSA’s complaint records…');
    } else {
      final top = done.components.isEmpty ? null : done.components.first;
      final tone = done.total == 0 ? 'green' : 'yellow';
      sign = Sign(
        tone: tone,
        label: 'Owner complaints, $label',
        value: numFmt(done.total.toDouble(), 0),
        unit: done.total == 1 ? 'complaint' : 'complaints',
        rows: done.total > 0
            ? [
                if (top != null) SignRow('Most reported area', prettyComponent(top.key)),
                SignRow('Involved a crash', numFmt(done.crashes.toDouble(), 0)),
                SignRow('Involved a fire', numFmt(done.fires.toDouble(), 0)),
                SignRow('Injuries reported', numFmt(done.injuries.toDouble(), 0)),
              ]
            : const [],
        extra: SignNote(
            '${done.total == 0 ? 'No complaints are on file with NHTSA for this model year. ' : 'These are reports from owners, not confirmed defects. '}'
            'Newer and more popular cars collect more complaints, so a bigger number does not always mean a worse car.',
            tone: tone),
      );
    }

    final maxCount = (done == null || done.components.isEmpty) ? 1 : done.components.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalcLayout(sign: sign, children: [
          VehiclePicker(kind: VehicleKind.complaints, busy: busy, onSubmit: _search, button: 'Find problems'),
        ]),
        if (done != null && done.total > 0) ...[
          Panel(
            title: 'Where owners report problems',
            child: Column(children: [
              for (final c in done.components.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(prettyComponent(c.key), style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text(numFmt(c.value.toDouble(), 0), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: c.value / maxCount,
                        minHeight: 8,
                        backgroundColor: C.card,
                        color: C.route,
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: Text('Latest complaints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            const SourceNote(),
          ]),
          const SizedBox(height: 12),
          for (final c in done.latest.take(shown)) _card(c),
          if (shown < done.latest.length)
            Align(
              alignment: Alignment.centerLeft,
              child: ShowMore(left: done.latest.length - shown, onTap: () => setState(() => shown += _page)),
            ),
        ],
      ],
    );
  }
}
