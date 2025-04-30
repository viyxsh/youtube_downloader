import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_downloader/screens/splash_screen.dart';
import 'package:youtube_downloader/theme/theme.dart';
import 'package:youtube_downloader/utils/app_initialization.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  // This is important: ensure the native splash screen stays visible until we're ready
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Configure device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize your app
  await AppInitialization.initializeApp();

  // Now we can remove the native splash screen and start the app
  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TubeSaver',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const SplashScreen(),
    );
  }
}