// ─────────────────────────────────────────────────────────────
// main.dart  — UPDATED
// Wraps app with ChangeNotifierProvider<LocaleProvider> so
// locale changes rebuild the whole widget tree.
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'Helper/AppColors.dart';
import 'Helper/AppLocalizations.dart';
import 'Helper/LocaleProvider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/app_language_selection_screen.dart';

// Public identifier for this OneSignal app — safe to embed client-side
// (it's how the SDK knows which OneSignal project to register a
// device against). The REST API key that can actually SEND
// notifications lives only in the backend's .env, never here.
const String _oneSignalAppId = 'afaf7759-b411-46c9-a030-cbc4cdd6ccc6';

void _initOneSignal() {
  OneSignal.initialize(_oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);
}

// A widget failing to build (a null field from an API response, a bad
// index, etc.) used to show Flutter's raw red/grey error box straight
// to the student. Swap in a plain, friendly placeholder instead — in
// debug the real error still prints to the console so it's not hidden
// from whoever's developing.
void _installErrorHandlers() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return Container(
      color: AppColors.backgroundColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.textSecondary, size: 32),
          SizedBox(height: 12),
          Text(
            "Something went wrong displaying this screen.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  };

  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    // Console/crash-log visibility during development; still reports
    // upward so tooling (DevTools, crash reporters if added later)
    // keeps seeing it, but never lets it crash the whole app.
    FlutterError.presentError(details);
    originalOnError?.call(details);
  };
}

void main() {
  // WidgetsFlutterBinding.ensureInitialized() and runApp() must run in the
  // same zone — calling ensureInitialized() outside runZonedGuarded (as
  // this used to) throws a "Zone mismatch" the moment runApp() fires from
  // inside the guarded zone. Doing all of it inside the same callback
  // avoids that entirely.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    _installErrorHandlers();
    _initOneSignal();

    final localeProvider = LocaleProvider();
    await localeProvider.init(); // restore saved language before first frame
    runApp(
      ChangeNotifierProvider.value(
        value: localeProvider,
        child: const DaminiPlusApp(),
      ),
    );
  }, (error, stack) {
    // Anything async that slips past every other try/catch in the app
    // lands here instead of silently killing the isolate.
    if (kDebugMode) {
      // ignore: avoid_print
      print('Uncaught zone error: $error\n$stack');
    }
  });
}

class DaminiPlusApp extends StatelessWidget {
  const DaminiPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'Damini Plus',
      debugShowCheckedModeBanner: false,

      // ── Locale setup ─────────────────────────────────────
      locale: localeProvider.locale,
      supportedLocales: const [kLocaleEn, kLocaleHi],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundColor,
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),

      // ── Routes ───────────────────────────────────────────
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/appLanguage': (_) =>
        const AppLanguageSelectionScreen(fromSettings: false),
      },
    );
  }
}