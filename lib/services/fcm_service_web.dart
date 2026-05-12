// WEB ONLY - This file is only used when running on web
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_config.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      final NotificationSettings settings = await _fcm.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Web notification permission granted');

        String? token = await _fcm.getToken(
          vapidKey: 'YOUR_VAPID_KEY_HERE',
        );
        print('📱 Web FCM Token: $token');
        await _saveToken(token);

        _fcm.onTokenRefresh.listen((newToken) async {
          await _saveToken(newToken);
        });
      } else {
        print('❌ Web notification permission denied');
      }

      FirebaseMessaging.onMessage.listen(_handleMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
    } catch (e) {
      print('Error initializing web FCM: $e');
    }
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
      'platform': 'web',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static void _handleMessage(RemoteMessage message) {
    print('📨 Received web message: ${message.notification?.title}');
    _showWebNotification(
      message.notification?.title ?? 'School Notification',
      message.notification?.body ?? '',
      message.data,
    );
  }

  static void _handleMessageOpen(RemoteMessage message) {
    print('🔔 Web notification clicked: ${message.data}');
  }

  static void _showWebNotification(String title, String body, Map<String, dynamic> data) {
    if (!html.Notification.supported) {
      print('Web notifications not supported');
      return;
    }

    if (html.Notification.permission != 'granted') {
      html.Notification.requestPermission();
      return;
    }

    try {
      final notification = html.Notification(title, body: body, icon: '/icons/Icon-192.png');
      notification.addEventListener('click', (event) {
        notification.close();
        if (js.context.hasProperty('window')) {
          js.context.callMethod('focus');
        }
      });
    } catch (e) {
      print('Error showing web notification: $e');
    }
  }
}