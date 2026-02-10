import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

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
  /// Does NOT request permission or get token - that happens only when user accepts
  Future<void> init(
      {required LocalNotificationsService localNotificationsService}) async {
    // Init local notifications service
    _localNotificationsService = localNotificationsService;

    // NOTE: We DON'T call getToken() here because on iOS it triggers system permission dialog
    // Token will be obtained only after user accepts on custom push request screen

    // Register handler for background messages (app terminated)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen for messages when the app is in foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Listen for notification taps when the app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check for initial message that opened the app from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('=== Initial message from terminated state: ${initialMessage.data}');
      }
      // Extract URL but don't navigate yet - let initAll() handle navigation
      if (initialMessage.data.containsKey('url')) {
        SdkInitializer.pushURL = initialMessage.data['url'];
        if (kDebugMode) {
          print('=== Saved push URL from terminated state: ${SdkInitializer.pushURL}');
        }
      }
    }
  }

  /// Gets FCM token after user has granted permission
  /// This should only be called AFTER requestPermission() has been called
  static Future<String> getToken() async {
    // Get the FCM token for the device
    // On iOS, this will trigger system permission dialog if not already granted
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      print('Push notifications token: $token');
    }

    // Listen for token refresh events
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      if (kDebugMode) {
        print('FCM token refreshed: $fcmToken');
      }
      // TODO: optionally send token to your server for targeting this device
    }).onError((error) {
      // Handle errors during token refresh

      if (kDebugMode) {
        print('Error refreshing FCM token: $error');
      }
    });

    return token!;
  }

  /// Requests notification permission from the user
  /// This should only be called when user accepts on custom push request screen
  static Future<void> requestPermission() async {
    // Request permission for alerts, badges, and sounds
    final result = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Log the user's permission decision
    if (kDebugMode) {
      print('User granted permission: ${result.authorizationStatus}');
    }
  }

  /// Handles messages received while the app is in the foreground
  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message received: ${message.data.toString()}');
    }
    final notificationData = message.notification;
    if (notificationData != null) {
      // Convert message.data to JSON string for proper parsing in tap handler
      final payload = json.encode(message.data);
      // Display a local notification using the service
      _localNotificationsService?.showNotification(
          notificationData.title, notificationData.body, payload);
    }
  }

  /// Handles notification taps when app is opened from the background or terminated state
  void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('=== PUSH TAP HANDLER ===' );
      print('Full message data: ${message.data.toString()}');
      print('Available keys: ${message.data.keys.toList()}');
    }
    // Extract URL from message data properly
    if (message.data.containsKey('url')) {
      SdkInitializer.pushURL = message.data['url'];
      if (kDebugMode) {
        print('Push URL set to: ${SdkInitializer.pushURL}');
      }
      
      // Trigger navigation to WebView if context is available
      if (SdkInitializer.hasContext()) {
        SdkInitializer.handlePushNavigation(SdkInitializer.getContext()!);
      } else {
        if (kDebugMode) {
          print('Context not available yet, navigation will happen on app resume');
        }
      }
    } else {
      if (kDebugMode) {
        print('WARNING: URL not found in message.data!');
        print('Message data keys: ${message.data.keys.toList()}');
      }
    }
  }

  /// Initializes Firebase Messaging without requesting permissions or token
  /// Call this at app startup to set up listeners
  static Future<void> initialize() async {
    final localNotificationsService = LocalNotificationsService.instance();
    await localNotificationsService.init();

    final firebaseMessagingService = FirebaseMessagingService.instance();
    await firebaseMessagingService.init(
        localNotificationsService: localNotificationsService);
  }
}

/// Background message handler (must be top-level function or static)
/// Handles messages when the app is fully terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received (app terminated): ${message.data.toString()}');
  }
  
  // Note: Cannot save to static variables here when app is fully terminated
  // URL will be retrieved via getInitialMessage() when app starts
}
