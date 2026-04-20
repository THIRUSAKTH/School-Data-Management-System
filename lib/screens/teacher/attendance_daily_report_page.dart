import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceDailyReportPage extends StatefulWidget {
  final String schoolId;

  const AttendanceDailyReportPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<AttendanceDailyReportPage> createState() =>
      _AttendanceDailyReportPageState();
}

class _AttendanceDailyReportPageState
    extends State<AttendanceDailyReportPage> {
  String? selectedClass;
  String? selectedSection;
  DateTime selectedDate = DateTime.now();

  List<String> _availableClasses = [];
  List<String> _availableSections = [];
  bool _isLoadingClasses = true;

  // Statistics
  int _totalStudents = 0;
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;
  double _attendanceRate = 0;

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  Future<void> _loadAvailableClasses() async {
    setState(() => _isLoadingClasses = true);

    try {
      // Get unique classes from students collection
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .get();

      final Set<String> classesSet = {};
      final Map<String, Set<String>> classSectionsMap = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final className = data['class'] as String?;
        final section = data['section'] as String?;

        if (className != null && className.isNotEmpty) {
          classesSet.add(className);

          if (section != null && section.isNotEmpty) {
            if (!classSectionsMap.containsKey(className)) {
              classSectionsMap[className] = {};
            }
            classSectionsMap[className]!.add(section);
          }
        }
      }

      setState(() {
        _availableClasses = classesSet.toList()..sort();
        if (_availableClasses.isNotEmpty && selectedClass == null) {
          selectedClass = _availableClasses.first;
          _loadSectionsForClass(selectedClass!);
        }
        _isLoadingClasses = false;
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _loadSectionsForClass(String className) async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: className)
          .get();

      final Set<String> sectionsSet = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final section = data['section'] as String?;
        if (section != null && section.isNotEmpty) {
          sectionsSet.add(section);
        }
      }

      setState(() {
        _availableSections = sectionsSet.toList()..sort();
        if (_availableSections.isNotEmpty) {
          selectedSection = _availableSections.first;
        } else {
          selectedSection = null;
        }
      });
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Daily Attendance Report"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: "Select Date",
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: "Export Report",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Date Display
          _buildDateHeader(),

          // Filters
          _buildFilters(),

          // Statistics Cards
          _buildStatisticsCards(),

          // Attendance List
          Expanded(
            child: _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.indigo.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Attendance Report",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('dd MMMM yyyy').format(selectedDate),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: _buildClassDropdown(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSectionDropdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedClass,
      decoration: const InputDecoration(
        labelText: "Select Class",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _availableClasses.map((className) {
        return DropdownMenuItem(
          value: className,
          child: Text(className),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedClass = value;
          if (value != null) {
            _loadSectionsForClass(value);
          }
        });
      },
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSection,
      decoration: const InputDecoration(
        labelText: "Select Section",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _availableSections.map((section) {
        return DropdownMenuItem(
          value: section,
          child: Text(section),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedSection = value;
        });
      },
    );
  }

  Widget _buildStatisticsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(formattedDate)
          .collection('records')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildStatsCardPlaceholder();
        }

        // Filter records by class and section
        final records = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['className'] == selectedClass && data['section'] == selectedSection;
        }).toList();

        _totalStudents = records.length;
        _presentCount = records.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Present';
        }).length;
        _absentCount = records.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Absent';
        }).length;
        _lateCount = records.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Late';
        }).length;
        _attendanceRate = _totalStudents > 0 ? (_presentCount / _totalStudents) * 100 : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatsCard(
                  title: "Present",
                  value: _presentCount.toString(),
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatsCard(
                  title: "Absent",
                  value: _absentCount.toString(),
                  color: Colors.red,
                  icon: Icons.cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatsCard(
                  title: "Rate",
                  value: "${_attendanceRate.toStringAsFixed(1)}%",
                  color: Colors.indigo,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCardPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _StatsCard(title: "Present", value: "0", color: Colors.green, icon: Icons.check_circle)),
          const SizedBox(width: 12),
          Expanded(child: _StatsCard(title: "Absent", value: "0", color: Colors.red, icon: Icons.cancel)),
          const SizedBox(width: 12),
          Expanded(child: _StatsCard(title: "Rate", value: "0%", color: Colors.indigo, icon: Icons.trending_up)),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (selectedClass == null || selectedSection == null) {
      return const Center(
        child: Text("Please select class and section"),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(formattedDate)
          .collection('records')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No attendance records for ${DateFormat('dd MMM yyyy').format(selectedDate)}",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please mark attendance first",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Filter records by class and section
        final records = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['className'] == selectedClass && data['section'] == selectedSection;
        }).toList();

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No students found for $selectedClass - $selectedSection",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Sort by roll number
        records.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aRoll = int.tryParse(aData['rollNo']?.toString() ?? '0') ?? 0;
          final bRoll = int.tryParse(bData['rollNo']?.toString() ?? '0') ?? 0;
          return aRoll.compareTo(bRoll);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final doc = records[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown';
            final rollNo = data['rollNo'] ?? '';
            final status = data['status'] ?? 'Absent';
            final checkInTime = data['checkInTime'];
            final checkOutTime = data['checkOutTime'];
            final remark = data['remark'];

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

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Text(
                    rollNo.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
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
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (checkInTime != null && checkInTime.isNotEmpty)
                          _infoRow('Check In', checkInTime),
                        if (checkOutTime != null && checkOutTime.isNotEmpty)
                          _infoRow('Check Out', checkOutTime),
                        if (remark != null && remark.isNotEmpty)
                          _infoRow('Remark', remark),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Select Date',
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _exportReport() async {
    // Show export options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel export coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ================= HELPER WIDGETS =================

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatsCard({
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}