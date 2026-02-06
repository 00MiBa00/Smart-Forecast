import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notifications_service.dart';
import 'sdk_initializer.dart';

class FirebaseMessagingService {
  // Private constructor for singleton pattern
  FirebaseMessagingService._internal();

  // Singleton instance
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  // Factory constructor to provide singleton instance
  factory FirebaseMessagingService.instance() => _instance;

  // Reference to local notifications service for displaying notifications
  LocalNotificationsService? _localNotificationsService;

  /// Initialize Firebase Messaging and sets up all message listeners
  Future<String> init({
    required LocalNotificationsService localNotificationsService,
  }) async {
    // Init local notifications service
    _localNotificationsService = localNotificationsService;

    // Handle FCM token (get current token without requesting permission)
    var token = await _handlePushNotificationsToken();

    // NOTE: Permission request (_requestPermission) is NOT called here
    // It will be called manually when user clicks "Yes" on custom push request screen

    // Register handler for background messages (app terminated)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen for messages when the app is in foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Listen for notification taps when the app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check for initial message that opened the app from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }
    return token;
  }

  /// Retrieves and manages the FCM token for push notifications
  Future<String> _handlePushNotificationsToken() async {
    // Get the FCM token for the device
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      print('Push notifications token: $token');
    }

    // Listen for token refresh events
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) {
          if (kDebugMode) {
            print('FCM token refreshed: $fcmToken');
          }
          // TODO: optionally send token to your server for targeting this device
        })
        .onError((error) {
          // Handle errors during token refresh

          if (kDebugMode) {
            print('Error refreshing FCM token: $error');
          }
        });

    return token!;
  }

  /// Requests notification permission from the user
  /// This should be called when user explicitly agrees to receive notifications
  Future<void> requestPermission() async {
    if (kDebugMode) {
      print('Requesting notification permission from user...');
    }
    // Request permission for alerts, badges, and sounds
    final result = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Log the user's permission decision
    if (kDebugMode) {
      print('User permission result: ${result.authorizationStatus}');
    }
  }

  /// Handles messages received while the app is in the foreground
  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message received: ${message.data.toString()}');
    }
    final notificationData = message.notification;
    if (notificationData != null) {
      // Extract URL from message data
      final url = message.data['url'] ?? '';
      if (kDebugMode) {
        print('Extracted URL from foreground push: $url');
      }
      // Display a local notification with URL as payload
      _localNotificationsService?.showNotification(
        notificationData.title,
        notificationData.body,
        url, // Pass URL, not entire data.toString()
      );
    }
  }

  /// Handles notification taps when app is opened from the background or terminated state
  void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print(
        '=== Notification tapped (app in background) ===',
      );
      print('Message data: ${message.data.toString()}');
    }
    final url = message.data['url'];
    if (url != null && url.isNotEmpty) {
      SdkInitializer.pushURL = url;
      if (kDebugMode) {
        print('Push URL set to: $url');
      }
      // Trigger navigation if context is available
      // For background state, need to wait a bit for app to come to foreground
      Future.delayed(const Duration(milliseconds: 300), () {
        if (kDebugMode) {
          print('Attempting navigation with pushURL: $url');
        }
        SdkInitializer.handlePushNavigation();
      });
    } else {
      if (kDebugMode) {
        print('WARNING: No URL found in push notification data');
      }
    }
  }

  static Future<String> InitPushAndGetToken() async {
    final localNotificationsService = LocalNotificationsService.instance();
    await localNotificationsService.init();

    final firebaseMessagingService = FirebaseMessagingService.instance();
    var token = await firebaseMessagingService.init(
      localNotificationsService: localNotificationsService,
    );

    return token;
  }
}

/// Background message handler (must be top-level function or static)
/// Handles messages when the app is fully terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received: ${message.data.toString()}');
  }
}
