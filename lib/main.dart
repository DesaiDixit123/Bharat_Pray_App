import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/localization/language_manager.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_notification_service.dart';

import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  
  // Initialize Persistent Language Management
  await LanguageManager.instance.initialize();

  // Initialize Firebase and Sacred Push Notification Service
  try {
    await Firebase.initializeApp();
    await FcmNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase Initialization Notice: $e');
  }

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system navigation bar & status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF0F081D),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const BharatPrayApp());
}

class BharatPrayApp extends StatelessWidget {
  const BharatPrayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageManager.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'Bharat Pray',
          debugShowCheckedModeBanner: false,
          locale: LanguageManager.instance.currentLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            splashFactory: InkRipple.splashFactory,
            primaryColor: const Color(0xFFFF7700),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF7700),
              brightness: Brightness.dark,
              primary: const Color(0xFFFF7700),
              secondary: const Color(0xFFFF5500),
              surface: const Color(0xFF0F081D),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F081D),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
