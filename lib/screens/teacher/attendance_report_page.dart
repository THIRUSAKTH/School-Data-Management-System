import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceReportPage extends StatefulWidget {
  final String schoolId;

  const AttendanceReportPage({super.key, required this.schoolId});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = "All";
  bool _isLoading = false;

  final List<String> _filterOptions = ["All", "Present", "Absent", "Late"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text(
          "Attendance Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: "Filter",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildSummaryCard(),
          Expanded(child: _buildAttendanceList()),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
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
                  DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
            onPressed: _pickDate,
            tooltip: "Change Date",
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('attendance')
              .doc(_getDateKey())
              .collection('records')
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
                  Icon(Icons.history_edu, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    "No attendance records for this date",
                    style: TextStyle(color: Colors.grey),
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
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Expanded(
                child: _summaryItem(
                  "Present",
                  present.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: _summaryItem(
                  "Late",
                  late.toString(),
                  Colors.orange,
                  Icons.access_time,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: _summaryItem(
                  "Absent",
                  absent.toString(),
                  Colors.red,
                  Icons.cancel,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: _summaryItem(
                  "Rate",
                  "${attendanceRate.toStringAsFixed(1)}%",
                  Colors.indigo,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('attendance')
              .doc(_getDateKey())
              .collection('records')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var records = snapshot.data!.docs;

        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No attendance records found",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Apply filter
        if (_selectedFilter != "All") {
          records =
              records.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == _selectedFilter;
              }).toList();
        }

        // Sort by Class and Section
        records.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final classA = dataA['className'] ?? '';
          final classB = dataB['className'] ?? '';
          final sectionA = dataA['section'] ?? '';
          final sectionB = dataB['section'] ?? '';

          if (classA == classB) {
            return sectionA.compareTo(sectionB);
          }
          return classA.compareTo(classB);
        });

        if (records.isEmpty && _selectedFilter != "All") {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_alt_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No $_selectedFilter students found",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final doc = records[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildAttendanceCard(data);
          },
        );
      },
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> data) {
    final name = data['name'] ?? 'Student';
    final rollNo = data['rollNo'] ?? '';
    final className = data['className'] ?? '';
    final section = data['section'] ?? '';
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            status == 'Late'
                ? BorderSide(color: Colors.orange.shade300, width: 1)
                : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: getStatusColor().withOpacity(0.1),
          child: Text(
            rollNo.isEmpty ? "?" : rollNo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: getStatusColor(),
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$className - $section", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(getStatusIcon(), size: 12, color: getStatusColor()),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: getStatusColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: getStatusColor(),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDate: _selectedDate,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Filter by Status",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _filterOptions.map((option) {
                    Color getColor() {
                      switch (option) {
                        case 'Present':
                          return Colors.green;
                        case 'Late':
                          return Colors.orange;
                        case 'Absent':
                          return Colors.red;
                        default:
                          return Colors.indigo;
                      }
                    }

                    return RadioListTile<String>(
                      title: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: getColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(option),
                        ],
                      ),
                      value: option,
                      groupValue: _selectedFilter,
                      activeColor: Colors.indigo,
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  String _getDateKey() {
    return DateFormat('yyyy-MM-dd').format(_selectedDate);
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
