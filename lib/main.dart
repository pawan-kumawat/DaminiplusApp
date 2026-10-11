import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'Helper/AdHelper.dart';
import 'Helper/AppColors.dart';
import 'Helper/AppLocalizations.dart';
import 'Helper/LocaleProvider.dart';
import 'Helper/TabletHelper.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/app_language_selection_screen.dart';

bool ipadView = false;

const String _oneSignalAppId = 'afaf7759-b411-46c9-a030-cbc4cdd6ccc6';

void _initOneSignal() {
  OneSignal.initialize(_oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);
}

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
    FlutterError.presentError(details);
    originalOnError?.call(details);
  };
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    _installErrorHandlers();
    _initOneSignal();
    await AdHelper.init();

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

      // ── iPad / Tablet View Builder ──────────────────────
      builder: (context, child) => TabletLayoutWrapper(child: child),

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