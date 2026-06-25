// lib/services/leave_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_config.dart'; // ✅ Import AppConfig
import '../models/leave_request_model.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Get current school ID from AppConfig
  String get _schoolId => AppConfig.schoolId;

  // ✅ Get the correct collection path using AppConfig
  CollectionReference _getLeaveCollection(String userId) {
    return _firestore
        .collection(AppConfig.schoolsCollection)
        .doc(_schoolId)
        .collection(AppConfig.teachersCollection)
        .doc(userId)
        .collection('leave_requests');
  }

  // ✅ Submit leave request with school path
  Future<void> submitLeaveRequest(LeaveRequest request) async {
    try {
      final collection = _getLeaveCollection(request.teacherId);
      final docRef = collection.doc();

      final Map<String, Object> data = {
        'id': docRef.id,
        'teacherId': request.teacherId,
        'teacherName': request.teacherName,
        'teacherEmail': request.teacherEmail,
        'teacherClass': request.teacherClass ?? '',
        'teacherSubject': request.teacherSubject ?? '',
        'leaveType': request.leaveType,
        'fromDate': Timestamp.fromDate(request.fromDate),
        'toDate': Timestamp.fromDate(request.toDate),
        'days': request.days,
        'reason': request.reason,
        'documentUrl': request.documentUrl ?? '',
        'status': request.status,
        'appliedAt': Timestamp.fromDate(request.appliedAt),
        'createdAt': Timestamp.fromDate(request.createdAt),
        'updatedAt': Timestamp.fromDate(request.updatedAt),
        'schoolId': _schoolId, // ✅ Use AppConfig
      };

      await docRef.set(data);
    } catch (e) {
      throw Exception('Failed to submit leave request: $e');
    }
  }

  // ✅ Get leave requests for a specific teacher
  Stream<QuerySnapshot> getTeacherLeaveRequests(String teacherId) {
    try {
      final collection = _getLeaveCollection(teacherId);
      return collection
          .orderBy('appliedAt', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting teacher leave requests: $e');
      return Stream.empty();
    }
  }

  // ✅ Get ALL leave requests for the school using collection group
  Stream<QuerySnapshot> getSchoolLeaveRequests() {
    try {
      // ✅ Use collectionGroup to query across all teachers
      return FirebaseFirestore.instance
          .collectionGroup('leave_requests')
          .where('schoolId', isEqualTo: _schoolId)
          .orderBy('appliedAt', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting school leave requests: $e');
      return Stream.empty();
    }
  }

  // ✅ Get filtered leave requests
  Stream<QuerySnapshot> getFilteredLeaveRequests(String filter) {
    try {
      Query query = FirebaseFirestore.instance
          .collectionGroup('leave_requests')
          .where('schoolId', isEqualTo: _schoolId)
          .orderBy('appliedAt', descending: true);

      if (filter != 'all') {
        query = query.where('status', isEqualTo: filter);
      }

      return query.snapshots();
    } catch (e) {
      print('Error getting filtered leave requests: $e');
      return Stream.empty();
    }
  }

  // ✅ Get leave balance
  Future<Map<String, dynamic>> getLeaveBalance(String teacherId) async {
    try {
      final collection = _getLeaveCollection(teacherId);

      // Get current academic year
      final year = DateTime.now().year;
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);

      // Get approved leaves for this year
      final approvedLeaves = await collection
          .where('status', isEqualTo: 'approved')
          .where('fromDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('toDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Calculate used days per leave type
      final usedDays = <String, int>{};
      for (final doc in approvedLeaves.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['leaveType'] ?? 'Casual Leave';
        final days = (data['days'] ?? 1) as int;
        usedDays[type] = (usedDays[type] ?? 0) + days;
      }

      // Define leave balances (could come from school settings)
      const leaveBalances = {
        'Casual Leave': 12,
        'Sick Leave': 10,
        'Earned Leave': 15,
      };

      final result = <String, dynamic>{};
      for (final entry in leaveBalances.entries) {
        final total = entry.value;
        final used = usedDays[entry.key] ?? 0;
        final remaining = total - used;
        result[entry.key] = {
          'total': total,
          'used': used,
          'remaining': remaining > 0 ? remaining : 0,
        };
      }

      return {
        'leaveTypes': result,
        'totalUsed': usedDays.values.fold(0, (sum, val) => sum + val),
      };
    } catch (e) {
      print('Error getting leave balance: $e');
      return {
        'leaveTypes': {
          'Casual Leave': {'total': 12, 'used': 0, 'remaining': 12},
          'Sick Leave': {'total': 10, 'used': 0, 'remaining': 10},
          'Earned Leave': {'total': 15, 'used': 0, 'remaining': 15},
        },
        'totalUsed': 0,
      };
    }
  }

  // ✅ Check if teacher can apply
  Future<bool> canApplyLeave(String teacherId, String leaveType, int days) async {
    final balance = await getLeaveBalance(teacherId);
    final typeBalance = balance['leaveTypes']?[leaveType];
    if (typeBalance == null) return false;
    final remaining = typeBalance['remaining'] as int;
    return remaining >= days;
  }

  // ✅ Update leave status
  Future<void> updateLeaveStatus(
      String teacherId,
      String leaveId,
      String status, {
        String? rejectionReason,
      }) async {
    try {
      final collection = _getLeaveCollection(teacherId);

      final Map<String, Object> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'approved') {
        updateData['approvedAt'] = FieldValue.serverTimestamp();
        updateData['approvedBy'] = _auth.currentUser?.uid ?? 'unknown';
      } else if (status == 'rejected') {
        updateData['rejectedAt'] = FieldValue.serverTimestamp();
        updateData['rejectedBy'] = _auth.currentUser?.uid ?? 'unknown';
        if (rejectionReason != null) {
          updateData['rejectionReason'] = rejectionReason;
        }
      }

      await collection.doc(leaveId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update leave status: $e');
    }
  }

  // ✅ Get a single leave request
  Future<Map<String, dynamic>?> getLeaveRequest(String teacherId, String leaveId) async {
    try {
      final collection = _getLeaveCollection(teacherId);
      final doc = await collection.doc(leaveId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting leave request: $e');
      return null;
    }
  }
}