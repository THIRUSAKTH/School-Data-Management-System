import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceDailyReportPage extends StatefulWidget {
  final String schoolId;

  const AttendanceDailyReportPage({super.key, required this.schoolId});

  @override
  State<AttendanceDailyReportPage> createState() =>
      _AttendanceDailyReportPageState();
}

class _AttendanceDailyReportPageState extends State<AttendanceDailyReportPage> {
  String selectedClass = "";
  String selectedSection = "A";
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<String> _availableClasses = [];
  List<String> _availableSections = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);

    try {
      final classesSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('classes')
              .get();

      setState(() {
        _availableClasses =
            classesSnapshot.docs
                .map(
                  (doc) =>
                      doc['className'] as String? ??
                      doc['class'] as String? ??
                      '',
                )
                .where((name) => name.isNotEmpty)
                .toList();

        if (_availableClasses.isNotEmpty) {
          selectedClass = _availableClasses.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Daily Attendance Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildFilters(),
                  _buildSummaryCard(),
                  Expanded(child: _buildAttendanceList()),
                ],
              ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Date Selector
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Date",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Class Selector
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Class",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedClass.isEmpty ? null : selectedClass,
                          hint: const Text("Select Class"),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.indigo,
                          ),
                          items:
                              _availableClasses.map((className) {
                                return DropdownMenuItem(
                                  value: className,
                                  child: Text(
                                    className,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedClass = value!;
                              _loadSections(selectedClass);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Section",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSection,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.indigo,
                          ),
                          items:
                              _availableSections.map((section) {
                                return DropdownMenuItem(
                                  value: section,
                                  child: Text(
                                    section,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSection = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadSections(String className) async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where('class', isEqualTo: className)
              .get();

      final sectionsSet = <String>{};
      for (var doc in studentsSnapshot.docs) {
        final section = doc['section'] as String?;
        if (section != null && section.isNotEmpty) {
          sectionsSet.add(section);
        }
      }

      setState(() {
        _availableSections = sectionsSet.toList()..sort();
        if (_availableSections.isNotEmpty) {
          selectedSection = _availableSections.first;
        } else {
          _availableSections = ['A', 'B', 'C', 'D'];
          selectedSection = 'A';
        }
      });
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  Widget _buildSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('attendance')
              .doc(_dateKey)
              .collection('records')
              .where('className', isEqualTo: selectedClass)
              .where('section', isEqualTo: selectedSection)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final records = snapshot.data!.docs;

        if (records.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.history_edu, size: 32, color: Colors.grey),
                  SizedBox(height: 6),
                  Text(
                    "No attendance records",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        int present = 0;
        int absent = 0;
        int late = 0;

        for (var doc in records) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Absent';
          if (status == 'Present')
            present++;
          else if (status == 'Late')
            late++;
          else
            absent++;
        }

        int total = present + absent + late;
        double attendanceRate = total > 0 ? (present / total) * 100 : 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _summaryItem(
                "Present",
                present.toString(),
                Colors.green,
                Icons.check_circle,
              ),
              Container(width: 1, height: 35, color: Colors.grey.shade300),
              _summaryItem(
                "Late",
                late.toString(),
                Colors.orange,
                Icons.access_time,
              ),
              Container(width: 1, height: 35, color: Colors.grey.shade300),
              _summaryItem(
                "Absent",
                absent.toString(),
                Colors.red,
                Icons.cancel,
              ),
              Container(width: 1, height: 35, color: Colors.grey.shade300),
              _summaryItem(
                "Rate",
                "${attendanceRate.toStringAsFixed(1)}%",
                Colors.indigo,
                Icons.trending_up,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('attendance')
              .doc(_dateKey)
              .collection('records')
              .where('className', isEqualTo: selectedClass)
              .where('section', isEqualTo: selectedSection)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!.docs;

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No attendance records found",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "for ${selectedClass.isEmpty ? 'selected class' : selectedClass} - $selectedSection",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Sort by roll number
        records.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final rollA = dataA['rollNo'] ?? '';
          final rollB = dataB['rollNo'] ?? '';
          return rollA.toString().compareTo(rollB.toString());
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final doc = records[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildStudentCard(data);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> data) {
    final name = data['name'] ?? 'Student';
    final rollNo = data['rollNo'] ?? '';
    final status = data['status'] ?? 'Absent';
    final remark = data['remark'] ?? '';
    final checkInTime = data['checkInTime'] ?? '';
    final checkOutTime = data['checkOutTime'] ?? '';

    Color getStatusColor() {
      switch (status) {
        case 'Present':
          return Colors.green;
        case 'Late':
          return Colors.orange;
        default:
          return Colors.red;
      }
    }

    IconData getStatusIcon() {
      switch (status) {
        case 'Present':
          return Icons.check_circle;
        case 'Late':
          return Icons.access_time;
        default:
          return Icons.cancel;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            status == 'Late'
                ? BorderSide(color: Colors.orange.shade300, width: 1)
                : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: getStatusColor().withOpacity(0.1),
          child: Text(
            rollNo.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: getStatusColor(),
              fontSize: 11,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(getStatusIcon(), size: 12, color: getStatusColor()),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: getStatusColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (checkInTime.isNotEmpty)
                  _infoRow("Check In Time", checkInTime),
                if (checkOutTime.isNotEmpty)
                  _infoRow("Check Out Time", checkOutTime),
                if (remark.isNotEmpty) _infoRow("Remark", remark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
