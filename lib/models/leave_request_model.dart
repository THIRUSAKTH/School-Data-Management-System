// lib/models/leave_request_model.dart
class LeaveRequest {
  String? id;
  String teacherId;
  String teacherName;
  String teacherEmail;
  String teacherClass;
  String teacherSubject;
  String leaveType;
  DateTime fromDate;
  DateTime toDate;
  int days;
  String reason;
  String? documentUrl;
  String status; // pending, approved, rejected, cancelled
  DateTime appliedAt;
  String? approvedBy;
  DateTime? approvedAt;
  String? rejectionReason;
  DateTime createdAt;
  DateTime updatedAt;

  LeaveRequest({
    this.id,
    required this.teacherId,
    required this.teacherName,
    required this.teacherEmail,
    required this.teacherClass,
    required this.teacherSubject,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.reason,
    this.documentUrl,
    this.status = 'pending',
    required this.appliedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherEmail': teacherEmail,
      'teacherClass': teacherClass,
      'teacherSubject': teacherSubject,
      'leaveType': leaveType,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'days': days,
      'reason': reason,
      'documentUrl': documentUrl,
      'status': status,
      'appliedAt': appliedAt.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LeaveRequest.fromMap(String id, Map<String, dynamic> map) {
    return LeaveRequest(
      id: id,
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      teacherEmail: map['teacherEmail'] ?? '',
      teacherClass: map['teacherClass'] ?? '',
      teacherSubject: map['teacherSubject'] ?? '',
      leaveType: map['leaveType'] ?? '',
      fromDate: DateTime.parse(map['fromDate']),
      toDate: DateTime.parse(map['toDate']),
      days: map['days']?.toInt() ?? 0,
      reason: map['reason'] ?? '',
      documentUrl: map['documentUrl'],
      status: map['status'] ?? 'pending',
      appliedAt: DateTime.parse(map['appliedAt']),
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
      rejectionReason: map['rejectionReason'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}