import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'core/site.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MilepostApp());
}

class MilepostApp extends StatelessWidget {
  const MilepostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: siteName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const _TouchScroll(),
      builder: (context, child) => _PhoneFrame(child: child ?? const SizedBox.shrink()),
      home: const SplashScreen(),
    );
  }
}

/// Drag-to-scroll with mouse too, and Android-style clamping physics.
class _TouchScroll extends MaterialScrollBehavior {
  const _TouchScroll();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

/// Keeps the app at phone width. On a wide screen (browser / tablet) it is
/// centred like a phone instead of stretching into a website layout.
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});

  static const double maxWidth = 440;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= maxWidth) return child;
    return ColoredBox(
      // color: const C.paperDeep,
      color: C.paperDeep,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: ClipRect(
            child: MediaQuery(data: mq.copyWith(size: Size(maxWidth, mq.size.height)), child: child),
          ),
        ),
      ),
    );
  }
}
