import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/fonts.dart';
import '../core/svg_art.dart';
import '../core/theme.dart';
import '../core/tool_model.dart';
import '../widgets/decor.dart';
import '../widgets/scenery.dart';
import 'tool_screen.dart';

const double _carW = 30, _carH = 57.5, _roadW = 38;
const double _farDrift = 0.5, _nearDrift = 0.25;
const _farKinds = ['hill', 'cloud', 'pine', 'tree', 'cloud', 'pine'];
const _nearKinds = ['gas', 'tree', 'billboard', 'pine', 'house', 'ev', 'light', 'tree', 'lamp'];

class _Pose {
  final Offset pos;
  final double angle; // radians, art faces down
  final double progress; // px scrolled past the anchor (for parallax)
  const _Pose(this.pos, this.angle, this.progress);
}

/// The tools as stops along one winding road. The road passes through every
/// stop and swings left and right in between. A car drives along it as the
/// page scrolls, and the stop it is passing is lifted into a light box.
class RouteList extends StatefulWidget {
  final List<Tool> tools;
  final ScrollController controller;
  const RouteList({super.key, required this.tools, required this.controller});

  @override
  State<RouteList> createState() => _RouteListState();
}

class _RouteListState extends State<RouteList> {
  final listKey = GlobalKey();
  late final List<GlobalKey> shieldKeys = List.generate(widget.tools.length, (_) => GlobalKey());
  late final far = makeScene((widget.tools.length * 1.2).round(), _farKinds, 11);
  late final near = makeScene((widget.tools.length * 1.8).round(), _nearKinds, 5);

  final pose = ValueNotifier<_Pose?>(null);
  Path? road;
  Size listSize = Size.zero;
  List<Offset> samples = [];
  List<double> stopYs = [];
  String _sig = '';
  int active = 0;
  bool _measureQueued = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    pose.dispose();
    super.dispose();
  }

  /* 1. measure where each stop sits and draw a curve through all of them */
  void _queueMeasure() {
    if (_measureQueued) return;
    _measureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureQueued = false;
      if (mounted) _measure();
    });
  }

  void _measure() {
    final listBox = listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null || !listBox.hasSize) return;
    final pts = <Offset>[];
    for (final k in shieldKeys) {
      final b = k.currentContext?.findRenderObject() as RenderBox?;
      if (b == null || !b.hasSize) return;
      pts.add(b.localToGlobal(b.size.center(Offset.zero), ancestor: listBox));
    }
    if (pts.isEmpty) return;

    final size = listBox.size;
    final sig = '${size.width.round()}x${size.height.round()}|${pts.map((p) => '${p.dx.round()},${p.dy.round()}').join(';')}';
    if (sig == _sig) return;
    _sig = sig;

    final wide = size.width >= 700;
    final amp = wide ? 24.0 : 12.0;
    final x = pts.first.dx;
    final nodes = <Offset>[Offset(x, 0), ...pts, Offset(x, size.height)];
    final path = Path()..moveTo(x, 0);
    for (var i = 1; i < nodes.length; i++) {
      final prev = nodes[i - 1], cur = nodes[i];
      final dy = cur.dy - prev.dy;
      final side = i.isOdd ? 1.0 : -1.0;
      final k = (amp * math.min(1.0, dy / 160) / 0.75) * side;
      path.cubicTo(x + k, prev.dy + dy / 3, x + k, cur.dy - dy / 3, x, cur.dy);
    }

    // sample the curve once so the car can look up a point by its height
    final pts2 = <Offset>[];
    for (final m in path.computeMetrics()) {
      for (double l = 0; l < m.length; l += 4) {
        pts2.add(m.getTangentForOffset(l)!.position);
      }
      pts2.add(m.getTangentForOffset(m.length)!.position);
    }

    setState(() {
      road = path;
      listSize = size;
      samples = pts2;
      stopYs = pts.map((p) => p.dy).toList();
    });
    _onScroll();
  }

  /* 2. move the car along the curve on scroll */
  void _onScroll() {
    final listBox = listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null || !listBox.attached || samples.isEmpty) return;
    final screenH = MediaQuery.sizeOf(context).height;
    final top = listBox.localToGlobal(Offset.zero).dy;
    final h = listSize.height;

    final anchor = screenH * 0.55; // a little below the middle of the screen
    final y = (anchor - top).clamp(_carH / 2, h - _carH / 2).toDouble();
    final progress = (anchor - top).clamp(0.0, h).toDouble();

    var lo = 0, hi = samples.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (samples[mid].dy < y) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final a = samples[math.max(lo - 1, 0)];
    final b = samples[math.min(lo + 1, samples.length - 1)];
    final p = samples[lo];
    // the car art faces down, so turn it to follow the road's direction
    final angle = math.atan2(b.dy - a.dy, b.dx - a.dx) - math.pi / 2;
    pose.value = _Pose(p, angle, progress);

    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < stopYs.length; i++) {
      final d = (stopYs[i] - p.dy).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    if (best != active) setState(() => active = best);
  }

  @override
  Widget build(BuildContext context) {
    _queueMeasure();
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 700;
      return Stack(
        key: listKey,
        clipBehavior: Clip.none,
        children: [
          // blurred roadside scenery, behind everything and clipped to the road's length
          if (road != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: ValueListenableBuilder<_Pose?>(
                    valueListenable: pose,
                    builder: (context, p, _) {
                      final prog = p?.progress ?? 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Transform.translate(
                            offset: Offset(0, prog * _farDrift),
                            child: Stack(children: [
                              SceneLayer(
                                  items: far,
                                  height: listSize.height,
                                  width: listSize.width,
                                  drift: _farDrift,
                                  blur: 5,
                                  opacity: 0.3,
                                  scale: wide ? 1 : 0.7),
                            ]),
                          ),
                          Transform.translate(
                            offset: Offset(0, prog * _nearDrift),
                            child: Stack(children: [
                              SceneLayer(
                                  items: near,
                                  height: listSize.height,
                                  width: listSize.width,
                                  drift: _nearDrift,
                                  blur: 3,
                                  opacity: 0.42,
                                  scale: wide ? 1 : 0.7),
                            ]),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

          // the road
          if (road != null)
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _RoadPainter(road!))),
            ),

          // the car, driven by scroll position
          if (road != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<_Pose?>(
                  valueListenable: pose,
                  builder: (context, p, _) {
                    if (p == null) return const SizedBox.shrink();
                    return Stack(clipBehavior: Clip.none, children: [
                      Positioned(
                        left: p.pos.dx - _carW / 2,
                        top: p.pos.dy - _carH / 2,
                        width: _carW,
                        height: _carH,
                        child: Transform.rotate(
                          angle: p.angle,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3)),
                              ],
                            ),
                            child: SvgPicture.string(carSvg, width: _carW, height: _carH),
                          ),
                        ),
                      ),
                    ]);
                  },
                ),
              ),
            ),

          // the stops
          SizedBox(
            width: double.infinity,
            child: Column(
            children: [
              for (var i = 0; i < widget.tools.length; i++)
                _Stop(
                  tool: widget.tools[i],
                  index: i,
                  active: i == active,
                  wide: wide,
                  shieldKey: shieldKeys[i],
                ),
            ],
          )),
        ],
      );
    });
  }
}

class _RoadPainter extends CustomPainter {
  final Path path;
  _RoadPainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path,
      Paint()
        ..color = C.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = _roadW
        ..strokeCap = StrokeCap.round,
    );
    final dash = Paint()
      ..color = C.hwy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 14, m.length)), dash);
        d += 28;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) => old.path != path;
}

class _Stop extends StatelessWidget {
  final Tool tool;
  final int index;
  final bool active, wide;
  final GlobalKey shieldKey;
  const _Stop({
    required this.tool,
    required this.index,
    required this.active,
    required this.wide,
    required this.shieldKey,
  });

  Widget _shield() => AnimatedScale(
        scale: active ? 1.1 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: Container(
          key: shieldKey,
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: C.paper, shape: BoxShape.circle),
          child: Hero(
            tag: 'shield-${tool.slug}',
            child: Shield(glyph: tool.glyph, tone: tool.tone, size: 52),
          ),
        ),
      );

  Widget _card(bool rightAligned) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.6,
      duration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: active ? C.card : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? C.ink.withOpacity(0.2) : Colors.transparent, width: 2),
          boxShadow: active
              ? [BoxShadow(color: C.ink.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -10)]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: rightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              tool.name,
              textAlign: rightAligned ? TextAlign.right : TextAlign.left,
              style: disp(22, weight: FontWeight.w800, height: 1.1).copyWith(
                decoration: active ? TextDecoration.underline : TextDecoration.none,
                decorationColor: C.hwy,
                decorationThickness: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(tool.short,
                textAlign: rightAligned ? TextAlign.right : TextAlign.left,
                style: const TextStyle(color: C.inkSoft, height: 1.35)),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'You enter ', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: '${tool.enter}. ', style: const TextStyle(color: C.inkSoft)),
                const TextSpan(text: 'You get ', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: '${tool.get}.', style: const TextStyle(color: C.inkSoft)),
              ]),
              textAlign: rightAligned ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onLeft = index.isEven;
    final Widget row;
    if (wide) {
      row = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: onLeft ? _card(true) : const SizedBox.shrink()),
          SizedBox(width: 96, child: Center(child: _shield())),
          Expanded(child: onLeft ? const SizedBox.shrink() : _card(false)),
        ],
      );
    } else {
      row = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 68, child: Center(child: _shield())),
          const SizedBox(width: 8),
          Expanded(child: _card(false)),
        ],
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => ToolScreen(tool: tool),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      )),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: wide ? 24 : 12, horizontal: wide ? 20 : 8),
        child: row,
      ),
    );
  }
}
