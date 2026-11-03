import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [FCM Background Message] Title: ${message.notification?.title}, Data: ${message.data}');
}

class FcmNotificationService {
  FcmNotificationService._privateConstructor();
  static final FcmNotificationService instance = FcmNotificationService._privateConstructor();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _cachedToken;
  String? get currentToken => _cachedToken;

  static const String channelId = 'bharat_pray_notifications';
  static const String channelName = 'Bharat Pray Sacred Notifications';
  static const String channelDescription = 'Notifications for Live Darshan, Daily Jap, Yatra, and Sacred Events';

  /// Initialize Firebase Messaging & Local Notification channels
  Future<void> initialize() async {
    try {
      // 1. Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Request user permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('🔔 [FCM Permission Status]: ${settings.authorizationStatus}');

      // 3. Setup Android notification channel for heads-up notifications
      const androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 4. Initialize Local Notifications Plugin
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _handleNotificationClick(response.payload!);
          }
        },
      );

      // 5. Retrieve device token
      await getDeviceToken();

      // 6. Listen for Token Refreshes
      _fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 [FCM Token Refreshed]: $newToken');
        _cachedToken = newToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_device_token', newToken);

        // If user is logged in, sync new token with backend
        final authToken = prefs.getString('auth_token') ?? prefs.getString('token');
        if (authToken != null && authToken.isNotEmpty) {
          try {
            await ApiService.updateFcmToken(newToken);
            debugPrint('✅ [FCM] Synced refreshed token with backend');
          } catch (e) {
            debugPrint('⚠️ [FCM] Failed to sync refreshed token: $e');
          }
        }
      });

      // 7. Foreground message listener (Shows banner when app is active)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM Foreground Message]: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // 8. Background tap listener (App was in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM Opened From Background]: ${message.data}');
        _handleRemoteMessageClick(message);
      });

      // 9. Terminated tap listener (App was closed)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 [FCM Initial Message (Terminated)]: ${initialMessage.data}');
        _handleRemoteMessageClick(initialMessage);
      }
    } catch (e) {
      debugPrint('⚠️ [FCM Notification Service Error]: $e');
    }
  }

  /// Get device FCM token (retrieves from Firebase or cached in SharedPreferences)
  Future<String?> getDeviceToken() async {
    try {
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        return _cachedToken;
      }

      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('fcm_device_token');

      final freshToken = await _fcm.getToken();
      if (freshToken != null && freshToken.isNotEmpty) {
        _cachedToken = freshToken;
        await prefs.setString('fcm_device_token', freshToken);
        debugPrint('🔥 [FCM Device Token Retrieved]: $freshToken');
      }

      return _cachedToken;
    } catch (e) {
      debugPrint('⚠️ [FCM getToken Error]: $e');
      return _cachedToken;
    }
  }

  /// Display banner notification when message arrives in Foreground
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Bharat Pray',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleRemoteMessageClick(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      _handleNotificationClick(jsonEncode(message.data));
    }
  }

  void _handleNotificationClick(String payloadJson) {
    try {
      final data = jsonDecode(payloadJson) as Map<String, dynamic>;
      final targetScreen = data['action_screen']?.toString() ?? data['screen']?.toString() ?? '';
      debugPrint('🎯 [FCM Notification Click Action Screen]: $targetScreen');
      // Navigation handler callback can be attached from UI layer if needed
    } catch (e) {
      debugPrint('⚠️ [FCM Payload Decode Error]: $e');
    }
  }
}
