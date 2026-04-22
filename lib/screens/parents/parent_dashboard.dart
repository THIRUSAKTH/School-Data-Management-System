import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/authentication_page/login_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_view_results.dart';
import 'package:schoolprojectjan/screens/parents/homework_view_page.dart';
import 'parent_attendance_page.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with SingleTickerProviderStateMixin {
  final String parentUid = FirebaseAuth.instance.currentUser!.uid;
  String? selectedStudentId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog
              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logging out...")),
              );

              try {
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();

                // Clear all routes and navigate to login
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(role: 'Parent'),
                    ),
                        (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifications coming soon")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings coming soon")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeworkViewPage(),
                ),
              );
            },
            tooltip: "View Homework",
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ParentViewResultsPage(),
                ),
              );
            },
            tooltip: "View Results",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('students')
            .where('parentUid', isEqualTo: parentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoChildrenWidget();
          }

          final students = snapshot.data!.docs;

          // Set default selected student if not set
          if (selectedStudentId == null && students.isNotEmpty) {
            selectedStudentId = students.first.id;
          }

          // Safe find - manually find the selected student
          QueryDocumentSnapshot? selectedDoc;
          for (var doc in students) {
            if (doc.id == selectedStudentId) {
              selectedDoc = doc;
              break;
            }
          }

          // If selected student not found, use first one
          if (selectedDoc == null && students.isNotEmpty) {
            selectedDoc = students.first;
            selectedStudentId = selectedDoc.id;
          }

          if (selectedDoc == null) {
            return _buildNoChildrenWidget();
          }

          final data = selectedDoc.data() as Map<String, dynamic>;
          final name = data['name'] ?? "Student";
          final className = data['class'] ?? "";
          final section = data['section'] ?? "";
          final rollNo = data['rollNo'] ?? "";
          final admissionNo = data['admissionNo'] ?? "";
          final fatherName = data['fatherName'] ?? "";
          final motherName = data['motherName'] ?? "";
          final phone = data['phone'] ?? "";

          return Column(
            children: [
              _buildHeader(name, className, section, rollNo),
              _buildChildSelector(students),
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.orange,
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                    Tab(icon: Icon(Icons.calendar_month), text: 'Attendance'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(
                      studentId: selectedStudentId!,
                      name: name,
                      className: className,
                      section: section,
                      rollNo: rollNo,
                      admissionNo: admissionNo,
                      fatherName: fatherName,
                      motherName: motherName,
                      phone: phone,
                    ),
                    _buildAttendanceTab(selectedStudentId!, name),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoChildrenWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Children Linked',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact the school admin to link your children.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String className, String section, String rollNo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, size: 45, color: Colors.orange),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Class $className-$section | Roll No: $rollNo",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector(List<QueryDocumentSnapshot> students) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Select Child',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final doc = students[index];
                final d = doc.data() as Map<String, dynamic>;
                final isSelected = selectedStudentId == doc.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedStudentId = doc.id;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          d['name'] ?? 'Student',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab({
    required String studentId,
    required String name,
    required String className,
    required String section,
    required String rollNo,
    required String admissionNo,
    required String fatherName,
    required String motherName,
    required String phone,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsRow(studentId),
          const SizedBox(height: 20),
          _buildStudentDetailsCard(
            name: name,
            className: className,
            section: section,
            rollNo: rollNo,
            admissionNo: admissionNo,
            fatherName: fatherName,
            motherName: motherName,
            phone: phone,
          ),
          const SizedBox(height: 16),
          _buildFeeSection(),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, attendanceSnapshot) {
        int present = 0;
        int total = 0;

        if (attendanceSnapshot.hasData) {
          for (var doc in attendanceSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total++;
            if (data['status'] == 'Present') {
              present++;
            }
          }
        }

        double attendanceRate = total > 0 ? (present / total) * 100 : 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('student_fees')
              .where('studentId', isEqualTo: studentId)
              .snapshots(),
          builder: (context, feeSnapshot) {
            double totalDue = 0;
            double totalPaid = 0;

            if (feeSnapshot.hasData) {
              for (var doc in feeSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                double amount = (data['amount'] ?? 0).toDouble();
                String status = data['status'] ?? "pending";

                if (status == "paid") {
                  totalPaid += amount;
                } else {
                  totalDue += amount;
                }
              }
            }

            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Attendance",
                    value: "${attendanceRate.toStringAsFixed(1)}%",
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Fees Paid",
                    value: "₹${totalPaid.toInt()}",
                    color: Colors.blue,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Fees Due",
                    value: "₹${totalDue.toInt()}",
                    color: Colors.red,
                    icon: Icons.pending_actions,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStudentDetailsCard({
    required String name,
    required String className,
    required String section,
    required String rollNo,
    required String admissionNo,
    required String fatherName,
    required String motherName,
    required String phone,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Student Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('Student Name', name),
            _infoRow('Class & Section', '$className - $section'),
            _infoRow('Roll Number', rollNo),
            if (admissionNo.isNotEmpty) _infoRow('Admission No', admissionNo),
            if (fatherName.isNotEmpty) _infoRow('Father\'s Name', fatherName),
            if (motherName.isNotEmpty) _infoRow('Mother\'s Name', motherName),
            if (phone.isNotEmpty) _infoRow('Phone', phone),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('student_fees')
          .where('studentId', isEqualTo: selectedStudentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No fee records found'),
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_outlined, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Fee Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] ?? 0).toDouble();
                    final dueDate = data['dueDate'] != null
                        ? (data['dueDate'] as Timestamp).toDate()
                        : null;
                    final status = data['status'] ?? 'pending';
                    final feeType = data['feeType'] ?? 'Fee';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: status == 'paid' ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          status == 'paid' ? Icons.check : Icons.pending,
                          color: status == 'paid' ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        feeType,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: dueDate != null
                          ? Text('Due: ${DateFormat('dd MMM yyyy').format(dueDate)}')
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${amount.toInt()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'paid' ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status == 'paid' ? Colors.green : Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab(String studentId, String studentName) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .limit(30)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No attendance records found',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        int present = 0;
        int absent = 0;
        int late = 0;
        List<Map<String, dynamic>> records = [];

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Absent';
          final date = data['date'] as String?;

          if (status == 'Present') present++;
          else if (status == 'Absent') absent++;
          else if (status == 'Late') late++;

          if (date != null) {
            records.add({
              'date': date,
              'status': status,
              'checkInTime': data['checkInTime'] ?? '',
              'checkOutTime': data['checkOutTime'] ?? '',
            });
          }
        }

        int total = present + absent + late;
        double attendanceRate = total > 0 ? (present / total) * 100 : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: "Present",
                      value: present.toString(),
                      color: Colors.green,
                      icon: Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: "Absent",
                      value: absent.toString(),
                      color: Colors.red,
                      icon: Icons.cancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: "Rate",
                      value: "${attendanceRate.toStringAsFixed(1)}%",
                      color: Colors.orange,
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (records.isNotEmpty) _buildAttendanceChart(records),
              const SizedBox(height: 20),
              _buildRecentRecordsCard(records),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentRecordsCard(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text("No attendance records found")),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Recent Attendance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length > 10 ? 10 : records.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final record = records[index];
                final date = DateTime.tryParse(record['date']) ?? DateTime.now();
                final status = record['status'];

                Color statusColor;
                IconData statusIcon;
                if (status == 'Present') {
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                } else if (status == 'Late') {
                  statusColor = Colors.orange;
                  statusIcon = Icons.access_time;
                } else {
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Text(
                    DateFormat('EEEE, dd MMM yyyy').format(date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: record['checkInTime'].isNotEmpty
                      ? Text('In: ${record['checkInTime']} | Out: ${record['checkOutTime']}')
                      : null,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (records.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParentAttendancePage(
                          schoolId: AppConfig.schoolId,
                          parentId: parentUid,
                          parentName: 'Parent',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All Records'),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart(List<Map<String, dynamic>> records) {
    List<String> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      last7Days.add(DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: i))));
    }

    Map<String, String> statusMap = {};
    for (var record in records) {
      statusMap[record['date']] = record['status'];
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < last7Days.length; i++) {
      String status = statusMap[last7Days[i]] ?? 'Absent';
      Color color;
      double value;

      if (status == 'Present') {
        color = Colors.green;
        value = 100;
      } else if (status == 'Late') {
        color = Colors.orange;
        value = 50;
      } else {
        color = Colors.red;
        value = 0;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: color,
              width: 30,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Weekly Attendance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < last7Days.length) {
                            DateTime date = DateTime.parse(last7Days[index]);
                            return Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(Colors.green, 'Present'),
                const SizedBox(width: 16),
                _legendItem(Colors.orange, 'Late'),
                const SizedBox(width: 16),
                _legendItem(Colors.red, 'Absent'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// STAT CARD Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}