import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:schoolprojectjan/screens/authentication_page/login_page.dart';
import 'parent_view_results.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStudentId;
  String? _schoolId;

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
    _schoolId = ModalRoute.of(context)!.settings.arguments as String;
    final parentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Parent Dashboard"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: "My Children"),
            Tab(icon: Icon(Icons.analytics), text: "Analytics"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
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
            .doc(_schoolId)
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

          // Set default selected student only if not set
          if (_selectedStudentId == null && students.isNotEmpty) {
            _selectedStudentId = students.first.id;
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildChildrenList(students),
              _buildAnalyticsTab(students),
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
            "No Child Linked",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Please contact the school admin to link your children.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenList(List<QueryDocumentSnapshot> students) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final data = s.data() as Map<String, dynamic>;
        final isSelected = _selectedStudentId == s.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedStudentId = s.id;
              _tabController.animateTo(1);
            });
          },
          child: Card(
            elevation: isSelected ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(color: Colors.orange, width: 2)
                  : BorderSide.none,
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Colors.white, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Colors.orange : Colors.orange.shade100,
                  child: Icon(
                    Icons.person,
                    color: isSelected ? Colors.white : Colors.orange,
                  ),
                ),
                title: Text(
                  data['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.orange.shade800 : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("Class: ${data['class'] ?? 'N/A'} ${data['section'] ?? ''}"),
                    Text("Roll No: ${data['rollNo'] ?? 'N/A'}"),
                  ],
                ),
                trailing: isSelected
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SELECTED',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
                    : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(List<QueryDocumentSnapshot> students) {
    if (_selectedStudentId == null) {
      return const Center(child: Text('Select a child to view details'));
    }

    // Safe find with null check
    QueryDocumentSnapshot? selectedStudent;
    for (var student in students) {
      if (student.id == _selectedStudentId) {
        selectedStudent = student;
        break;
      }
    }

    if (selectedStudent == null && students.isNotEmpty) {
      selectedStudent = students.first;
      _selectedStudentId = selectedStudent.id;
    }

    if (selectedStudent == null) {
      return const Center(child: Text('No child selected'));
    }

    final data = selectedStudent.data() as Map<String, dynamic>;
    final studentName = data['name'] ?? 'Student';
    final className = data['class'] ?? '';
    final section = data['section'] ?? '';
    final rollNo = data['rollNo'] ?? '';
    final admissionNo = data['admissionNo'] ?? '';
    final fatherName = data['fatherName'] ?? '';
    final motherName = data['motherName'] ?? '';
    final phone = data['phone'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStudentHeader(studentName, className, section, rollNo),
          const SizedBox(height: 16),
          _buildStatsRow(_selectedStudentId!),
          const SizedBox(height: 16),
          _buildAttendanceSummary(_selectedStudentId!),
          const SizedBox(height: 16),
          _buildFeeDetails(_selectedStudentId!),
          const SizedBox(height: 16),
          _buildStudentDetails(
            name: studentName,
            className: className,
            section: section,
            rollNo: rollNo,
            admissionNo: admissionNo,
            fatherName: fatherName,
            motherName: motherName,
            phone: phone,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader(String name, String className, String section, String rollNo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, size: 40, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Class $className-$section | Roll No: $rollNo",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
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
              .doc(_schoolId)
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

  Widget _buildAttendanceSummary(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return Card(
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No attendance records found')),
            ),
          );
        }

        final records = snapshot.data!.docs;
        int present = 0;
        int absent = 0;
        int late = 0;

        for (var doc in records) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Absent';
          if (status == 'Present') present++;
          else if (status == 'Late') late++;
          else absent++;
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Recent Attendance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        value: present.toString(),
                        label: 'Present',
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        value: late.toString(),
                        label: 'Late',
                        color: Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        value: absent.toString(),
                        label: 'Absent',
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length > 5 ? 5 : records.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = records[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final dateStr = data['date'] ?? '';
                    DateTime date;
                    try {
                      date = DateTime.parse(dateStr);
                    } catch (e) {
                      date = DateTime.now();
                    }
                    final status = data['status'] ?? 'Absent';

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
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      title: Text(
                        DateFormat('EEEE, dd MMM yyyy').format(date),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
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

  Widget _buildFeeDetails(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .collection('student_fees')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return Card(
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No fee records found')),
            ),
          );
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.orange),
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
                        radius: 20,
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

  Widget _buildStudentDetails({
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
            _infoRow('Father\'s Name', fatherName.isNotEmpty ? fatherName : 'Not provided'),
            _infoRow('Mother\'s Name', motherName.isNotEmpty ? motherName : 'Not provided'),
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
}

// Helper Widgets
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}