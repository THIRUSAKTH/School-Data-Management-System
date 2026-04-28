import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class AdminAcademicYearPage extends StatefulWidget {
  const AdminAcademicYearPage({super.key});

  @override
  State<AdminAcademicYearPage> createState() => _AdminAcademicYearPageState();
}

class _AdminAcademicYearPageState extends State<AdminAcademicYearPage> {
  final TextEditingController _yearNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _loadDefaultDates();
  }

  void _loadDefaultDates() {
    final now = DateTime.now();
    final year = now.year;

    // Default: June to May academic year
    _startDate = DateTime(year, 6, 1);
    _endDate = DateTime(year + 1, 5, 31);

    _startDateController.text = DateFormat('dd MMM yyyy').format(_startDate!);
    _endDateController.text = DateFormat('dd MMM yyyy').format(_endDate!);
    _yearNameController.text = "$year - ${year + 1}";
  }

  Future<void> _pickDate(TextEditingController controller, DateTime? currentDate, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('dd MMM yyyy').format(picked);
      if (isStart) {
        setState(() => _startDate = picked);
        // Auto update year name if dates change
        if (_endDate != null) {
          _yearNameController.text = "${picked.year} - ${_endDate!.year}";
        }
      } else {
        setState(() => _endDate = picked);
        if (_startDate != null) {
          _yearNameController.text = "${_startDate!.year} - ${picked.year}";
        }
      }
    }
  }

  Future<void> _saveAcademicYear() async {
    if (_yearNameController.text.isEmpty) {
      _showSnackbar("Please enter academic year name", Colors.red);
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showSnackbar("Please select start and end dates", Colors.red);
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      _showSnackbar("Start date cannot be after end date", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _yearNameController.text.trim(),
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'isActive': _editingId == null, // New year becomes active by default
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingId != null) {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('academic_years')
            .doc(_editingId)
            .update(data);
        _showSnackbar("Academic year updated successfully", Colors.green);
      } else {
        // If this is the first year, make it active
        final existingYears = await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('academic_years')
            .get();

        if (existingYears.docs.isEmpty) {
          data['isActive'] = true;
        }

        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('academic_years')
            .add(data);
        _showSnackbar("Academic year created successfully", Colors.green);
      }

      _clearForm();
    } catch (e) {
      _showSnackbar("Error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setActiveYear(String id, String name) async {
    final batch = FirebaseFirestore.instance.batch();

    // Get all academic years
    final allYears = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('academic_years')
        .get();

    // Set all to inactive
    for (var doc in allYears.docs) {
      batch.update(doc.reference, {'isActive': false});
    }

    // Set selected to active
    batch.update(
        FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('academic_years')
            .doc(id),
        {'isActive': true}
    );

    await batch.commit();
    _showSnackbar("$name is now active", Colors.green);
  }

  Future<void> _deleteYear(String id, String name, bool isActive) async {
    if (isActive) {
      _showSnackbar("Cannot delete active academic year", Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Academic Year"),
        content: Text("Are you sure you want to delete $name?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(AppConfig.schoolId)
                  .collection('academic_years')
                  .doc(id)
                  .delete();
              _showSnackbar("Academic year deleted", Colors.green);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _editYear(String id, Map<String, dynamic> data) {
    setState(() {
      _editingId = id;
      _yearNameController.text = data['name'] ?? '';
      _startDate = (data['startDate'] as Timestamp?)?.toDate();
      _endDate = (data['endDate'] as Timestamp?)?.toDate();
      _startDateController.text = _startDate != null
          ? DateFormat('dd MMM yyyy').format(_startDate!)
          : '';
      _endDateController.text = _endDate != null
          ? DateFormat('dd MMM yyyy').format(_endDate!)
          : '';
    });
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _loadDefaultDates();
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Academic Year Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          if (_editingId != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearForm,
              tooltip: "Cancel Edit",
            ),
        ],
      ),
      body: Column(
        children: [
          // Add/Edit Form
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingId != null ? "Edit Academic Year" : "Add New Academic Year",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _yearNameController,
                  decoration: const InputDecoration(
                    labelText: "Academic Year Name",
                    hintText: "e.g., 2024 - 2025",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(_startDateController, _startDate, true),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _startDateController,
                            decoration: const InputDecoration(
                              labelText: "Start Date",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.play_arrow),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(_endDateController, _endDate, false),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _endDateController,
                            decoration: const InputDecoration(
                              labelText: "End Date",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.stop),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAcademicYear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_editingId != null ? "Update" : "Create"),
                  ),
                ),
              ],
            ),
          ),

          // Academic Years List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(AppConfig.schoolId)
                  .collection('academic_years')
                  .orderBy('startDate', descending: true)
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
                        Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "No Academic Years Found",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap + to add a new academic year",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isActive = data['isActive'] ?? false;
                    final startDate = (data['startDate'] as Timestamp?)?.toDate();
                    final endDate = (data['endDate'] as Timestamp?)?.toDate();
                    final now = DateTime.now();
                    final isCurrentYear = startDate != null && endDate != null &&
                        now.isAfter(startDate) && now.isBefore(endDate);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: _cardDecoration(),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.green : Colors.grey.shade200,
                          child: Icon(
                            Icons.calendar_today,
                            color: isActive ? Colors.white : Colors.grey,
                          ),
                        ),
                        title: Text(
                          data['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (startDate != null && endDate != null)
                              Text(
                                "${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}",
                                style: const TextStyle(fontSize: 11),
                              ),
                            if (isCurrentYear && !isActive)
                              const Text(
                                "Current Year (Not Active)",
                                style: TextStyle(fontSize: 10, color: Colors.orange),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isActive)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editYear(doc.id, data),
                                tooltip: "Edit",
                              ),
                            if (!isActive)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteYear(doc.id, data['name'] ?? '', isActive),
                                tooltip: "Delete",
                              ),
                            if (!isActive && !isCurrentYear)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _setActiveYear(doc.id, data['name'] ?? ''),
                                tooltip: "Set as Active",
                              ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "ACTIVE",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearForm,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: "Add New Academic Year",
      ),
    );
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