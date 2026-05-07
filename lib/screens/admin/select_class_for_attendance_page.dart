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
  String _searchText = "";
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedClassFilter;
  String? _selectedSectionFilter;
  bool _isLoadingFilters = true;

  List<String> _availableClasses = [];
  List<String> _availableSections = [];

  final List<String> _months = const [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() => _isLoadingFilters = true);

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
        _isLoadingFilters = false;
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
      setState(() => _isLoadingFilters = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading filters: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          _buildHeaderCard(),
          _buildSearchBox(),
          _buildFiltersRow(),
          _buildDateSelector(),
          _buildListHeader(),
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
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchText = "";
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
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
      ),
    );
  }

  Widget _buildFiltersRow() {
    if (_isLoadingFilters) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              child: DropdownButtonFormField<String>(
                value: _selectedClassFilter,
                hint: const Text("All Classes"),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Filter by Class",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.filter_list, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text("All Classes")),
                  ..._availableClasses.map((className) {
                    return DropdownMenuItem<String>(
                      value: className,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(className, overflow: TextOverflow.ellipsis),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedClassFilter = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              child: DropdownButtonFormField<String>(
                value: _selectedSectionFilter,
                hint: const Text("All Sections"),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Filter by Section",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.group, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text("All Sections")),
                  ..._availableSections.map((section) {
                    return DropdownMenuItem<String>(
                      value: section,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Text("Section $section", overflow: TextOverflow.ellipsis),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSectionFilter = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final currentYear = DateTime.now().year;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              child: DropdownButtonFormField<int>(
                value: _selectedMonth,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Month",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.calendar_month, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: List.generate(12, (i) {
                  return DropdownMenuItem<int>(
                    value: i + 1,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        _months[i],
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              child: DropdownButtonFormField<int>(
                value: _selectedYear,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Year",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.calendar_today, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  for (int i = -2; i <= 3; i++)
                    DropdownMenuItem<int>(
                      value: currentYear + i,
                      child: Text((currentYear + i).toString()),
                    ),
                ],
                onChanged: (v) => setState(() => _selectedYear = v!),
              ),
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
          SizedBox(width: 80),
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

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  "Error loading classes",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
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
        if (_searchText.isNotEmpty) {
          classList = classList.where((classInfo) {
            final fullName = "${classInfo['className']} ${classInfo['section']}".toLowerCase();
            return fullName.contains(_searchText);
          }).toList();
        }

        // Apply class filter
        if (_selectedClassFilter != null && _selectedClassFilter!.isNotEmpty) {
          classList = classList.where((classInfo) {
            return classInfo['className'] == _selectedClassFilter;
          }).toList();
        }

        // Apply section filter
        if (_selectedSectionFilter != null && _selectedSectionFilter!.isNotEmpty) {
          classList = classList.where((classInfo) {
            return classInfo['section'] == _selectedSectionFilter;
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

        return RefreshIndicator(
          onRefresh: _loadFilters,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classList.length,
            itemBuilder: (context, index) {
              final classInfo = classList[index];
              final className = classInfo['className'];
              final section = classInfo['section'];
              final studentCount = classInfo['studentCount'];
              final displaySection = section.isEmpty ? "A" : section;
              final hasStudents = studentCount > 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: hasStudents
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminMonthlyAttendancePage(
                          schoolId: widget.schoolId,
                          className: className,
                          section: displaySection,
                          month: _selectedMonth,
                          year: _selectedYear,
                        ),
                      ),
                    );
                  }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: hasStudents
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.class_,
                            color: hasStudents
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
                                  color: hasStudents
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Section: $displaySection",
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hasStudents
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "$studentCount Student${studentCount != 1 ? 's' : ''}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hasStudents
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
                        if (hasStudents)
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
                        if (!hasStudents)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              );
            },
          ),
        );
      },
    );
  }
}