import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_config.dart';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save attendance for a class
  static Future<bool> saveAttendance({
    required String schoolId,
    required String className,
    required String section,
    required DateTime date,
    required Map<String, Map<String, dynamic>> attendanceData,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final batch = _firestore.batch();

      for (var entry in attendanceData.entries) {
        final studentId = entry.key;
        final data = entry.value;

        final docRef = _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('attendance')
            .doc(dateStr)
            .collection('records')
            .doc(studentId);

        final recordData = {
          'studentId': studentId,
          'studentName': data['studentName'] ?? '',
          'rollNo': data['rollNo'] ?? '',
          'className': className,
          'section': section,
          'date': dateStr,
          'status': data['status'] ?? 'Absent',
          'remark': data['remark'] ?? '',
          'checkInTime': data['checkInTime'] ?? '',
          'checkOutTime': data['checkOutTime'] ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': data['updatedBy'] ?? '',
        };

        batch.set(docRef, recordData);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      return false;
    }
  }

  // Get attendance for a student (using collection group)
  static Future<List<Map<String, dynamic>>> getStudentAttendance(
    String studentId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collectionGroup('records')
              .where('studentId', isEqualTo: studentId)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'date': data['date'] ?? '',
          'status': data['status'] ?? 'Absent',
          'remark': data['remark'] ?? '',
          'checkInTime': data['checkInTime'] ?? '',
          'checkOutTime': data['checkOutTime'] ?? '',
          'className': data['className'] ?? '',
          'section': data['section'] ?? '',
          'studentName': data['studentName'] ?? '',
          'rollNo': data['rollNo'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting student attendance: $e');
      return [];
    }
  }

  // Get attendance for a specific date and class
  static Future<List<Map<String, dynamic>>> getClassAttendance({
    required String schoolId,
    required String className,
    required String section,
    required DateTime date,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final snapshot =
          await _firestore
              .collection('schools')
              .doc(schoolId)
              .collection('attendance')
              .doc(dateStr)
              .collection('records')
              .where('className', isEqualTo: className)
              .where('section', isEqualTo: section)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'studentId': doc.id,
          'studentName': data['studentName'] ?? '',
          'rollNo': data['rollNo'] ?? '',
          'status': data['status'] ?? 'Absent',
          'remark': data['remark'] ?? '',
          'checkInTime': data['checkInTime'] ?? '',
          'checkOutTime': data['checkOutTime'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting class attendance: $e');
      return [];
    }
  }

  // Get attendance statistics
  static Map<String, dynamic> getAttendanceStats(
    List<Map<String, dynamic>> records,
  ) {
    int present = records.where((r) => r['status'] == 'Present').length;
    int absent = records.where((r) => r['status'] == 'Absent').length;
    int late = records.where((r) => r['status'] == 'Late').length;
    int total = present + absent + late;
    double percentage = total > 0 ? (present / total) * 100 : 0;

    return {
      'present': present,
      'absent': absent,
      'late': late,
      'total': total,
      'percentage': percentage.toStringAsFixed(1),
    };
  }

  // Group attendance by month
  static Map<String, List<Map<String, dynamic>>> groupByMonth(
    List<Map<String, dynamic>> records,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var record in records) {
      final date = record['date'];
      if (date.toString().length >= 7) {
        final month = date.toString().substring(0, 7);
        if (!grouped.containsKey(month)) {
          grouped[month] = [];
        }
        grouped[month]!.add(record);
      }
    }

    return grouped;
  }
}
