import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../app_config.dart';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mark attendance for a class
  static Future<Map<String, dynamic>> markAttendance({
    required String classId,
    required String section,
    required String date,
    required List<Map<String, dynamic>> studentsAttendance,
    String? notes,
  }) async {
    try {
      final attendanceRef = _firestore
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('attendance')
          .doc(date)
          .collection('records');

      final batch = _firestore.batch();

      for (var student in studentsAttendance) {
        final studentId = student['studentId'];
        final status = student['status']; // 'present', 'absent', 'late'
        final checkInTime = student['checkInTime'];
        final checkOutTime = student['checkOutTime'];

        final docRef = attendanceRef.doc(studentId);
        batch.set(docRef, {
          'studentId': studentId,
          'classId': classId,
          'section': section,
          'date': date,
          'status': status,
          'checkInTime': checkInTime ?? FieldValue.serverTimestamp(),
          'checkOutTime': checkOutTime,
          'markedBy': FirebaseAuth.instance.currentUser?.uid,
          'markedAt': FieldValue.serverTimestamp(),
          'notes': notes ?? '',
          'isHoliday': false,
        });
      }

      await batch.commit();
      return {'success': true, 'message': 'Attendance marked successfully'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get attendance for a specific date and class
  static Future<List<Map<String, dynamic>>> getAttendanceByDate({
    required String classId,
    required String section,
    required String date,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('attendance')
          .doc(date)
          .collection('records')
          .where('classId', isEqualTo: classId)
          .where('section', isEqualTo: section)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting attendance: $e');
      return [];
    }
  }

  // Get student attendance for a month
  static Future<Map<String, dynamic>> getStudentMonthlyAttendance({
    required String studentId,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final attendanceData = <String, Map<String, dynamic>>{};
      int present = 0, absent = 0, late = 0, total = 0;

      for (var day = startDate; day.isBefore(endDate); day = day.add(const Duration(days: 1))) {
        final dateStr = DateFormat('yyyy-MM-dd').format(day);

        // Skip weekends if configured
        if (day.weekday == DateTime.sunday) {
          continue;
        }

        final doc = await _firestore
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('attendance')
            .doc(dateStr)
            .collection('records')
            .doc(studentId)
            .get();

        total++;

        if (doc.exists) {
          final data = doc.data()!;
          final status = data['status'] ?? 'absent';

          attendanceData[dateStr] = {
            'status': status,
            'checkInTime': data['checkInTime'],
            'checkOutTime': data['checkOutTime'],
          };

          switch (status) {
            case 'present':
              present++;
              break;
            case 'late':
              late++;
              break;
            case 'absent':
              absent++;
              break;
          }
        } else {
          attendanceData[dateStr] = {'status': 'absent', 'checkInTime': null, 'checkOutTime': null};
          absent++;
        }
      }

      return {
        'attendance': attendanceData,
        'summary': {
          'present': present,
          'absent': absent,
          'late': late,
          'total': total,
          'percentage': total > 0 ? (present / total * 100).toStringAsFixed(1) : '0',
        }
      };
    } catch (e) {
      print('Error getting monthly attendance: $e');
      return {
        'attendance': {},
        'summary': {'present': 0, 'absent': 0, 'late': 0, 'total': 0, 'percentage': '0'},
      };
    }
  }

  // Update single student attendance
  static Future<bool> updateStudentAttendance({
    required String studentId,
    required String date,
    required String status,
    String? checkInTime,
    String? checkOutTime,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('attendance')
          .doc(date)
          .collection('records')
          .doc(studentId)
          .update({
        'status': status,
        if (checkInTime != null) 'checkInTime': checkInTime,
        if (checkOutTime != null) 'checkOutTime': checkOutTime,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating attendance: $e');
      return false;
    }
  }

  // Get attendance statistics for a class
  static Future<Map<String, dynamic>> getClassAttendanceStats({
    required String classId,
    required String section,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final students = await _getClassStudents(classId, section);
      final stats = <String, Map<String, dynamic>>{};

      for (var student in students) {
        final studentId = student['id'];
        final monthlyData = await getStudentMonthlyAttendance(
          studentId: studentId,
          year: year,
          month: month,
        );

        stats[studentId] = {
          'name': student['name'],
          'rollNo': student['rollNo'],
          ...monthlyData['summary'],
        };
      }

      return {
        'students': stats,
        'classAverage': _calculateClassAverage(stats),
      };
    } catch (e) {
      print('Error getting class stats: $e');
      return {'students': {}, 'classAverage': '0'};
    }
  }

  // Helper: Get class students
  static Future<List<Map<String, dynamic>>> _getClassStudents(String classId, String section) async {
    final snapshot = await _firestore
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('students')
        .where('class', isEqualTo: classId)
        .where('section', isEqualTo: section)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'rollNo': data['rollNo'] ?? '',
      };
    }).toList();
  }

  static String _calculateClassAverage(Map<String, dynamic> stats) {
    double total = 0;
    int count = 0;

    for (var student in stats.values) {
      final percentage = double.tryParse(student['percentage'] ?? '0');
      if (percentage != null) {
        total += percentage;
        count++;
      }
    }

    return count > 0 ? (total / count).toStringAsFixed(1) : '0';
  }

  // Export attendance to CSV
  static String exportAttendanceToCSV(List<Map<String, dynamic>> attendanceData) {
    String csv = "Student Name,Roll No,Date,Status,Check In Time,Check Out Time\n";

    for (var record in attendanceData) {
      csv += "${record['studentName']},"
          "${record['rollNo']},"
          "${record['date']},"
          "${record['status']},"
          "${record['checkInTime'] ?? '-'},"
          "${record['checkOutTime'] ?? '-'}\n";
    }

    return csv;
  }
}