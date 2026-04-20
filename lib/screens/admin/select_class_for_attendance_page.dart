import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_monthly_attendance_page.dart';

class SelectClassForAttendancePage extends StatefulWidget {
  final String schoolId;

  const SelectClassForAttendancePage({
    super.key,
    required this.schoolId,
  });

  @override
  State<SelectClassForAttendancePage> createState() =>
      _SelectClassForAttendancePageState();
}

class _SelectClassForAttendancePageState
    extends State<SelectClassForAttendancePage> {

  String searchText = "";
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  String? selectedClassFilter;
  String? selectedSectionFilter;

  List<String> _availableClasses = [];
  List<String> _availableSections = [];

  final List<String> months = const [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .get();

      final Set<String> classesSet = {};
      final Set<String> sectionsSet = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final className = data['class'] as String?;
        final section = data['section'] as String?;

        if (className != null && className.isNotEmpty) {
          classesSet.add(className);
        }
        if (section != null && section.isNotEmpty) {
          sectionsSet.add(section);
        }
      }

      setState(() {
        _availableClasses = classesSet.toList()..sort();
        _availableSections = sectionsSet.toList()..sort();
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Monthly Attendance Reports",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFilters,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          _buildHeaderCard(),

          // Search Box
          _buildSearchBox(),

          // Filters Row
          _buildFiltersRow(),

          // Date Selector
          _buildDateSelector(),

          // List Header
          _buildListHeader(),

          // Class List
          Expanded(
            child: _buildClassList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Attendance Reports",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Select a class to view monthly attendance",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search by class name...",
          prefixIcon: const Icon(Icons.search, color: Colors.green),
          suffixIcon: searchText.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                searchText = "";
              });
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 1),
          ),
        ),
        onChanged: (value) => setState(() => searchText = value.toLowerCase()),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedClassFilter,
              hint: const Text("All Classes"),
              decoration: InputDecoration(
                labelText: "Filter by Class",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.filter_list, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("All Classes")),
                ..._availableClasses.map((className) {
                  return DropdownMenuItem(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedClassFilter = value;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedSectionFilter,
              hint: const Text("All Sections"),
              decoration: InputDecoration(
                labelText: "Filter by Section",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.group, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("All Sections")),
                ..._availableSections.map((section) {
                  return DropdownMenuItem(
                    value: section,
                    child: Text(section),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedSectionFilter = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: InputDecoration(
                labelText: "Month",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.calendar_month, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: List.generate(12, (i) {
                return DropdownMenuItem(
                  value: i + 1,
                  child: Text(months[i]),
                );
              }),
              onChanged: (v) => setState(() => selectedMonth = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: InputDecoration(
                labelText: "Year",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.calendar_today, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: List.generate(6, (i) {
                final year = 2024 + i;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (v) => setState(() => selectedYear = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('Class Name', style: TextStyle(fontWeight: FontWeight.bold))),
          Text('Section', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
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
                Icon(Icons.class_, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No classes found",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please add students first",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Get unique class-section combinations
        final Map<String, Map<String, dynamic>> classMap = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final className = data['class'] as String?;
          final section = data['section'] as String?;

          if (className != null && className.isNotEmpty) {
            final key = "$className-${section ?? ''}";
            if (!classMap.containsKey(key)) {
              classMap[key] = {
                'className': className,
                'section': section ?? '',
                'studentCount': 0,
              };
            }
            classMap[key]!['studentCount'] = (classMap[key]!['studentCount'] as int) + 1;
          }
        }

        // Convert to list and apply filters
        List<Map<String, dynamic>> classList = classMap.values.toList();

        // Apply search filter
        if (searchText.isNotEmpty) {
          classList = classList.where((classInfo) {
            final fullName = "${classInfo['className']} ${classInfo['section']}".toLowerCase();
            return fullName.contains(searchText);
          }).toList();
        }

        // Apply class filter
        if (selectedClassFilter != null && selectedClassFilter!.isNotEmpty) {
          classList = classList.where((classInfo) {
            return classInfo['className'] == selectedClassFilter;
          }).toList();
        }

        // Apply section filter
        if (selectedSectionFilter != null && selectedSectionFilter!.isNotEmpty) {
          classList = classList.where((classInfo) {
            return classInfo['section'] == selectedSectionFilter;
          }).toList();
        }

        if (classList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No matching classes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try adjusting your search or filters",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Sort by class name
        classList.sort((a, b) => a['className'].compareTo(b['className']));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classList.length,
          itemBuilder: (context, index) {
            final classInfo = classList[index];
            final className = classInfo['className'];
            final section = classInfo['section'];
            final studentCount = classInfo['studentCount'];

            // Calculate color based on student count
            Color cardColor = Colors.white;
            if (studentCount == 0) {
              cardColor = Colors.grey.shade50;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: studentCount > 0
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminMonthlyAttendancePage(
                        schoolId: widget.schoolId,
                        className: className,
                        section: section.isEmpty ? "A" : section,
                        month: selectedMonth,
                        year: selectedYear,
                      ),
                    ),
                  );
                }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: cardColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: studentCount > 0
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.class_,
                            color: studentCount > 0
                                ? Colors.green.shade700
                                : Colors.grey.shade500,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                className,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: studentCount > 0
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Section: ${section.isEmpty ? 'A' : section}",
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: studentCount > 0
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "$studentCount Students",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: studentCount > 0
                                            ? Colors.blue.shade700
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (studentCount > 0)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                          ),
                        if (studentCount == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "No Students",
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}