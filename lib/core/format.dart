/// Number formatting without the intl package (en-US style).

double _clean(double n, int d) {
  final limit = 0.5 * _pow10(-d);
  return n.abs() < limit ? 0 : n;
}

double _pow10(int e) {
  var r = 1.0;
  if (e >= 0) {
    for (var i = 0; i < e; i++) {
      r *= 10;
    }
  } else {
    for (var i = 0; i < -e; i++) {
      r /= 10;
    }
  }
  return r;
}

String _group(String digits) {
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final left = digits.length - i;
    b.write(digits[i]);
    if (left > 1 && left % 3 == 1) b.write(',');
  }
  return b.toString();
}

/// Exactly [d] decimals, with thousands separators.
String fixed(double n, [int d = 1]) {
  final v = _clean(n, d);
  final s = v.abs().toStringAsFixed(d);
  final parts = s.split('.');
  final body = parts.length > 1 ? '${_group(parts[0])}.${parts[1]}' : _group(parts[0]);
  return v < 0 ? '-$body' : body;
}

/// Up to [d] decimals, no trailing zeros.
String numFmt(double n, [int d = 1]) {
  var s = fixed(n, d);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}

String money(double n, [int d = 2]) {
  final v = _clean(n, d);
  final s = fixed(v.abs(), d);
  return v < 0 ? '-\$$s' : '\$$s';
}

String signed(double n, [int d = 1]) {
  final v = _clean(n, d);
  final sign = v > 0 ? '+' : (v < 0 ? '\u2212' : '');
  return '$sign${fixed(v.abs(), d)}';
}

/// Turns what someone typed into a number. Empty or half-typed gives NaN.
double parse(String s) {
  final t = s.replaceAll(',', '').trim();
  if (t.isEmpty || t == '.' || t == '-' || t == '-.') return double.nan;
  return double.tryParse(t) ?? double.nan;
}
