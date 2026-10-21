import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/svg_art.dart';
import 'decor.dart';

class SceneItem {
  final int id;
  final String kind;
  final double top; // % of the layer
  final bool left;
  final double edge; // % in from the screen edge
  final double width; // px on desktop
  const SceneItem(this.id, this.kind, this.top, this.left, this.edge, this.width);
}

/// native width (px) of each piece of scenery before random scaling
const Map<String, double> _width = {
  'gas': 150,
  'tree': 70,
  'pine': 60,
  'billboard': 120,
  'house': 110,
  'light': 36,
  'ev': 56,
  'lamp': 38,
  'hill': 280,
  'cloud': 160,
};

/// Spread [count] pieces of scenery down the layer, alternating sides at random.
List<SceneItem> makeScene(int count, List<String> kinds, int seed) {
  final rnd = math.Random(seed);
  final offset = (rnd.nextDouble() * kinds.length).floor();
  final slot = 100 / count;
  return List.generate(count, (i) {
    final kind = kinds[(i + offset) % kinds.length];
    return SceneItem(
      i,
      kind,
      i * slot + rnd.nextDouble() * slot * 0.6,
      rnd.nextDouble() < 0.5,
      rnd.nextDouble() * 16,
      (_width[kind]! * (0.85 + rnd.nextDouble() * 0.4)).roundToDouble(),
    );
  });
}

/// One layer of blurred roadside scenery, taller than the road by [drift] so it
/// can slide slower than the page (parallax) and still fill the whole height.
class SceneLayer extends StatelessWidget {
  final List<SceneItem> items;
  final double height, width, drift, blur, opacity, scale;
  const SceneLayer({
    super.key,
    required this.items,
    required this.height,
    required this.width,
    required this.drift,
    required this.blur,
    required this.opacity,
    this.scale = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final layerH = (1 + drift) * height;
    return Positioned(
      left: 0,
      width: width,
      top: -drift * height,
      height: layerH,
      child: BlurLayer(
        sigma: blur,
        opacity: opacity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final it in items)
              Positioned(
                top: it.top / 100 * layerH,
                left: it.left ? it.edge / 100 * width : null,
                right: it.left ? null : it.edge / 100 * width,
                width: it.width * scale,
                child: SvgPicture.string(sceneSvgs[it.kind]!),
              ),
          ],
        ),
      ),
    );
  }
}
