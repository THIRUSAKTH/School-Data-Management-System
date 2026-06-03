import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app_config.dart';

class NotificationService {
  // Send notification to a specific user by their UID
  static Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 Sending to user: $userId');
      print('   Title: $title');
      print('   Body: $body');

      // Get user's FCM token - try multiple collections
      String? token;

      // Try 1: schools/users collection
      final schoolUserDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('users')
          .doc(userId)
          .get();

      if (schoolUserDoc.exists) {
        token = schoolUserDoc.data()?['fcmToken'] as String?;
        print('   ✅ Token found in schools/users');
      }

      // Try 2: parents collection
      if (token == null || token.isEmpty) {
        final parentDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('parents')
            .doc(userId)
            .get();

        if (parentDoc.exists) {
          token = parentDoc.data()?['fcmToken'] as String?;
          print('   ✅ Token found in parents');
        }
      }

      // Try 3: users collection (root)
      if (token == null || token.isEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          token = userDoc.data()?['fcmToken'] as String?;
          print('   ✅ Token found in root users');
        }
      }

      if (token == null || token.isEmpty) {
        print('❌ No FCM token found for user: $userId');

        // Still create in-app notification
        await _createInAppNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
        );

        return false;
      }

      print('✅ Token found: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      // Queue notification for processing
      await _queueNotification(
        token: token,
        title: title,
        body: body,
        type: type,
        data: data,
        userId: userId,
      );

      // Create in-app notification
      await _createInAppNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );

      print('✅ Notification queued for user: $userId');
      return true;

    } catch (e) {
      print('❌ Error sending notification to user: $e');
      return false;
    }
  }

  // Queue notification for Cloud Function or direct processing
  static Future<void> _queueNotification({
    required String token,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? userId,
  }) async {
    try {
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
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'retryCount': 0,
      });
      print('📋 Notification added to queue');
    } catch (e) {
      print('❌ Error queueing notification: $e');
    }
  }

  // Create in-app notification
  static Future<void> _createInAppNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notifications')
          .add({
        'userId': userId,
        'title': title,
        'message': body,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'deletedFor': [],
        'additionalData': data ?? {},
      });
      print('📱 In-app notification created');
    } catch (e) {
      print('❌ Error creating in-app notification: $e');
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

      final students = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .get();

      print('📚 Found ${students.docs.length} students');

      final Set<String> parentUids = {};
      for (var doc in students.docs) {
        // Try multiple field name variations
        String? parentUid = doc.data()['parentUID'] as String?;
        if (parentUid == null || parentUid.isEmpty) {
          parentUid = doc.data()['parentUid'] as String?;
        }
        if (parentUid == null || parentUid.isEmpty) {
          parentUid = doc.data()['parentId'] as String?;
        }

        if (parentUid != null && parentUid.isNotEmpty) {
          parentUids.add(parentUid);
          print('👨‍👩‍👧 Student ${doc.id} → Parent: $parentUid');
        } else {
          print('⚠️ Student ${doc.id} has no parent UID');
        }
      }

      print('👪 Found ${parentUids.length} unique parents');

      int successCount = 0;
      for (var parentUid in parentUids) {
        final success = await sendToUser(
          userId: parentUid,
          title: title,
          body: body,
          type: type,
          data: data,
        );
        if (success) successCount++;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('✅ Notifications - Success: $successCount, Failed: ${parentUids.length - successCount}');
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

      int successCount = 0;
      for (var doc in teachers.docs) {
        final teacherUid = doc.data()['uid'] as String?;
        if (teacherUid != null && teacherUid.isNotEmpty) {
          final success = await sendToUser(
            userId: teacherUid,
            title: title,
            body: body,
            type: type,
            data: data,
          );
          if (success) successCount++;
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      print('✅ Notifications sent to $successCount teachers');
    } catch (e) {
      print('❌ Error sending to all teachers: $e');
    }
  }

  // Send notification to specific class parents
  static Future<void> sendToClass({
    required String className,
    String? section,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📚 Sending to class: $className ${section ?? ''}');

      var query = FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .where('class', isEqualTo: className);

      if (section != null && section.isNotEmpty) {
        query = query.where('section', isEqualTo: section);
      }

      final students = await query.get();

      final Set<String> parentUids = {};
      for (var doc in students.docs) {
        String? parentUid = doc.data()['parentUID'] as String?;
        if (parentUid == null || parentUid.isEmpty) {
          parentUid = doc.data()['parentUid'] as String?;
        }
        if (parentUid != null && parentUid.isNotEmpty) {
          parentUids.add(parentUid);
        }
      }

      int successCount = 0;
      for (var parentUid in parentUids) {
        final success = await sendToUser(
          userId: parentUid,
          title: title,
          body: body,
          type: type,
          data: {...?data, 'className': className, 'section': section},
        );
        if (success) successCount++;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('✅ Notifications sent to $successCount parents in class $className');
    } catch (e) {
      print('❌ Error sending to class: $e');
    }
  }

  // Send notification to a single student's parent
  static Future<void> sendToStudentParent({
    required String studentId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📚 Sending to parent of student: $studentId');

      final studentDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .doc(studentId)
          .get();

      if (!studentDoc.exists) {
        print('❌ Student not found: $studentId');
        return;
      }

      String? parentUid = studentDoc.data()?['parentUID'] as String?;
      if (parentUid == null || parentUid.isEmpty) {
        parentUid = studentDoc.data()?['parentUid'] as String?;
      }

      if (parentUid == null || parentUid.isEmpty) {
        print('❌ No parent UID found for student: $studentId');
        return;
      }

      await sendToUser(
        userId: parentUid,
        title: title,
        body: body,
        type: type,
        data: {...?data, 'studentId': studentId},
      );

      print('✅ Notification sent to parent of student: $studentId');
    } catch (e) {
      print('❌ Error sending to student parent: $e');
    }
  }
}