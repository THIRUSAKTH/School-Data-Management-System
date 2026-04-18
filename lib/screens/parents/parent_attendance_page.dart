import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ParentAttendancePage extends StatefulWidget {
  final String schoolId;
  final String parentId;
  final String parentName;

  const ParentAttendancePage({
    super.key,
    required this.schoolId,
    required this.parentId,
    required this.parentName,
  });

  @override
  State<ParentAttendancePage> createState() => _ParentAttendancePageState();
}

class _ParentAttendancePageState extends State<ParentAttendancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _childrenList = [];
  String? _selectedChildId;
  bool _isLoading = true;
  Map<String, dynamic> _attendanceData = {};
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChildren();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);

    try {
      // Get parent document to find linked students
      final parentDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('parents')
          .doc(widget.parentId)
          .get();

      if (parentDoc.exists) {
        final data = parentDoc.data();
        List<dynamic> childrenIds = data?['childrenIds'] ?? [];

        // Load each child's details
        for (String childId in childrenIds) {
          final childDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .doc(childId)
              .get();

          if (childDoc.exists) {
            final childData = childDoc.data();
            _childrenList.add({
              'id': childId,
              'name': childData?['name'] ?? 'Unknown',
              'className': childData?['className'] ?? 'Unknown',
              'rollNo': childData?['rollNo'] ?? '',
              'admissionNo': childData?['admissionNo'] ?? '',
            });
          }
        }
      }

      if (_childrenList.isNotEmpty && _selectedChildId == null) {
        _selectedChildId = _childrenList.first['id'];
        await _loadAttendanceData();
      }
    } catch (e) {
      debugPrint('Error loading children: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading children: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadAttendanceData() async {
    if (_selectedChildId == null) return;

    setState(() => _isLoading = true);

    try {
      final attendanceRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .where('studentId', isEqualTo: _selectedChildId);

      final snapshot = await attendanceRef.get();

      Map<String, dynamic> monthlyData = {};
      int totalPresent = 0;
      int totalAbsent = 0;
      int totalLate = 0;
      int totalHoliday = 0;
      List<Map<String, dynamic>> dailyRecords = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = data['date'] as String?;
        final status = data['status'] as String?;
        final checkInTime = data['checkInTime'] as String?;
        final checkOutTime = data['checkOutTime'] as String?;

        if (date != null && status != null) {
          final month = date.substring(0, 7);
          dailyRecords.add({
            'date': date,
            'status': status,
            'checkInTime': checkInTime,
            'checkOutTime': checkOutTime,
          });

          if (!monthlyData.containsKey(month)) {
            monthlyData[month] = {
              'present': 0,
              'absent': 0,
              'late': 0,
              'holiday': 0,
            };
          }

          if (status == 'Present') {
            monthlyData[month]['present']++;
            totalPresent++;
          } else if (status == 'Absent') {
            monthlyData[month]['absent']++;
            totalAbsent++;
          } else if (status == 'Late') {
            monthlyData[month]['late']++;
            totalLate++;
          } else if (status == 'Holiday') {
            monthlyData[month]['holiday']++;
            totalHoliday++;
          }
        }
      }

      // Calculate attendance rate
      int totalDays = totalPresent + totalAbsent;
      double attendanceRate = totalDays > 0 ? (totalPresent / totalDays) * 100 : 0;

      setState(() {
        _attendanceData = {
          'monthlyData': monthlyData,
          'dailyRecords': dailyRecords,
          'totalPresent': totalPresent,
          'totalAbsent': totalAbsent,
          'totalLate': totalLate,
          'totalHoliday': totalHoliday,
          'attendanceRate': attendanceRate,
        };
      });
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Widget _buildChildSelector() {
    if (_childrenList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No children linked to this parent account. Please contact school admin.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

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
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Child',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _childrenList.length,
              itemBuilder: (context, index) {
                final child = _childrenList[index];
                final isSelected = _selectedChildId == child['id'];
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedChildId = child['id'];
                    });
                    await _loadAttendanceData();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          child['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          child['className'],
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Monthly View'),
            Tab(icon: Icon(Icons.list_alt), text: 'Daily Records'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showMonthPicker,
            tooltip: 'Select Month',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAttendanceReport,
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _childrenList.isEmpty
          ? _buildNoChildrenWidget()
          : Column(
        children: [
          _buildChildSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMonthlyView(),
                _buildDailyRecordsView(),
              ],
            ),
          ),
        ],
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

  Widget _buildMonthlyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceSummaryCards(),
          const SizedBox(height: 24),
          _buildAttendanceChart(),
          const SizedBox(height: 24),
          _buildMonthlyBreakdown(),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildSummaryCard(
          'Attendance Rate',
          '${(_attendanceData['attendanceRate'] ?? 0).toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.green,
          'Overall attendance',
        ),
        _buildSummaryCard(
          'Present',
          '${_attendanceData['totalPresent'] ?? 0}',
          Icons.check_circle,
          Colors.blue,
          'Days present',
        ),
        _buildSummaryCard(
          'Absent',
          '${_attendanceData['totalAbsent'] ?? 0}',
          Icons.cancel,
          Colors.red,
          'Days absent',
        ),
        _buildSummaryCard(
          'Late Arrivals',
          '${_attendanceData['totalLate'] ?? 0}',
          Icons.access_time,
          Colors.orange,
          'Came late',
        ),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    final monthlyData = _attendanceData['monthlyData'] ?? {};
    final currentMonthData = monthlyData[_selectedMonth] ?? {
      'present': 0,
      'absent': 0,
      'late': 0,
    };

    final present = (currentMonthData['present'] ?? 0).toDouble();
    final absent = (currentMonthData['absent'] ?? 0).toDouble();
    final late = (currentMonthData['late'] ?? 0).toDouble();
    final total = present + absent + late;

    List<PieChartSectionData> sections = [];

    if (total > 0) {
      sections.add(
        PieChartSectionData(
          value: present,
          title: '${((present / total) * 100).toStringAsFixed(0)}%',
          color: Colors.green,
          radius: 100,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
      sections.add(
        PieChartSectionData(
          value: absent,
          title: '${((absent / total) * 100).toStringAsFixed(0)}%',
          color: Colors.red,
          radius: 100,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
      if (late > 0) {
        sections.add(
          PieChartSectionData(
            value: late,
            title: '${((late / total) * 100).toStringAsFixed(0)}%',
            color: Colors.orange,
            radius: 100,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      }
    } else {
      sections.add(
         PieChartSectionData(
          value: 1,
          title: 'No Data',
          color: Colors.grey,
          radius: 100,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Distribution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('MMMM yyyy').format(DateTime.parse(_selectedMonth + '-01')),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.green, 'Present'),
        const SizedBox(width: 20),
        _legendItem(Colors.red, 'Absent'),
        const SizedBox(width: 20),
        _legendItem(Colors.orange, 'Late'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMonthlyBreakdown() {
    final monthlyData = _attendanceData['monthlyData'] ?? {};
    final sortedMonths = monthlyData.keys.toList()..sort();

    if (sortedMonths.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text('No attendance records found'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedMonths.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final month = sortedMonths[index];
              final data = monthlyData[month];
              final present = data?['present'] ?? 0;
              final absent = data?['absent'] ?? 0;
              final late = data?['late'] ?? 0;
              final total = present + absent + late;
              final rate = total > 0 ? (present / total) * 100 : 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: rate >= 75 ? Colors.green.shade100 : Colors.orange.shade100,
                  child: Text(
                    '${present + absent}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rate >= 75 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                title: Text(DateFormat('MMMM yyyy').format(DateTime.parse(month + '-01'))),
                subtitle: Text('Present: $present | Absent: $absent | Late: $late'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: rate >= 75 ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: rate >= 75 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDailyRecordsView() {
    final dailyRecords = List<Map<String, dynamic>>.from(_attendanceData['dailyRecords'] ?? []);

    // Sort by date descending (newest first)
    dailyRecords.sort((a, b) => b['date'].compareTo(a['date']));

    if (dailyRecords.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dailyRecords.length,
      itemBuilder: (context, index) {
        final record = dailyRecords[index];
        final date = DateTime.parse(record['date']);
        final status = record['status'];
        final checkInTime = record['checkInTime'];
        final checkOutTime = record['checkOutTime'];

        Color statusColor;
        IconData statusIcon;
        if (status == 'Present') {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (status == 'Absent') {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
        } else if (status == 'Late') {
          statusColor = Colors.orange;
          statusIcon = Icons.access_time;
        } else {
          statusColor = Colors.grey;
          statusIcon = Icons.help_outline;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: _cardDecoration(),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: checkInTime != null && checkOutTime != null
                ? Text('In: $checkInTime | Out: $checkOutTime')
                : null,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedMonth + '-01'),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Month',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
      });
      await _loadAttendanceData();
    }
  }

  Future<void> _exportAttendanceReport() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export feature coming soon')),
      );
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}