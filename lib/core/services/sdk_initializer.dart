import 'dart:io' show Platform;
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../app/clear_app.dart';
import '../../firebase_options.dart';
import '../app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_messaging_service.dart';
import '../screens/no_internet_connection.dart';
import 'push_request_control.dart';
import '../screens/push_request_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/webview_screen.dart';

class SdkInitializer {
  static BuildContext? _context;
  static AppsflyerSdk? _appsflyerSdk;

  // Хранилище для переменных во время выполнения приложения
  static final Map<String, dynamic> _runtimeStorage = {};
  static Map<String, dynamic> _convrtsion = {};

  // Геттеры для удобного доступа к часто используемым переменным
  static String? receivedUrl;
  static String? pushURL;
  static String? get conversionData =>
      _runtimeStorage['conversionData'] as String?;
  static Map<String, dynamic>? get serverResponse =>
      _runtimeStorage['serverResponse'] as Map<String, dynamic>?;
  static String? get apnsToken => _runtimeStorage['apnsToken'] as String?;
  static SharedPreferences? prefs;

  static PushRequestData? pushRequestData;

  static String deep_link_sub1 = "";
  static String deep_link_value = "";
  
  // Flag to prevent double navigation during first start
  static bool _navigationHandled = false;

  /// Сохраняет содержимое _runtimeStorage в строку JSON
  static String saveRuntimeStorage() {
    try {
      return json.encode(_runtimeStorage);
    } catch (e) {
      //  print('Ошибка при сохранении _runtimeStorage: $e');
      return '{}';
    }
  }

  /// Загружает содержимое JSON-строки в _runtimeStorage (старые значения перезаписываются)
  static void loadRuntimeStorage(String jsonString) {
    try {
      Map<String, dynamic> map = json.decode(jsonString);
      _runtimeStorage
        ..clear()
        ..addAll(map);
    } catch (e) {
      // print('Ошибка при загрузке _runtimeStorage: $e');
    }
  }

  // Методы для работы с хранилищем
  static void setValue(String key, dynamic value) {
    _runtimeStorage[key] = value;
    saveRuntimeStorageToDevice();
  }

  static Future<void> saveRuntimeStorageToDevice() async {
    try {
      final jsonString = saveRuntimeStorage();
      await prefs!.setString('runtimeStorage', jsonString);
      //  print("save data $jsonString");
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка при сохранении runtimeStorage на девайсе: $e');
      }
    }
  }

  static Future<void> loadRuntimeStorageToDevice() async {
    try {
      var json = await prefs!.getString('runtimeStorage');
      loadRuntimeStorage(json!);
      if (kDebugMode) {
        print('runtimeStorage успешно загружен');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка при сохранении runtimeStorage на девайсе: $e');
      }
    }
  }

  static dynamic getValue(String key) {
    return _runtimeStorage[key];
  }

  static bool hasValue(String key) {
    return _runtimeStorage.containsKey(key);
  }

  static void clearStorage() {
    _runtimeStorage.clear();
  }

  static Map<String, dynamic> getAllValues() {
    return Map.from(_runtimeStorage);
  }

  static void showApp(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DocTrainerApp()),
      (route) => false,
    );
  }

  /// Check if context is available for navigation
  static bool hasContext() {
    return _context != null;
  }

  /// Get current context for navigation
  static BuildContext? getContext() {
    return _context;
  }

  static void showWeb(BuildContext context) {
    if (kDebugMode) {
      print('3 showWeb');
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WebViewScreen()),
      (route) => false,
    );
  }

  /// Handle push notification tap - navigate to WebView with pushURL
  static void handlePushNavigation(BuildContext context) {
    if (kDebugMode) {
      print('handlePushNavigation called, pushURL: $pushURL');
    }
    
    if (pushURL != null && pushURL!.isNotEmpty) {
      // Navigate to WebView which will use pushURL
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WebViewScreen()),
        (route) => false,
      );
    } else {
      if (kDebugMode) {
        print('handlePushNavigation: pushURL is empty');
      }
    }
  }

  static const MethodChannel _channel =
      MethodChannel('com.yourapp/native_methods');

  static Future<void> callSwiftMethod() async {
    try {
      await _channel.invokeMethod('callSwiftMethod');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to call Swift method: '${e.message}'");
      }
    }
  }

  static Future<void> initAll(BuildContext context) async {
    // Reset navigation flag for fresh start
    _navigationHandled = false;
    
    var isNotInternet =
        await NoInternetConnectionScreen.checkInternetConnection();

    // print('isNotInternet =' + isNotInternet.toString());
    if (!isNotInternet) {
      NoInternetConnectionScreen.showIfNoInternet(context);
      return;
    }
    prefs = await SharedPreferences.getInstance();
    await loadRuntimeStorageToDevice();

    if (hasValue("pushRequestData")) {
      pushRequestData = PushRequestData.fromJson(getValue("pushRequestData"));
    } else {
      pushRequestData = PushRequestData();
      //print("new PushRequestData");
    }
    _context = context;

    var isFirstStart = !hasValue("isFirstStart");
    if (!isFirstStart) {
      var isOrganic = getValue("Organic");
      if (!isOrganic) {
        Map<String, dynamic> conversion = getValue("conversionData");
        if (kDebugMode) {
          print(conversion);
        }
        receivedUrl = await makeConversion(conversion);
        if (PushRequestControl.shouldShowPushRequest(pushRequestData!)) {
          Navigator.pushAndRemoveUntil(
            _context!,
            MaterialPageRoute(builder: (context) => const PushRequestScreen()),
            (route) => false,
          );
        } else {
          // Push notification listeners are already set up in FirebaseMessagingService.init()
          showWeb(context);
        }
      } else {
        showApp(context);
      }
      return;
    }

    // Первый запуск - ждем callback от AppsFlyer
    // AppsFlyer уже инициализирован в main.dart с установленным callback
    if (kDebugMode) {
      print('First start - waiting for AppsFlyer callback');
    }

    // Ждем до 10 секунд на callback от AppsFlyer
    int attempts = 0;
    const maxAttempts = 50; // 50 * 200ms = 10 секунд
    while (!hasValue("isFirstStart") && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;

      // Проверяем, не произошла ли навигация через callback
      if (hasValue("isFirstStart")) {
        if (kDebugMode) {
          print('AppsFlyer callback received after ${attempts * 200}ms');
        }
        return; // Exit early, navigation already handled by callback
      }
    }

    // Если таймаут истек и callback не пришел, считаем organic и показываем приложение
    // Double-check to prevent race condition with callback
    if (!hasValue("isFirstStart") && !_navigationHandled) {
      if (kDebugMode) {
        print('AppsFlyer timeout after ${attempts * 200}ms - showing app as organic');
      }
      _navigationHandled = true;
      setValue("Organic", true);
      setValue("isFirstStart", true);
      await saveRuntimeStorageToDevice();
      showApp(context);
    } else {
      if (kDebugMode) {
        print('AppsFlyer callback completed during final check, navigation already handled');
      }
    }
  }

  static Future<String> makeConversion(
    Map<String, dynamic> conversionMap, {
    String? apnsToken,
    bool isLoad = true,
  }) async {
    conversionMap.addEntries([
      MapEntry("store_id", "id" + AppConfig.appsFlyerAppId),
      MapEntry("bundle_id", AppConfig.bundleId),
      MapEntry("locale", AppConfig.locale),
      MapEntry("os", AppConfig.os),
      MapEntry("firebase_project_id", DefaultFirebaseOptions.ios.projectId),
    ]);

    if (apnsToken != null) {
      conversionMap.addEntries([MapEntry("push_token", apnsToken)]);
    }
    //print(conversionMap);
    var result = await sendPostRequest(
      body: conversionMap,
      url: AppConfig.endpoint + "/config.php",
    );

    if (kDebugMode) {
      print('makeConversion server response: $result');
    }
    
    if (result == null) {
      if (kDebugMode) {
        print('makeConversion: server returned null');
      }
      return "";
    }
    setValue('serverResponse', result);

    if (!result.containsKey("url")) {
      if (kDebugMode) {
        print('makeConversion: response does not contain url key');
      }
      return "";
    }

    if (kDebugMode) {
      print('makeConversion: extracted URL = ${result['url']}');
    }
    return result['url'];
  }

  static void onEndRequest(String? url) {
    if (kDebugMode) {
      print('onEndRequest called with URL: $url');
    }
    
    // Guard against double navigation during first start
    if (_navigationHandled) {
      if (kDebugMode) {
        print('onEndRequest skipped - navigation already handled');
      }
      return;
    }
    _navigationHandled = true;
    
    if (url == null || url == "") {
      if (kDebugMode) {
        print('onEndRequest: URL is empty, showing organic app');
      }
      if (kDebugMode) {
        print('not url');
      }
      setValue("Organic", true);
      setValue("isFirstStart", true);

      showApp(_context!);

      return;
    }
    setValue("Organic", false);
    setValue("isFirstStart", true);

    if (kDebugMode) {
      print('onEndRequest: User is NON-ORGANIC, URL = $url');
    }

    // Сохраняем полный ответ сервера
    setValue('serverResponse', url);

    //print(mapToJsonString(map));

    // print("url: " + url);

    // Сохраняем полученную ссылку в хранилище
    receivedUrl = url;
    setValue('urlReceivedAt', DateTime.now().toIso8601String());
    if (kDebugMode) {
      print('url');
    }

    if (PushRequestControl.shouldShowPushRequest(pushRequestData!)) {
      if (kDebugMode) {
        print('url1');
      }
      Navigator.pushAndRemoveUntil(
        _context!,
        MaterialPageRoute(builder: (context) => const PushRequestScreen()),
        (route) => false,
      );
    } else {
      if (kDebugMode) {
        print('url2');
      }
      Navigator.push(
        _context!,
        MaterialPageRoute(builder: (context) => const WebViewScreen()),
      );
    }
  }

  static bool isHasConversion = false;
  static void initAppsFlyer() {
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: AppConfig.appsFlyerDevKey,
      appId: AppConfig.appsFlyerAppId,
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
      manualStart: true,
    );
    _appsflyerSdk = AppsflyerSdk(options);
    // App open attribution callback
    if (kDebugMode) {
      print('add af');
    }
    _appsflyerSdk!.onAppOpenAttribution((res) {
      if (kDebugMode) {
        print("onAppOpenAttribution res: $res");
      }
    });
    _appsflyerSdk!.setOneLinkCustomDomain(['']);
    // Deep linking callback
    _appsflyerSdk!.onDeepLinking((DeepLinkResult dp) {
      switch (dp.status) {
        case Status.FOUND:
          if (kDebugMode) {
            print(dp.deepLink?.toString());
          }
          if (kDebugMode) {
            print("onDeepLinking res: $dp");
          }

          var map = dp.deepLink!.clickEvent;
          //_convrtsion.addEntries(map as Iterable<MapEntry<String, dynamic>>);
          _convrtsion.addAll(map);
          if (kDebugMode) {
            print(
                'deep_link_value=$deep_link_value deep_link_sub1=$deep_link_sub1|');
          }
          break;
        case Status.NOT_FOUND:
          if (kDebugMode) {
            print("deep link not found");
          }
          break;
        case Status.ERROR:
          if (kDebugMode) {
            print("deep link error: ${dp.error}");
          }
          break;
        case Status.PARSE_ERROR:
          if (kDebugMode) {
            print("deep link status parsing error");
          }
          break;
      }
      if (kDebugMode) {
        print("onDeepLinking res: $dp");
      }
    });

    _appsflyerSdk
        ?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    )
        .then((value) {
      if (kDebugMode) {
        print('_appsflyerSdk initSdk');
      }

      // _appsflyerSdk!
      //     .onDeepLinking((DeepLinkResult dl) => (DeepLinkResult dl) {

      //     });
      _appsflyerSdk?.onInstallConversionData((res) {
        if (kDebugMode) {
          print('=== AppsFlyer onInstallConversionData callback triggered ===');
        }
        
        if (isHasConversion) {
          if (kDebugMode) {
            print('Callback already processed, skipping');
          }
          return;
        }
        isHasConversion = true;
        _appsflyerSdk?.getAppsFlyerUID().then((value) async {
          if (value == null) return;
          Map<String, dynamic> conversionMap = res["payload"];

          if (kDebugMode) {
            print("start load conversion 1");
          }
          if (kDebugMode) {
            print("af_sub2: ${conversionMap['af_sub1']}");
          }

          if (kDebugMode) {
            print(_convrtsion);
          }
          if (kDebugMode) {
            print("start load conversion 2");
          }

          if (kDebugMode) {
            print(conversionMap);
          }

          if (kDebugMode) {
            print("start load conversion 3");
          }

          for (var entry in conversionMap.entries) {
            //if (_convrtsion.containsKey(entry.key)) continue;
            if (entry.value != '') {
              _convrtsion[entry.key] = entry.value;

              if (kDebugMode) {
                print(
                    '|${entry.key} - ${entry.value} |${_convrtsion[entry.key]}');
              }
            }
          }

          // _convrtsion.addAll(conversionMap);
          // _convrtsion
          //     .addEntries(conversionMap as Iterable<MapEntry<String, dynamic>>);
          _convrtsion.addEntries([MapEntry("af_id", value)]);

          setValue('conversionData', _convrtsion);
          var url = await makeConversion(_convrtsion);
          if (kDebugMode) {
            print("url -" + url);
          }
          onEndRequest(url);
        });

        // if (res is Map<dynamic, dynamic>) {
        //    Map<String, dynamic>? conversionMap =(res as Map<dynamic, dynamic>)["asd"];
        // }
      });
      // Starting the SDK with optional success and error callbacks
      _appsflyerSdk?.startSDK(
        onSuccess: () {
          if (kDebugMode) {
            print("AppsFlyer SDK initialized successfully.");
          }
        },
        onError: (int errorCode, String errorMessage) {
          if (kDebugMode) {
            print(options.afDevKey + " " + options.appId);
          }
          if (kDebugMode) {
            print(
              "Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage",
            );
          }
        },
      );
    });
    // Initialization of the AppsFlyer SDK

    // Starting the SDK with optional success and error callbacks
    // AppsFlyerOptions appsFlyerOptions = AppsFlyerOptions(
    //   afDevKey: 'zvxjwZLB7ErfKkprZ9BueZ',
    //   appId: AppConfig.appsFlyerAppId,
    // ); // Optional field

    // _appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
    // _appsflyerSdk!.startSDK(
    //   onSuccess: () {
    //     print("AppsFlyer SDK initialized successfully.");
    //   },
    //   onError: (int errorCode, String errorMessage) {
    //     print(
    //       "Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage",
    //     );
    //   },
    // );
  }

  /// Запрашивает APNS токен через FirebaseMessaging
  static Future<String?> requestAPNSToken() async {
    try {
      // Запрашиваем разрешение на пуш-уведомления (для iOS запрос обязателен)
      await FirebaseMessaging.instance.requestPermission();

      // Убеждаемся, что FCM token получен (это запустит регистрацию и выдачу APNS токена на iOS)
      var token = await FirebaseMessaging.instance.getAPNSToken();
      if (kDebugMode) {
        print("first token");
      }
      if (kDebugMode) {
        print(token);
      }
      if (kDebugMode) {
        print(DefaultFirebaseOptions.currentPlatform.projectId);
      }
      String? apnsToken;
      int retries = 10;
      // Ждём пока APNS токен не станет доступен
      for (int i = 0; i < retries; i++) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          if (kDebugMode) {
            print('APNS токен получен: $apnsToken');
          }
          return apnsToken;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (kDebugMode) {
        print('APNS токен не получен (timeout)');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка при получении APNS токена: $e');
      }
      return null;
    }
  }

  static bool isIOSSimulator() {
    if (!Platform.isIOS) return false;

    // Проверяем переменные окружения симулятора
    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
        Platform.environment.containsKey('SIMULATOR_HOST_HOME') ||
        Platform.environment.containsKey('SIMULATOR_UDID');
  }

  static Future<void> pushRequest(BuildContext context) async {
    // Firebase уже инициализирован в main.dart

    var token = await FirebaseMessagingService.InitPushAndGetToken();

    PushRequestControl.acceptPushRequest(pushRequestData!);

    setValue("pushRequestData", pushRequestData?.toJson());
    _convrtsion = SdkInitializer.getValue('conversionData');
    if (kDebugMode) {
      print("makeConversion 2");
    }
    var url = await SdkInitializer.secondMakeConversion(
      _convrtsion,
      apnsToken: token,
      isLoad: false,
    );
    setValue(url, "receivedUrl");
    if (kDebugMode) {
      print("pushRequest ");
    }
    _runtimeStorage['receivedUrl'] = url;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WebViewScreen()),
      (route) => false,
    );
  }

  static Future<String> secondMakeConversion(
    Map<String, dynamic> conversionMap, {
    String? apnsToken,
    bool isLoad = true,
  }) async {
    conversionMap.addEntries([MapEntry("push_token", apnsToken)]);

    if (kDebugMode) {
      print(conversionMap["firebase_project_id"]);
    }

    if (kDebugMode) {
      print("with token " + conversionMap.toString());
    }
    setValue("", conversionMap);
    var result = await sendPostRequest(
      body: conversionMap,
      url: AppConfig.endpoint + "/config.php",
    );

    // if (isLoad) {
    //   onEndRequest(result);
    // }
    if (result == null) return "";
    setValue('serverResponse', result);
    if (!result.containsKey("url")) return "";
    return result['url'];
  }

  static void pushRequestDecline() {
    PushRequestControl.declinePushRequest(pushRequestData!);
    setValue("pushRequestData", pushRequestData?.toJson());
  }
}

Map<String, dynamic> parseJsonFromString(String jsonString) {
  if (kDebugMode) {
    print("1 " + jsonString);
  }
  String cleanedString = jsonString.trim();
  if (kDebugMode) {
    print("2 " + cleanedString);
  }
  // Парсим JSON строку в Map
  Map<String, dynamic> jsonMap = jsonDecode(cleanedString);

  // print("3 " + jsonMap.length.toString());
  return jsonMap;
}

String mapToJsonString(Map<String, dynamic> map) {
  try {
    // Преобразуем Map в JSON строку с красивым форматированием
    String jsonString = json.encode(map);
    return jsonString;
  } catch (e) {
    if (kDebugMode) {
      print('Ошибка преобразования в JSON: $e');
    }
    return '{}';
  }
}

Future<Map<String, dynamic>?> sendPostRequest({
  required String url,
  required Map<String, dynamic> body,
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (kDebugMode) {
    print(body);
  }
  try {
    // Подготавливаем заголовки
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    // Отправляем POST запрос
    http.Response response = await http
        .post(Uri.parse(url), headers: requestHeaders, body: json.encode(body))
        .timeout(timeout);

    // Проверяем статус ответа
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Успешный ответ
      Map<String, dynamic> result = json.decode(response.body);
      return result;
    } else {
      // Ошибка HTTP
      if (kDebugMode) {
        print('HTTP Error: ${response.statusCode} - ${response.body}');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Ошибка запроса: $e');
    }
    return null;
  }
}
