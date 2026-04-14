import 'package:flutter/material.dart';

class AppConfig {
  /// 🔑 Main School ID (VERY IMPORTANT)
  static const String schoolId = "school_1";
  /// ================= BRANDING =================
  /// 🏫 App Name (can show in UI later)
  static const String appName = "ABC School App";

  /// 🎨 Primary Theme Color
  static const Color primaryColor = Color(0xFF0F9B8E);

  /// 🎨 Secondary Color
  static const Color secondaryColor = Color(0xFF1EC8D9);
  /// ================= ROLE =================

  /// Default role (optional use)
  static const String defaultRole = "Admin";
  /// ================= FIRESTORE PATHS =================
  /// (Helps avoid typing mistakes everywhere)

  static const String schoolsCollection = "schools";
  static const String studentsCollection = "students";
  static const String teachersCollection = "teachers";
  static const String feesCollection = "fees";
  static const String attendanceCollection = "attendance";
  static const String studentFeesCollection = "student_fees";

  /// ================= HELPER METHODS =================
  /// 📌 Get School Reference
  static String schoolDocPath() {
    return "$schoolsCollection/$schoolId";
  }

  /// 📌 Get Students Path
  static String studentsPath() {
    return "$schoolsCollection/$schoolId/$studentsCollection";
  }

  /// 📌 Get Teachers Path
  static String teachersPath() {
    return "$schoolsCollection/$schoolId/$teachersCollection";
  }

  /// 📌 Get Fees Path
  static String feesPath() {
    return "$schoolsCollection/$schoolId/$feesCollection";
  }

  /// 📌 Get Student Fees Path
  static String studentFeesPath() {
    return "$schoolsCollection/$schoolId/$studentFeesCollection";
  }
}