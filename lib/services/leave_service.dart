// lib/services/leave_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leave_request_model.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit leave request
  Future<void> submitLeaveRequest(LeaveRequest request) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Add to Firestore
      final docRef = await _firestore.collection('leave_requests').add({
        ...request.toMap(),
        'teacherId': user.uid,
        'appliedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update leave balance
      await _updateLeaveBalance(user.uid, request.leaveType, request.days);

      // Send notification to admin
      await _notifyAdmins(request);

      return;
    } catch (e) {
      throw Exception('Failed to submit leave request: $e');
    }
  }

  // Get teacher's leave balance
  Future<Map<String, dynamic>> getLeaveBalance(String teacherId) async {
    try {
      final doc = await _firestore
          .collection('teacher_leave_balance')
          .doc(teacherId)
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      } else {
        // Initialize default balance
        final defaultBalance = {
          'Casual Leave': {'total': 12, 'used': 0, 'remaining': 12},
          'Sick Leave': {'total': 8, 'used': 0, 'remaining': 8},
          'Earned Leave': {'total': 15, 'used': 0, 'remaining': 15},
        };

        await _firestore
            .collection('teacher_leave_balance')
            .doc(teacherId)
            .set({
          'teacherId': teacherId,
          'academicYear': '2026-2027',
          'leaveTypes': defaultBalance,
        });

        return {'leaveTypes': defaultBalance};
      }
    } catch (e) {
      throw Exception('Failed to get leave balance: $e');
    }
  }

  // Update leave balance
  Future<void> _updateLeaveBalance(String teacherId, String leaveType, int days) async {
    try {
      final docRef = _firestore
          .collection('teacher_leave_balance')
          .doc(teacherId);

      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        final leaveTypes = Map<String, dynamic>.from(data['leaveTypes'] ?? {});

        if (leaveTypes.containsKey(leaveType)) {
          final balance = Map<String, dynamic>.from(leaveTypes[leaveType]);
          balance['used'] = (balance['used'] ?? 0) + days;
          balance['remaining'] = (balance['total'] ?? 0) - (balance['used'] ?? 0);
          leaveTypes[leaveType] = balance;

          await docRef.update({
            'leaveTypes': leaveTypes,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update leave balance: $e');
    }
  }

  // Get teacher's leave history
  Stream<List<LeaveRequest>> getLeaveHistory(String teacherId) {
    return _firestore
        .collection('leave_requests')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LeaveRequest.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Cancel leave request
  Future<void> cancelLeaveRequest(String requestId) async {
    try {
      await _firestore
          .collection('leave_requests')
          .doc(requestId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel leave request: $e');
    }
  }

  // Notify admins
  Future<void> _notifyAdmins(LeaveRequest request) async {
    try {
      // Get all admin FCM tokens
      final admins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (var admin in admins.docs) {
        final fcmToken = admin.data()['fcmToken'];

        if (fcmToken != null && fcmToken.isNotEmpty) {
          // Send notification using Firebase Cloud Messaging
          await _firestore.collection('notifications').add({
            'userId': admin.id,
            'type': 'leave_request',
            'title': '📞 Leave Request from ${request.teacherName}',
            'body': '${request.leaveType} - ${request.days} days from ${request.fromDate.day}/${request.fromDate.month}',
            'data': {
              'requestId': request.id,
              'teacherName': request.teacherName,
              'leaveType': request.leaveType,
              'fromDate': request.fromDate.toIso8601String(),
              'toDate': request.toDate.toIso8601String(),
              'days': request.days.toString(),
            },
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Failed to notify admins: $e');
    }
  }

  // Check if leave can be applied
  Future<bool> canApplyLeave(String teacherId, String leaveType, int days) async {
    try {
      final balance = await getLeaveBalance(teacherId);
      final leaveTypes = balance['leaveTypes'] ?? {};

      if (leaveTypes.containsKey(leaveType)) {
        final remaining = leaveTypes[leaveType]['remaining'] ?? 0;
        return remaining >= days;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}