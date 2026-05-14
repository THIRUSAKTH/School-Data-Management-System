import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_config.dart';

class NotificationService {
  // Send notification to a specific user by their UID
  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 Sending to user: $userId');

      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('users')
          .doc(userId)
          .get();

      final token = userDoc.data()?['fcmToken'];

      if (token == null || token.isEmpty) {
        print('❌ No FCM token for user: $userId');
        return;
      }

      print('✅ Token found: ${token.substring(0, 20)}...');

      // Add to notification queue for Cloud Function to process
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notification_queue')
          .add({
        'token': token,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('✅ Notification queued for user: $userId');
    } catch (e) {
      print('❌ Error sending notification to user: $e');
    }
  }

  // Send notification to all parents
  static Future<void> sendToAllParents({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📢 Sending to all parents...');

      // Get all students - NOTE: using 'parentUID' (capital UID) to match Firestore
      final students = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .get();

      print('📚 Found ${students.docs.length} students');

      final Set<String> parentUids = {};
      for (var doc in students.docs) {
        final parentUid = doc.data()['parentUID']; // ← CHANGED: capital UID
        if (parentUid != null && parentUid.isNotEmpty) {
          parentUids.add(parentUid);
          print('👨‍👩‍👧 Student has parent: $parentUid');
        } else {
          print('⚠️ Student ${doc.id} has no parentUID');
        }
      }

      print('👪 Found ${parentUids.length} unique parents');

      // Send notification to each parent
      for (var parentUid in parentUids) {
        await sendToUser(
          userId: parentUid,
          title: title,
          body: body,
          type: type,
          data: data,
        );
      }

      print('✅ Notifications queued for ${parentUids.length} parents');
    } catch (e) {
      print('❌ Error sending to all parents: $e');
    }
  }

  // Send notification to all teachers
  static Future<void> sendToAllTeachers({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('👨‍🏫 Sending to all teachers...');

      final teachers = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('teachers')
          .get();

      print('📚 Found ${teachers.docs.length} teachers');

      for (var doc in teachers.docs) {
        final teacherUid = doc.data()['uid'];
        if (teacherUid != null && teacherUid.isNotEmpty) {
          await sendToUser(
            userId: teacherUid,
            title: title,
            body: body,
            type: type,
            data: data,
          );
        }
      }

      print('✅ Notifications queued for ${teachers.docs.length} teachers');
    } catch (e) {
      print('❌ Error sending to all teachers: $e');
    }
  }

  // Send notification to specific class parents
  static Future<void> sendToClass({
    required String className,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📚 Sending to class: $className');

      final students = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .where('class', isEqualTo: className)
          .get();

      final Set<String> parentUids = {};
      for (var doc in students.docs) {
        final parentUid = doc.data()['parentUID']; // ← CHANGED: capital UID
        if (parentUid != null && parentUid.isNotEmpty) {
          parentUids.add(parentUid);
        }
      }

      for (var parentUid in parentUids) {
        await sendToUser(
          userId: parentUid,
          title: title,
          body: body,
          type: type,
          data: {...?data, 'className': className},
        );
      }

      print('✅ Notifications queued for ${parentUids.length} parents in class $className');
    } catch (e) {
      print('❌ Error sending to class: $e');
    }
  }
}