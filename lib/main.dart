import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/sdk_initializer.dart';
import 'core/services/firebase_messaging_service.dart';
import 'firebase_options.dart';
import 'package:flutter/cupertino.dart';
import 'core/screens/splash_screen.dart';

void main() async {
  try {
    if (kDebugMode) {
      print('=== MAIN STARTED ===');
    }
    WidgetsFlutterBinding.ensureInitialized();
    if (kDebugMode) {
      print('Widgets binding initialized');
    }
    
    // Проверяем, не инициализирован ли уже Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        print('Firebase initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase already initialized or error: $e');
      }
      // Firebase уже инициализирован, продолжаем
    }
    
    // Инициализируем Firebase Messaging сразу после Firebase Core
    // Это критично для обработки пушей из terminated state
    try {
      if (kDebugMode) {
        print('Initializing Firebase Messaging...');
      }
      await FirebaseMessagingService.InitPushAndGetToken();
      if (kDebugMode) {
        print('Firebase Messaging initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Messaging: $e');
      }
    }
    
    SdkInitializer.prefs = await SharedPreferences.getInstance();
    await SdkInitializer.loadRuntimeStorageToDevice();
    var isFirstStart = !SdkInitializer.hasValue("isFirstStart");
    var isOrganic = SdkInitializer.getValue("Organic");
    if (kDebugMode) {
      print('add af2 $isFirstStart $isOrganic');
    }
    if (isFirstStart) {
      if (kDebugMode) {
        print('Initializing AppsFlyer...');
      }
      SdkInitializer.initAppsFlyer();
    }

    if (kDebugMode) {
      print('Running app...');
    }
    runApp(const App());
    if (kDebugMode) {
      print('App widget created');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('FATAL ERROR IN MAIN: $e');
      print('Stack trace: $stackTrace');
    }
    // Показываем fallback экран с ошибкой
    runApp(
      CupertinoApp(
        home: Container(
          color: const Color(0xFFFF0000),
          child: Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: CupertinoColors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
