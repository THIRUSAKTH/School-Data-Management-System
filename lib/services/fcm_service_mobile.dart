// MOBILE ONLY - For Android and iOS
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_config.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin? _localNotifications;

  static Future<void> initialize() async {
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
      'platform': 'mobile',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> _handleMessage(RemoteMessage message) async {
    print('📨 Received mobile message: ${message.notification?.title}');

    final title = message.notification?.title ?? 'School Notification';
    final body = message.notification?.body ?? '';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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

  static void _handleMessageOpen(RemoteMessage message) {
    print('🔔 Mobile notification clicked: ${message.data}');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Handling background message: ${message.messageId}');
  await Firebase.initializeApp();
  print('Background message title: ${message.notification?.title}');
}