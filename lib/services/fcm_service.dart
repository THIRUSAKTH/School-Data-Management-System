import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:js' as js;
import '../app_config.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin? _localNotifications;

  static Future<void> initialize() async {
    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeMobile();
    }
  }

  // ==================== WEB INITIALIZATION ====================
  static Future<void> _initializeWeb() async {
    try {
      // Request permission for web notifications
      final NotificationSettings settings = await _fcm.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Web notification permission granted');

        // Get FCM token with VAPID key
        String? token = await _fcm.getToken(
          vapidKey: 'YOUR_VAPID_KEY_HERE', // Get from Firebase Console
        );
        print('📱 Web FCM Token: $token');
        await _saveToken(token);

        // Listen to token refresh
        _fcm.onTokenRefresh.listen((newToken) async {
          await _saveToken(newToken);
        });
      } else {
        print('❌ Web notification permission denied');
      }

      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen(_handleMessage);

      // Handle when user clicks on notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
    } catch (e) {
      print('Error initializing web FCM: $e');
    }
  }

  // ==================== MOBILE INITIALIZATION ====================
  static Future<void> _initializeMobile() async {
    // Request permissions for mobile
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('❌ Mobile notification permission denied');
      return;
    }

    // Initialize local notifications for mobile
    _localNotifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications?.initialize(initSettings);

    // Get FCM token for mobile
    String? token = await _fcm.getToken();
    print('📱 Mobile FCM Token: $token');
    await _saveToken(token);

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      await _saveToken(newToken);
    });

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // Handle when user clicks on notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    // Handle background messages (Android/iOS only)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // ==================== TOKEN MANAGEMENT ====================
  static Future<void> _saveToken(String? token) async {
    if (token == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('users')
        .doc(userId)
        .set({
          'fcmToken': token,
          'platform': kIsWeb ? 'web' : 'mobile',
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // ==================== MESSAGE HANDLERS ====================
  static Future<void> _handleMessage(RemoteMessage message) async {
    print('📨 Received message: ${message.notification?.title}');

    final title = message.notification?.title ?? 'School Notification';
    final body = message.notification?.body ?? '';
    final data = message.data;

    if (kIsWeb) {
      // Show web notification using browser API
      _showWebNotification(title, body, data);
    } else {
      // Show mobile local notification
      await _showMobileNotification(title, body, data);
    }
  }

  static void _handleMessageOpen(RemoteMessage message) {
    print('🔔 Notification clicked: ${message.data}');
    _handleNotificationClick(message.data);
  }

  // ==================== WEB NOTIFICATION (FULLY CORRECTED) ====================
  static void _showWebNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    if (!kIsWeb) return;

    // Check if browser notifications are supported
    if (!html.Notification.supported) {
      print('Web notifications not supported');
      return;
    }

    // Request permission if not already granted
    if (html.Notification.permission != 'granted') {
      html.Notification.requestPermission().then((permission) {
        if (permission == 'granted') {
          _showWebNotification(title, body, data);
        }
      });
      return;
    }

    try {
      // Create the notification
      final notification = html.Notification(
        title,
        body: body,
        icon: '/icons/Icon-192.png',
      );

      // Handle click event using addEventListener (correct way for HTML Notification)
      notification.addEventListener('click', (event) {
        notification.close();
        // Focus or open the app window
        if (js.context.hasProperty('window')) {
          js.context.callMethod('focus');
        }
        _handleNotificationClick(data);
      });
    } catch (e) {
      print('Error showing web notification: $e');
    }
  }

  // ==================== MOBILE NOTIFICATION ====================
  static Future<void> _showMobileNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    if (_localNotifications == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'school_channel',
          'School Notifications',
          channelDescription: 'Important school updates and announcements',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications?.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  // ==================== HANDLE NOTIFICATION CLICK ====================
  static void _handleNotificationClick(Map<String, dynamic> data) {
    final String type = data['type'] ?? 'general';
    final String? studentId = data['studentId'];

    print('Navigate to: $type page for student: $studentId');

    // You can add navigation logic here based on your app structure
    // Example using a GlobalKey navigator:
    // if (type == 'notice') {
    //   navigatorKey.currentState?.pushNamed('/notices');
    // }
  }
}

// ==================== BACKGROUND HANDLER (Mobile Only) ====================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Handling background message: ${message.messageId}');
  await Firebase.initializeApp();
  print('Background message title: ${message.notification?.title}');
}
