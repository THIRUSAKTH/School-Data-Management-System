import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../app_config.dart';

// Conditional web imports - these will be tree-shaken on mobile
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html

if
(
dart.library.html) 'dart:html';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js if (dart.library.html) 'dart:js';

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

static Future<void> _initializeWeb() async {
// Only execute if web libraries are available
// ignore: undefined_identifier
if (html.Notification.supported) {
// Web notification code here
print('Web notification initialization');
}
}

static Future<void> _initializeMobile() async {
// Mobile notification code here (no html/js imports)
NotificationSettings settings = await _fcm.requestPermission(
alert: true,
badge: true,
sound: true,
);

if (settings.authorizationStatus != AuthorizationStatus.authorized) {
print('❌ Mobile notification permission denied');
return;
}

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

String? token = await _fcm.getToken();
print('📱 Mobile FCM Token: $token');
await _saveToken(token);

_fcm.onTokenRefresh.listen((newToken) async {
await _saveToken(newToken);
});

FirebaseMessaging.onMessage.listen(_handleMobileMessage);
FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
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
'platform': kIsWeb ? 'web' : 'mobile',
'lastUpdated': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
}

static Future<void> _handleMobileMessage(RemoteMessage message) async {
print('📨 Received message: ${message.notification?.title}');

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
print('🔔 Notification clicked: ${message.data}');
}
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
print('📨 Handling background message: ${message.messageId}');
await Firebase.initializeApp();
print('Background message title: ${message.notification?.title}');
}