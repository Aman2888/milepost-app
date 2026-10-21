import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/svg_art.dart';
import '../core/theme.dart';
import 'ui.dart' show glyphIcon;

/// Paper colour with the faint atlas grid from globals.css.
class PaperBackground extends StatelessWidget {
  final Widget child;
  const PaperBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = C.paper);
    final p = Paint()
      ..color = C.ink.withOpacity(0.045)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The yellow dashed line down the middle of a road, used as the page divider.
class Centerline extends StatelessWidget {
  final double height;
  const Centerline({super.key, this.height = 5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _CenterPainter()),
    );
  }
}

class _CenterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = C.hwy;
    for (double x = 0; x < size.width; x += 52) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 30, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Route-shield badge for a tool, like the ones on highway signs.
class Shield extends StatelessWidget {
  final String glyph, tone;
  final double size;
  const Shield({super.key, required this.glyph, required this.tone, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(shieldSvg(glyph, tone), width: size, height: size * 54 / 48);
  }
}

class MilepostMark extends StatelessWidget {
  final double height;
  const MilepostMark({super.key, this.height = 36});

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(milepostSvg, height: height, width: height * 28 / 38);
}

/// A white line icon from the website's glyph set.
class GlyphIcon extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  const GlyphIcon(this.name, {super.key, this.color = C.ink, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final hex = '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return SvgPicture.string(glyphSvg(name, hex), width: size, height: size);
  }
}

/// Fades and slides its child up on first build. Use [delay] to stagger.
class FadeSlide extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double dy;
  const FadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.dy = 24,
  });

  @override
  Widget build(BuildContext context) {
    final total = delay + duration;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * dy), child: c),
      ),
      child: child,
    );
  }
}

/// Blurs [child] without re-rasterising it every frame it moves.
class BlurLayer extends StatelessWidget {
  final double sigma, opacity;
  final Widget child;
  const BlurLayer({super.key, required this.sigma, required this.opacity, required this.child});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: RepaintBoundary(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
          child: child,
        ),
      ),
    );
  }
}

/// Round tonal icon badge for a tool (Material style).
class ToolIcon extends StatelessWidget {
  final String glyph, tone;
  final double size;
  const ToolIcon({super.key, required this.glyph, required this.tone, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final base = tone == 'yellow' ? const Color(0xFF8A6100) : C.tone(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: base.withOpacity(0.14), shape: BoxShape.circle),
      child: Icon(glyphIcon(glyph), color: base, size: size * 0.54),
    );
  }
}
