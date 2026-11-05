import 'package:flutter/material.dart';
import 'app_locale.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'splash_screen.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore session asynchronously in background without blocking instant app & animation start
  ApiService.instance.initSession();
  NotificationService.instance.init();

  // Start real-time background synchronization with web backend
  ApiService.instance.startRealtimeSync();

  runApp(const KUmedFarmApp());
}

class KUmedFarmApp extends StatefulWidget {
  const KUmedFarmApp({super.key});

  @override
  State<KUmedFarmApp> createState() => _KUmedFarmAppState();
}

class _KUmedFarmAppState extends State<KUmedFarmApp>
    with WidgetsBindingObserver {
  DateTime? _pausedTime;
  bool _isShowingSplash = true; // initially splash is showing on cold start

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final paused = _pausedTime;
      _pausedTime = null;
      // If the app was minimized/backgrounded for more than 500ms and splash is not already open,
      // replay the intro animation when reopening the app!
      if (paused != null &&
          DateTime.now().difference(paused).inMilliseconds > 500 &&
          !_isShowingSplash) {
        _triggerResumeSplash();
      }
    }
  }

  void _triggerResumeSplash() {
    _isShowingSplash = true;
    appNavigatorKey.currentState?.push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => SplashScreen(
          isResume: true,
          onFinished: () {
            _isShowingSplash = false;
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) => ValueListenableBuilder<AppLanguage>(
        valueListenable: languageNotifier,
        builder: (context, lang, _) => MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'KUmedFarm',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: mode,
          home: SplashScreen(
            onFinished: () {
              _isShowingSplash = false;
            },
          ),
        ),
      ),
    );
  }
}
