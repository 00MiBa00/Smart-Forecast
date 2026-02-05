import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app_config.dart';
import '../services/sdk_initializer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() {
    if (kDebugMode) {
      print('=== SPLASH SCREEN CREATED ===');
    }
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Разрешаем все ориентации для Splash экрана
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (kDebugMode) {
      print('SplashScreen initState called');
    }
    // Ensure the widget is built before initializing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        print('PostFrameCallback - calling _initializeApp');
      }
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (kDebugMode) {
      print('_initializeApp started, mounted: $mounted');
    }
    if (!mounted) return;
    await SdkInitializer.initAll(context);
    if (kDebugMode) {
      print('_initializeApp completed');
    }
    // await Future.delayed(const Duration(seconds: 1));
    // Navigator.of(context).pushReplacement(
    //   MaterialPageRoute(builder: (context) => const MainScreen()),
    // );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('SplashScreen build called');
    }
    final screenHeight = MediaQuery.of(context).size.width;
    final logoSize = screenHeight * 0.8; // Адаптивный размер логотипа

    return Scaffold(
      backgroundColor:
          Colors.blue, // ВРЕМЕННО: для проверки что экран рендерится
      body: Container(
        decoration: AppConfig
            .splashDecoration, // const BoxDecoration(gradient: AppConfig.splashGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    AppConfig.logoPath,
                    height: logoSize,
                    width: logoSize,
                    errorBuilder: (context, error, stackTrace) {
                      // Показываем текст если изображение не загружается
                      if (kDebugMode) {
                        print('Error loading logo: $error');
                      }
                      return const Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppConfig.spinerColor,
                      strokeWidth: 4,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: AppConfig.loadingTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
