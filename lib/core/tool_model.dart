class Tool {
  final String slug;
  final String name;
  final String short;
  final String enter;
  final String get;
  final String glyph;
  final String tone; // blue | red | yellow | green | ink
  final String formula;
  final List<String> tips;
  final String? example;
  final bool isLookup;

  const Tool({
    required this.slug,
    required this.name,
    required this.short,
    required this.enter,
    required this.get,
    required this.glyph,
    required this.tone,
    required this.formula,
    required this.tips,
    this.example,
    this.isLookup = false,
  });
}
