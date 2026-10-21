/// Direct client for NHTSA's free public APIs. A port of app/api/nhtsa/route.ts
/// and lib/nhtsa.ts. A mobile app has no CORS limit, so no proxy server is needed.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _api = 'https://api.nhtsa.gov';
const _vpic = 'https://vpic.nhtsa.dot.gov/api/vehicles';

enum VehicleKind { recalls, complaints, ratings }

class NhtsaException implements Exception {
  final String message;
  NhtsaException(this.message);
  @override
  String toString() => message;
}

/* ---------------- models ---------------- */

class VinResult {
  final Map<String, String> fields;
  final String errorCode, errorText;
  VinResult(this.fields, this.errorCode, this.errorText);
}

class Recall {
  final String campaign, component, summary, consequence, remedy, notes;
  final String? date; // ISO yyyy-mm-dd
  final bool parkIt, parkOutside, ota;
  Recall({
    required this.campaign,
    required this.date,
    required this.component,
    required this.summary,
    required this.consequence,
    required this.remedy,
    required this.notes,
    required this.parkIt,
    required this.parkOutside,
    required this.ota,
  });
}

class Complaint {
  final String id, summary;
  final String? filed, incident;
  final List<String> components;
  final bool crash, fire;
  final int injuries, deaths;
  Complaint({
    required this.id,
    required this.filed,
    required this.incident,
    required this.components,
    required this.summary,
    required this.crash,
    required this.fire,
    required this.injuries,
    required this.deaths,
  });
}

class ComplaintResult {
  final int total, crashes, fires, injuries, deaths;
  final List<MapEntry<String, int>> components;
  final List<Complaint> latest;
  ComplaintResult(this.total, this.crashes, this.fires, this.injuries, this.deaths,
      this.components, this.latest);
}

class Rating {
  final String id, description, esc, fcw, ldw;
  final int? overall, front, frontDriver, frontPassenger, side, sideDriver, sidePassenger;
  final int? pole, rollover, recalls, complaints, investigations;
  final double? rolloverChance; // 0..1
  Rating({
    required this.id,
    required this.description,
    required this.overall,
    required this.front,
    required this.frontDriver,
    required this.frontPassenger,
    required this.side,
    required this.sideDriver,
    required this.sidePassenger,
    required this.pole,
    required this.rollover,
    required this.rolloverChance,
    required this.esc,
    required this.fcw,
    required this.ldw,
    required this.recalls,
    required this.complaints,
    required this.investigations,
  });
}

/* ---------------- helpers ---------------- */

typedef Json = Map<String, dynamic>;

List<Json> _list(Json data, List<String> keys) {
  for (final k in keys) {
    final v = data[k];
    if (v is List) return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
}

String _str(dynamic v) {
  if (v is String) return v.trim();
  if (v is num) return v.toString();
  return '';
}

bool _flag(dynamic v) {
  if (v == true) return true;
  if (v is String) return RegExp(r'^(y|yes|true|1)$', caseSensitive: false).hasMatch(v.trim());
  return false;
}

int _int(dynamic v) => int.tryParse('${v ?? ''}'.trim()) ?? 0;

int? _stars(dynamic v) {
  final n = int.tryParse('${v ?? ''}'.trim());
  return (n != null && n >= 1 && n <= 5) ? n : null;
}

int? _count(dynamic v) => int.tryParse('${v ?? ''}'.trim());

String _clip(String s, int max) => s.length > max ? '${s.substring(0, max).trimRight()}…' : s;

/* NHTSA's slash dates are day-first in some datasets and month-first in others. */
String _detectOrder(List<String> dates, String fallback) {
  final re = RegExp(r'^(\d{1,2})/(\d{1,2})/\d{4}');
  for (final d in dates) {
    final m = re.firstMatch(d);
    if (m == null) continue;
    if (int.parse(m.group(1)!) > 12) return 'dmy';
    if (int.parse(m.group(2)!) > 12) return 'mdy';
  }
  return fallback;
}

String? _toIso(String raw, String order) {
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
  if (iso != null) return '${iso.group(1)}-${iso.group(2)}-${iso.group(3)}';
  final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(raw);
  if (m == null) return null;
  final day = int.parse(order == 'dmy' ? m.group(1)! : m.group(2)!);
  final month = int.parse(order == 'dmy' ? m.group(2)! : m.group(1)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return '${m.group(3)}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

int _byDateDesc(String? a, String? b) => (b ?? '').compareTo(a ?? '');

const _commaTails = {'GASOLINE', 'DIESEL', 'OTHER', 'AIR', 'ELECTRIC', 'HYDRAULIC'};
const _commaHeads = {'FUEL SYSTEM', 'SERVICE BRAKES'};

List<String> _splitComponents(String raw) {
  final out = <String>[];
  for (final token in raw.split(',')) {
    final head = token.split(':')[0].trim();
    if (head.isEmpty) continue;
    if (out.isNotEmpty &&
        _commaHeads.contains(out.last.toUpperCase()) &&
        _commaTails.contains(head.toUpperCase())) {
      out[out.length - 1] = '${out.last}, $head';
    } else {
      out.add(head);
    }
  }
  return out.toSet().toList();
}

/* ---------------- service ---------------- */

class Nhtsa {
  Nhtsa._();
  static final Nhtsa instance = Nhtsa._();

  final http.Client _client = http.Client();
  final Map<String, Json> _cache = {};

  /// [cache] true for data that rarely changes (never for VINs).
  Future<Json> _get(String url, {bool cache = true}) async {
    if (cache && _cache.containsKey(url)) return _cache[url]!;
    http.Response res;
    try {
      res = await _client
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw NhtsaException('NHTSA took too long to answer. Please try again.');
    } catch (_) {
      throw NhtsaException('Could not connect. Check your internet connection and try again.');
    }
    if (res.statusCode != 200) {
      throw NhtsaException('NHTSA returned an error (${res.statusCode}). Please try again later.');
    }
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final json = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
      if (cache) _cache[url] = json;
      return json;
    } catch (_) {
      throw NhtsaException('NHTSA sent a reply that could not be read. Please try again later.');
    }
  }

  static final _name = RegExp(r"^[\w\s\-./&'()+,#]{1,60}$");
  String _enc(String s) => Uri.encodeComponent(s);

  Future<VinResult> decodeVin(String vin) async {
    final v = vin.toUpperCase().trim();
    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(v)) {
      throw NhtsaException('A VIN has 17 letters and numbers. The letters I, O and Q are never used.');
    }
    final data = await _get('$_vpic/DecodeVinValues/$v?format=json', cache: false);
    final rows = _list(data, ['Results', 'results']);
    final row = rows.isEmpty ? <String, dynamic>{} : rows.first;
    final fields = <String, String>{};
    row.forEach((k, val) {
      final s = _str(val);
      if (s.isNotEmpty && s != 'Not Applicable') fields[k] = s;
    });
    final code = fields.remove('ErrorCode') ?? '';
    final text = fields.remove('ErrorText') ?? '';
    return VinResult(fields, code, text);
  }

  Future<List<String>> names(VehicleKind kind, String year, {String? make}) async {
    final what = make == null ? 'makes' : 'models';
    if (!RegExp(r'^(19|20)\d{2}$').hasMatch(year)) throw NhtsaException('Pick a model year.');
    if (make != null && !_name.hasMatch(make)) throw NhtsaException('Pick a make.');

    List<Json> rows;
    if (kind == VehicleKind.ratings) {
      final url = what == 'makes'
          ? '$_api/SafetyRatings/modelyear/$year?format=json'
          : '$_api/SafetyRatings/modelyear/$year/make/${_enc(make!)}?format=json';
      rows = _list(await _get(url), ['Results', 'results']);
    } else {
      final issue = kind == VehicleKind.recalls ? 'r' : 'c';
      final url = what == 'makes'
          ? '$_api/products/vehicle/makes?modelYear=$year&issueType=$issue'
          : '$_api/products/vehicle/models?modelYear=$year&make=${_enc(make!)}&issueType=$issue';
      rows = _list(await _get(url), ['results', 'Results']);
    }
    final key = what == 'makes' ? 'make' : 'model';
    final cap = key[0].toUpperCase() + key.substring(1);
    final seen = <String>{};
    for (final r in rows) {
      final v = _str(r[key] ?? r[cap]);
      if (v.isNotEmpty) seen.add(v);
    }
    return seen.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _check(String year, String make, String model) {
    if (!RegExp(r'^(19|20)\d{2}$').hasMatch(year)) throw NhtsaException('Pick a model year.');
    if (!_name.hasMatch(make)) throw NhtsaException('Pick a make.');
    if (!_name.hasMatch(model)) throw NhtsaException('Pick a model.');
  }

  Future<List<Recall>> recalls(String year, String make, String model) async {
    _check(year, make, model);
    final data = await _get(
        '$_api/recalls/recallsByVehicle?make=${_enc(make)}&model=${_enc(model)}&modelYear=$year');
    final rows = _list(data, ['results', 'Results']);
    final order = _detectOrder(rows.map((r) => _str(r['ReportReceivedDate'])).toList(), 'dmy');
    final items = rows
        .map((r) => Recall(
              campaign: _str(r['NHTSACampaignNumber']),
              date: _toIso(_str(r['ReportReceivedDate']), order),
              component: _str(r['Component']),
              summary: _str(r['Summary']),
              consequence: _str(r['Consequence'] ?? r['Conequence']),
              remedy: _str(r['Remedy']),
              notes: _str(r['Notes']),
              parkIt: _flag(r['parkIt']),
              parkOutside: _flag(r['parkOutSide']),
              ota: _flag(r['overTheAirUpdate']),
            ))
        .toList();
    items.sort((a, b) => _byDateDesc(a.date, b.date));
    return items;
  }

  Future<ComplaintResult> complaints(String year, String make, String model) async {
    _check(year, make, model);
    final data = await _get(
        '$_api/complaints/complaintsByVehicle?make=${_enc(make)}&model=${_enc(model)}&modelYear=$year');
    final rows = _list(data, ['results', 'Results']);
    final order = _detectOrder(
        rows.expand((r) => [_str(r['dateComplaintFiled']), _str(r['dateOfIncident'])]).toList(),
        'mdy');
    final all = rows
        .map((r) => Complaint(
              id: _str(r['odiNumber']),
              filed: _toIso(_str(r['dateComplaintFiled']), order),
              incident: _toIso(_str(r['dateOfIncident']), order),
              components: _splitComponents(_str(r['components'])),
              summary: _clip(_str(r['summary']), 600),
              crash: _flag(r['crash']),
              fire: _flag(r['fire']),
              injuries: _int(r['numberOfInjuries']),
              deaths: _int(r['numberOfDeaths']),
            ))
        .toList();

    final tally = <String, int>{};
    for (final c in all) {
      for (final n in c.components) {
        tally[n] = (tally[n] ?? 0) + 1;
      }
    }
    all.sort((a, b) => _byDateDesc(a.filed, b.filed));
    final comps = tally.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    return ComplaintResult(
      all.length,
      all.where((c) => c.crash).length,
      all.where((c) => c.fire).length,
      all.fold(0, (s, c) => s + c.injuries),
      all.fold(0, (s, c) => s + c.deaths),
      comps,
      all.take(50).toList(),
    );
  }

  Future<List<Rating>> ratings(String year, String make, String model) async {
    _check(year, make, model);
    final variants = _list(
        await _get(
            '$_api/SafetyRatings/modelyear/$year/make/${_enc(make)}/model/${_enc(model)}?format=json'),
        ['Results', 'results']);
    final ids = variants
        .map((v) => _str(v['VehicleId']))
        .where((id) => RegExp(r'^\d+$').hasMatch(id) && id != '0')
        .toSet()
        .take(8)
        .toList();
    final details = await Future.wait(
        ids.map((id) => _get('$_api/SafetyRatings/VehicleId/$id?format=json')));

    final items = <Rating>[];
    for (var i = 0; i < details.length; i++) {
      final rs = _list(details[i], ['Results', 'results']);
      if (rs.isEmpty) continue;
      final r = rs.first;
      final chance = double.tryParse('${r['RolloverPossibility'] ?? ''}');
      items.add(Rating(
        id: ids[i],
        description: _str(r['VehicleDescription']),
        overall: _stars(r['OverallRating']),
        front: _stars(r['OverallFrontCrashRating']),
        frontDriver: _stars(r['FrontCrashDriversideRating']),
        frontPassenger: _stars(r['FrontCrashPassengersideRating']),
        side: _stars(r['OverallSideCrashRating']),
        sideDriver: _stars(r['SideCrashDriversideRating']),
        sidePassenger: _stars(r['SideCrashPassengersideRating']),
        pole: _stars(r['SidePoleCrashRating']),
        rollover: _stars(r['RolloverRating']),
        rolloverChance: (chance != null && chance > 0) ? (chance > 1 ? chance / 100 : chance) : null,
        esc: _str(r['NHTSAElectronicStabilityControl']),
        fcw: _str(r['NHTSAForwardCollisionWarning']),
        ldw: _str(r['NHTSALaneDepartureWarning']),
        recalls: _count(r['RecallsCount']),
        complaints: _count(r['ComplaintsCount']),
        investigations: _count(r['InvestigationCount']),
      ));
    }
    return items;
  }
}

/* ---------------- formatting helpers (lib/nhtsa.ts) ---------------- */

String prettyName(String s) {
  if (s.isEmpty || RegExp(r'[a-z]').hasMatch(s)) return s;
  return s.replaceAllMapped(RegExp(r'[A-Z0-9]+'), (m) {
    final w = m.group(0)!;
    if (RegExp(r'\d').hasMatch(w) || w.length <= 3) return w;
    return w[0] + w.substring(1).toLowerCase();
  });
}

const _acronyms = {'ESC', 'ABS', 'LDW', 'FCW', 'EV', 'LED'};

String prettyComponent(String s) {
  return s.toLowerCase().replaceAllMapped(RegExp(r'[a-z]+'), (m) {
    final w = m.group(0)!;
    if (_acronyms.contains(w.toUpperCase())) return w.toUpperCase();
    return m.start == 0 ? w[0].toUpperCase() + w.substring(1) : w;
  });
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "2018-03-04" becomes "Mar 4, 2018".
String formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
  if (m == null) return iso;
  final mo = int.parse(m.group(2)!);
  if (mo < 1 || mo > 12) return iso;
  return '${_months[mo - 1]} ${int.parse(m.group(3)!)}, ${m.group(1)}';
}

String? matchName(List<String> list, String wanted) {
  String norm(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final w = norm(wanted);
  if (w.isEmpty) return null;
  for (final x in list) {
    if (norm(x) == w) return x;
  }
  final near = list.where((x) {
    final n = norm(x);
    return n.startsWith(w) || w.startsWith(n);
  }).toList();
  return near.length == 1 ? near.first : null;
}
