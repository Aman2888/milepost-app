import 'package:flutter/material.dart';
import '../core/site.dart';
import '../core/theme.dart';
import '../widgets/decor.dart';
import 'home_screen.dart';

/// Android-style splash: the logo and name fade in on a plain surface, then the home screen appears.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    c.forward().whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.paper,
      body: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final v = Curves.easeOutCubic.transform(c.value);
          return Center(
            child: Opacity(
              opacity: v,
              child: Transform.scale(
                scale: 0.9 + 0.1 * v,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MilepostMark(height: 72),
                    const SizedBox(height: 16),
                    Text(siteName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(siteTagline, style: TextStyle(color: C.inkSoft)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
