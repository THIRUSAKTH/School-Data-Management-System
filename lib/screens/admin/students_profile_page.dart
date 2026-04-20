import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'student_edit_page.dart';

class StudentProfilePage extends StatefulWidget {
  final String schoolId;
  final String studentId;

  const StudentProfilePage({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with SingleTickerProviderStateMixin {  // Make sure this is here
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);  // 'this' works because of SingleTickerProviderStateMixin
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Student Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: "Profile"),
            Tab(icon: Icon(Icons.calendar_today), text: "Attendance"),
            Tab(icon: Icon(Icons.attach_money), text: "Fees"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editStudent(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .doc(widget.studentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Student not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(data),
              _buildAttendanceTab(),
              _buildFeesTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileTab(Map<String, dynamic> data) {
    final name = data['name'] ?? "Student";
    final className = data['class'] ?? "-";
    final section = data['section'] ?? "-";
    final roll = data['rollNo'] ?? "-";
    final admissionNo = data['admissionNo'] ?? "-";
    final parentName = data['parentName'] ?? "-";
    final parentEmail = data['parentEmail'] ?? "-";
    final parentPhone = data['parentPhone'] ?? "-";
    final bloodGroup = data['bloodGroup'] ?? "-";
    final gender = data['gender'] ?? "-";
    final address = data['address'] ?? "-";

    String dob = "-";
    if (data['dob'] != null) {
      dob = DateFormat('dd MMM yyyy').format((data['dob'] as Timestamp).toDate());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Card
          _buildHeaderCard(name, className, section, roll),
          const SizedBox(height: 16),

          // Personal Information
          _buildInfoCard("Personal Information", Icons.person, [
            _infoRow("Student Name", name),
            _infoRow("Roll Number", roll),
            _infoRow("Admission Number", admissionNo),
            _infoRow("Gender", gender),
            _infoRow("Date of Birth", dob),
            _infoRow("Blood Group", bloodGroup),
          ]),
          const SizedBox(height: 16),

          // Academic Information
          _buildInfoCard("Academic Information", Icons.school, [
            _infoRow("Class", className),
            _infoRow("Section", section),
          ]),
          const SizedBox(height: 16),

          // Parent Information
          _buildInfoCard("Parent Information", Icons.family_restroom, [
            _infoRow("Parent Name", parentName),
            _infoRow("Email", parentEmail),
            _infoRow("Phone", parentPhone),
          ]),
          const SizedBox(height: 16),

          // Address
          if (address.isNotEmpty && address != "-")
            _buildInfoCard("Address", Icons.location_on, [
              _infoRow("Address", address),
            ]),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(String name, String className, String section, String roll) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.deepPurple),
            ),
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
            "Class $className - $section | Roll No: $roll",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Colors.deepPurple),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
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
            width: 120,
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

  Widget _buildAttendanceTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        int present = 0;
        int absent = 0;
        int late = 0;
        List<Map<String, dynamic>> records = [];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = doc.id;

            // Check if this student has attendance record
            if (data.containsKey(widget.studentId)) {
              final studentRecord = data[widget.studentId] as Map<String, dynamic>;
              final status = studentRecord['status'] ?? 'Absent';

              records.add({
                'date': date,
                'status': status,
                'checkInTime': studentRecord['checkInTime'],
                'checkOutTime': studentRecord['checkOutTime'],
              });

              if (status == 'Present') present++;
              else if (status == 'Late') late++;
              else absent++;
            }
          }
        }

        final total = present + absent + late;
        final attendanceRate = total > 0 ? (present / total) * 100 : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _statCard("Present", present.toString(), Colors.green, Icons.check_circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard("Absent", absent.toString(), Colors.red, Icons.cancel),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard("Rate", "${attendanceRate.toStringAsFixed(1)}%", Colors.deepPurple, Icons.trending_up),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Attendance Chart
              if (records.isNotEmpty)
                _buildAttendanceChart(records),

              const SizedBox(height: 20),

              // Recent Records
              if (records.isNotEmpty)
                _buildRecentRecords(records),

              if (records.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text("No attendance records found"),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart(List<Map<String, dynamic>> records) {
    // Get last 7 days
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Last 7 Days",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
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
    );
  }

  Widget _buildRecentRecords(List<Map<String, dynamic>> records) {
    var recentRecords = records.take(5).toList();
    recentRecords.sort((a, b) => b['date'].compareTo(a['date']));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Attendance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentRecords.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final record = recentRecords[index];
              final date = DateTime.parse(record['date']);
              final status = record['status'];
              final statusColor = status == 'Present'
                  ? Colors.green
                  : (status == 'Late' ? Colors.orange : Colors.red);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(
                    status == 'Present' ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                title: Text(DateFormat('EEEE, dd MMM yyyy').format(date)),
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
        ],
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

  Widget _buildFeesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('student_fees')
          .where('studentId', isEqualTo: widget.studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        double total = 0;
        double paid = 0;
        List<Map<String, dynamic>> feesList = [];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final f = doc.data() as Map<String, dynamic>;
            double amount = (f['amount'] ?? 0).toDouble();
            String status = f['status'] ?? 'pending';
            total += amount;
            if (status == 'paid') paid += amount;

            feesList.add({
              'amount': amount,
              'status': status,
              'dueDate': f['dueDate'],
              'feeType': f['feeType'] ?? 'Fee',
            });
          }
        }

        final pending = total - paid;
        final collectionRate = total > 0 ? (paid / total) * 100 : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _statCard("Total", "₹${total.toInt()}", Colors.blue, Icons.account_balance_wallet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard("Paid", "₹${paid.toInt()}", Colors.green, Icons.check_circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard("Pending", "₹${pending.toInt()}", Colors.red, Icons.pending),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Collection Rate
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Collection Rate"),
                        Text(
                          "${collectionRate.toStringAsFixed(1)}%",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: collectionRate / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fee Details List
              if (feesList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Fee Details",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: feesList.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final fee = feesList[index];
                          final isPaid = fee['status'] == 'paid';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                              child: Icon(
                                isPaid ? Icons.check : Icons.pending,
                                color: isPaid ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(fee['feeType']),
                            subtitle: fee['dueDate'] != null
                                ? Text("Due: ${DateFormat('dd MMM yyyy').format((fee['dueDate'] as Timestamp).toDate())}")
                                : null,
                            trailing: Text(
                              "₹${fee['amount'].toInt()}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

              if (feesList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text("No fee records found"),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _editStudent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentEditPage(
          schoolId: widget.schoolId,
          studentId: widget.studentId,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Student"),
        content: const Text("Are you sure you want to delete this student? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('students')
                  .doc(widget.studentId)
                  .delete();

              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Student deleted successfully")),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}