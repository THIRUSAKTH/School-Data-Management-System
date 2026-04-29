import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../app_config.dart';

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = "all";
  bool _isLoading = false;

  // Store response text for each complaint
  final Map<String, TextEditingController> _responseControllers = {};

  final List<String> _statusFilters = [
    "all",
    "pending",
    "in_progress",
    "resolved",
    "rejected",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _responseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getResponseController(
    String complaintId,
    String? initialValue,
  ) {
    if (!_responseControllers.containsKey(complaintId)) {
      _responseControllers[complaintId] = TextEditingController(
        text: initialValue ?? '',
      );
    }
    return _responseControllers[complaintId]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Complaints Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pending), text: "All Complaints"),
            Tab(icon: Icon(Icons.bar_chart), text: "Statistics"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildComplaintsList(), _buildStatisticsTab()],
      ),
    );
  }

  Widget _buildComplaintsList() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('schools')
                    .doc(AppConfig.schoolId)
                    .collection('complaints')
                    .orderBy('createdAt', descending: true)
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
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Error loading complaints",
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
                      Icon(
                        Icons.feedback_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Complaints',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complaints from parents will appear here',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              var complaints = snapshot.data!.docs;
              if (_selectedFilter != "all") {
                complaints =
                    complaints.where((c) {
                      final data = c.data() as Map<String, dynamic>;
                      return data['status'] == _selectedFilter;
                    }).toList();
              }

              if (complaints.isEmpty) {
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
                        'No ${_selectedFilter.toUpperCase()} complaints',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    final data = complaint.data() as Map<String, dynamic>;
                    return _buildComplaintCard(complaint.id, data);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': 'all', 'color': Colors.grey},
      {'label': 'Pending', 'value': 'pending', 'color': Colors.orange},
      {'label': 'In Progress', 'value': 'in_progress', 'color': Colors.blue},
      {'label': 'Resolved', 'value': 'resolved', 'color': Colors.green},
      {'label': 'Rejected', 'value': 'rejected', 'color': Colors.red},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : filter['color'] as Color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter =
                      selected ? filter['value'] as String : "all";
                });
              },
              backgroundColor: Colors.white,
              selectedColor: filter['color'] as Color,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: (filter['color'] as Color).withOpacity(0.3),
              ),
              shape: const StadiumBorder(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComplaintCard(String complaintId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final createdAt = data['createdAt'] as Timestamp?;
    final statusConfig = _getStatusConfig(status);
    final responseController = _getResponseController(
      complaintId,
      data['response'],
    );
    bool isProcessing = false;

    return StatefulBuilder(
      builder: (context, setStateCard) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side:
                status == 'pending'
                    ? BorderSide(color: Colors.orange.shade300, width: 1.5)
                    : BorderSide.none,
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: statusConfig['color'].withOpacity(0.1),
              child: Icon(
                statusConfig['icon'],
                color: statusConfig['color'],
                size: 20,
              ),
            ),
            title: Text(
              data['title'] ?? 'Complaint',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${data['studentName']} (${data['studentClass'] ?? 'N/A'}-${data['studentSection'] ?? 'N/A'})",
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  data['category'] ?? 'General',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusConfig['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusConfig['label'],
                style: TextStyle(
                  color: statusConfig['color'],
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Complaint Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Complaint Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['description'] ?? 'No description',
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Submitted: ${createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate()) : 'Unknown'}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Response Section
                    const Text(
                      "Response",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: responseController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Type your response here...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: "Update Status",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'pending',
                          child: Text(
                            'Pending',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'in_progress',
                          child: Text(
                            'In Progress',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'resolved',
                          child: Text(
                            'Resolved',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'rejected',
                          child: Text(
                            'Rejected',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          _updateComplaintStatus(complaintId, newStatus);
                          setStateCard(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Submit Response Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            isProcessing
                                ? null
                                : () async {
                                  setStateCard(() => isProcessing = true);
                                  await _submitResponse(
                                    complaintId,
                                    responseController.text.trim(),
                                    status,
                                  );
                                  setStateCard(() => isProcessing = false);
                                },
                        icon:
                            isProcessing
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.send, size: 18),
                        label: Text(
                          isProcessing ? "Sending..." : "Send Response",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateComplaintStatus(
    String complaintId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('complaints')
          .doc(complaintId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to ${newStatus.toUpperCase()}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitResponse(
    String complaintId,
    String response,
    String currentStatus,
  ) async {
    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a response before sending"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Determine new status (if resolved, set to resolved)
      String newStatus = currentStatus;
      if (currentStatus == 'pending' || currentStatus == 'in_progress') {
        newStatus = 'resolved';
      }

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('complaints')
          .doc(complaintId)
          .update({
            'response': response,
            'status': newStatus,
            'respondedBy': 'Admin',
            'respondedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Response sent successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatisticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('complaints')
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
                Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No Data Available",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        int pending = 0;
        int inProgress = 0;
        int resolved = 0;
        int rejected = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          switch (status) {
            case 'pending':
              pending++;
              break;
            case 'in_progress':
              inProgress++;
              break;
            case 'resolved':
              resolved++;
              break;
            case 'rejected':
              rejected++;
              break;
          }
        }

        final total = pending + inProgress + resolved + rejected;
        final resolutionRate = total > 0 ? (resolved / total) * 100 : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.lightBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Total Complaints",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$total",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Resolution Rate: ${resolutionRate.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Statistics Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatCard(
                    "Pending",
                    pending,
                    Colors.orange,
                    Icons.pending,
                  ),
                  _buildStatCard(
                    "In Progress",
                    inProgress,
                    Colors.blue,
                    Icons.hourglass_empty,
                  ),
                  _buildStatCard(
                    "Resolved",
                    resolved,
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildStatCard(
                    "Rejected",
                    rejected,
                    Colors.red,
                    Icons.cancel,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Breakdown
              _buildCategoryBreakdown(snapshot.data!.docs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<QueryDocumentSnapshot> complaints) {
    Map<String, int> categoryCount = {};

    for (var doc in complaints) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] ?? 'Other';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    final categories = categoryCount.keys.toList();
    categories.sort();

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Category Breakdown",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(category, style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: categoryCount[category]! / complaints.length,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${categoryCount[category]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'resolved':
        return {
          'label': 'RESOLVED',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'in_progress':
        return {
          'label': 'IN PROGRESS',
          'color': Colors.blue,
          'icon': Icons.hourglass_empty,
        };
      case 'rejected':
        return {'label': 'REJECTED', 'color': Colors.red, 'icon': Icons.cancel};
      default:
        return {
          'label': 'PENDING',
          'color': Colors.orange,
          'icon': Icons.pending,
        };
    }
  }
}
