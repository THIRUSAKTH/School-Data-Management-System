import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:schoolprojectjan/app_config.dart';

class ParentAttendancePage extends StatefulWidget {
  final String? studentId;
  final String? schoolId;

  const ParentAttendancePage({super.key, this.studentId, this.schoolId});

  @override
  State<ParentAttendancePage> createState() => _ParentAttendancePageState();
}

class _ParentAttendancePageState extends State<ParentAttendancePage> {
  String? _selectedStudentId;
  String? _studentName;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  Map<String, dynamic> _attendanceData = {};
  bool _isLoading = true;
  bool _isLoadingChart = false;
  final String _schoolId = AppConfig.schoolId;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(_schoolId)
              .collection('students')
              .where(
                'parentUid',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .get();

      if (snapshot.docs.isNotEmpty) {
        if (widget.studentId != null) {
          final studentDoc = snapshot.docs.firstWhere(
            (doc) => doc.id == widget.studentId,
            orElse: () => snapshot.docs.first,
          );
          _selectedStudentId = studentDoc.id;
          _studentName = studentDoc.data()['name'] ?? 'Student';
        } else {
          final firstStudent = snapshot.docs.first;
          _selectedStudentId = firstStudent.id;
          _studentName = firstStudent.data()['name'] ?? 'Student';
        }
        await _loadAttendance();
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading students: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendance() async {
    if (_selectedStudentId == null) return;

    setState(() => _isLoadingChart = true);

    try {
      final Map<String, dynamic> data = {};

      // Method 1: Try collection group query (requires index)
      try {
        final allAttendance =
            await FirebaseFirestore.instance
                .collectionGroup('records')
                .where('studentId', isEqualTo: _selectedStudentId)
                .get();

        for (var doc in allAttendance.docs) {
          final docData = doc.data();
          final date = docData['date'];
          if (date != null && date.toString().startsWith(_selectedMonth)) {
            data[date.toString()] = {
              'status': docData['status'],
              'checkInTime': docData['checkInTime'],
              'checkOutTime': docData['checkOutTime'],
              'remark': docData['remark'],
            };
          }
        }
        setState(() => _attendanceData = data);
      } catch (e) {
        // Method 2: Fallback - Query by date range without index
        debugPrint('Collection group query failed, using fallback: $e');
        await _loadAttendanceFallback(data);
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please create Firebase index for attendance"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingChart = false);
    }
  }

  // Fallback method that doesn't require collection group index
  Future<void> _loadAttendanceFallback(Map<String, dynamic> data) async {
    try {
      // Get all attendance documents for the selected month
      final startDate = '$_selectedMonth-01';

      // Query by date - this doesn't need collection group index
      final monthStart = DateTime.parse(startDate);
      final nextMonth = DateTime(monthStart.year, monthStart.month + 1);
      final endDate = DateFormat(
        'yyyy-MM-dd',
      ).format(nextMonth.subtract(const Duration(days: 1)));

      // Get all attendance dates in the month
      final attendanceDates =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(_schoolId)
              .collection('attendance')
              .get();

      for (var dateDoc in attendanceDates.docs) {
        final date = dateDoc.id;
        if (date.startsWith(_selectedMonth)) {
          try {
            final record =
                await dateDoc.reference
                    .collection('records')
                    .doc(_selectedStudentId)
                    .get();

            if (record.exists) {
              final recordData = record.data()!;
              data[date] = {
                'status': recordData['status'] ?? 'Absent',
                'checkInTime': recordData['checkInTime'] ?? '',
                'checkOutTime': recordData['checkOutTime'] ?? '',
                'remark': recordData['remark'] ?? '',
              };
            }
          } catch (e) {
            debugPrint('Error fetching record for $date: $e');
          }
        }
      }

      if (mounted) {
        setState(() => _attendanceData = data);
      }
    } catch (e) {
      debugPrint('Fallback attendance load error: $e');
    }
  }

  String _getEndDateOfMonth(String yearMonth) {
    final date = DateTime.parse('$yearMonth-01');
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return DateFormat('yyyy-MM-dd').format(lastDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text("Attendance Details"),
        actions: [
          if (_studentName != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_studentName!, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedStudentId == null
              ? _buildNoStudentsWidget()
              : Column(
                children: [
                  _buildChildSelector(),
                  _buildMonthSelector(),
                  Expanded(
                    child:
                        _isLoadingChart
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildAttendanceSummary(),
                                  const SizedBox(height: 20),
                                  if (_attendanceData.isNotEmpty) ...[
                                    _buildMonthlyChart(),
                                    const SizedBox(height: 20),
                                    _buildAttendanceCalendar(),
                                  ] else ...[
                                    _buildEmptyState(),
                                  ],
                                ],
                              ),
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildNoStudentsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Children Linked',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No attendance records for ${DateFormat('MMMM yyyy').format(DateTime.parse("$_selectedMonth-01"))}',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(_schoolId)
              .collection('students')
              .where(
                'parentUid',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final students = snapshot.data!.docs;

        if (students.length <= 1) {
          return const SizedBox(height: 8);
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStudentId,
              hint: const Text("Select Child"),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
              items:
                  students.map<DropdownMenuItem<String>>((student) {
                    final data = student.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: student.id,
                      child: Text(
                        data['name'] ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedStudentId = value;
                  if (value != null) {
                    final selected = students.firstWhere((s) => s.id == value);
                    final data = selected.data() as Map<String, dynamic>;
                    _studentName = data['name'] ?? 'Student';
                  }
                });
                await _loadAttendance();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    final currentDate = DateTime.now();
    final selectedDate = DateTime.parse('$_selectedMonth-01');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.orange),
            onPressed: () {
              final date = DateTime.parse('$_selectedMonth-01');
              final prevMonth = DateTime(date.year, date.month - 1);
              setState(() {
                _selectedMonth = DateFormat('yyyy-MM').format(prevMonth);
              });
              _loadAttendance();
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(selectedDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.orange),
            onPressed: () {
              final date = DateTime.parse('$_selectedMonth-01');
              final nextMonth = DateTime(date.year, date.month + 1);
              if (nextMonth.isBefore(DateTime.now()) ||
                  (nextMonth.year == currentDate.year &&
                      nextMonth.month == currentDate.month)) {
                setState(() {
                  _selectedMonth = DateFormat('yyyy-MM').format(nextMonth);
                });
                _loadAttendance();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    int present =
        _attendanceData.values.where((v) => v['status'] == 'Present').length;
    int absent =
        _attendanceData.values.where((v) => v['status'] == 'Absent').length;
    int late =
        _attendanceData.values.where((v) => v['status'] == 'Late').length;
    int total = present + absent + late;
    double percentage = total > 0 ? (present / total) * 100 : 0;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _SummaryCard(
          title: "Present",
          value: present.toString(),
          color: Colors.green,
          icon: Icons.check_circle,
        ),
        _SummaryCard(
          title: "Absent",
          value: absent.toString(),
          color: Colors.red,
          icon: Icons.cancel,
        ),
        if (late > 0)
          _SummaryCard(
            title: "Late",
            value: late.toString(),
            color: Colors.orange,
            icon: Icons.access_time,
          ),
        _SummaryCard(
          title: "Rate",
          value: "${percentage.toStringAsFixed(1)}%",
          color: Colors.blue,
          icon: Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    Map<int, int> weeklyPresent = {};
    Map<int, int> weeklyTotal = {};

    for (var entry in _attendanceData.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date != null) {
        final weekNumber = ((date.day - 1) ~/ 7) + 1;
        weeklyTotal[weekNumber] = (weeklyTotal[weekNumber] ?? 0) + 1;
        if (entry.value['status'] == 'Present') {
          weeklyPresent[weekNumber] = (weeklyPresent[weekNumber] ?? 0) + 1;
        }
      }
    }

    final weeks = [1, 2, 3, 4, 5];
    final presentData = weeks.map((w) => weeklyPresent[w] ?? 0).toList();
    final totalData = weeks.map((w) => weeklyTotal[w] ?? 0).toList();

    final maxValue = totalData.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxValue == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Text(
            "Weekly Performance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(weeks.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: totalData[i].toDouble(),
                        color: Colors.grey.shade300,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: presentData[i].toDouble(),
                        color: Colors.green,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }),
                maxY: maxValue + 1,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget:
                          (value, meta) => Text('${value.toInt()}'),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        return index < weeks.length
                            ? Text('Week ${weeks[index]}')
                            : const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final week = weeks[groupIndex];
                      final total = totalData[groupIndex];
                      final present = presentData[groupIndex];
                      return BarTooltipItem(
                        'Week $week\nPresent: $present/$total\nRate: ${total > 0 ? ((present / total) * 100).toStringAsFixed(1) : 0}%',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(Colors.green, 'Present'),
              const SizedBox(width: 16),
              _legendItem(Colors.grey.shade300, 'Total Days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAttendanceCalendar() {
    final daysInMonth = _getDaysInMonth(_selectedMonth);
    final firstDay = DateTime.parse('$_selectedMonth-01');
    final startingOffset = firstDay.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Text(
            "Attendance Calendar",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final day = index - startingOffset + 1;
              if (day < 1 || day > daysInMonth) {
                return Container();
              }
              final dateKey =
                  '$_selectedMonth-${day.toString().padLeft(2, '0')}';
              final record = _attendanceData[dateKey];
              final status = record != null ? record['status'] : null;

              Color bgColor;
              IconData? icon;
              Color iconColor;

              if (status == 'Present') {
                bgColor = Colors.green.shade100;
                icon = Icons.check_circle;
                iconColor = Colors.green;
              } else if (status == 'Absent') {
                bgColor = Colors.red.shade100;
                icon = Icons.cancel;
                iconColor = Colors.red;
              } else if (status == 'Late') {
                bgColor = Colors.orange.shade100;
                icon = Icons.access_time;
                iconColor = Colors.orange;
              } else {
                bgColor = Colors.grey.shade100;
                icon = null;
                iconColor = Colors.grey;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (icon != null) Icon(icon, size: 12, color: iconColor),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getDaysInMonth(String yearMonth) {
    final date = DateTime.parse('$yearMonth-01');
    final nextMonth = DateTime(date.year, date.month + 1);
    return nextMonth.difference(date).inDays;
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
