import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  
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
    return MaterialApp(
      title: 'Bharat Pray',
      debugShowCheckedModeBanner: false,
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
  }
}
