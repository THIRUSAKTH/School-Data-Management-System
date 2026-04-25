import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class NoticePostPage extends StatefulWidget {
  const NoticePostPage({super.key});

  @override
  State<NoticePostPage> createState() => _NoticePostPageState();
}

class _NoticePostPageState extends State<NoticePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _priority = "Normal";
  String _targetAudience = "All";
  List<String> _selectedClasses = [];
  List<String> _selectedSections = [];

  DateTime? _expiryDate;
  bool _isPinned = false;
  bool _isLoading = false;

  // Available options
  final List<String> _priorityOptions = ["Normal", "Important", "Urgent"];
  final List<String> _audienceOptions = ["All", "Students", "Parents", "Teachers", "Specific Class"];

  List<String> _availableClasses = [];
  List<String> _availableSections = ['A', 'B', 'C', 'D'];

  // Colors for priorities
  final Map<String, Color> _priorityColors = {
    "Normal": Colors.blue,
    "Important": Colors.orange,
    "Urgent": Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('classes')
          .get();

      setState(() {
        _availableClasses = classesSnapshot.docs
            .map((doc) => doc['class'] as String)
            .where((className) => className.isNotEmpty)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Post Notice",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _showPreview,
            tooltip: "Preview",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildFormCard(),
            const SizedBox(height: 20),
            _buildOptionsCard(),
            const SizedBox(height: 20),
            if (_titleController.text.isNotEmpty || _messageController.text.isNotEmpty)
              _buildPreviewCard(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.announcement,
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
                  "Create Notice",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Share important announcements with everyone",
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

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Notice Details",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Title Field
          TextField(
            controller: _titleController,
            decoration: _buildInputDecoration(
              "Enter notice title",
              Icons.title,
            ),
          ),
          const SizedBox(height: 16),

          // Message Field
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: _buildInputDecoration(
              "Enter notice details...",
              Icons.description,
            ),
          ),
          const SizedBox(height: 16),

          // Priority Dropdown
          Row(
            children: [
              const Icon(Icons.priority_high, size: 20, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text("Priority:"),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  items: _priorityOptions.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _priorityColors[p],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(p),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _priority = value!),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Additional Options",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Target Audience
          Row(
            children: [
              const Icon(Icons.people, size: 20, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text("Target Audience:"),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _targetAudience,
                  items: _audienceOptions.map((audience) {
                    return DropdownMenuItem(
                      value: audience,
                      child: Text(audience),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _targetAudience = value!),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),

          // Specific Class Selection (if applicable)
          if (_targetAudience == "Specific Class") ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              "Select Classes",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (_availableClasses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "No classes available. Please add classes first.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableClasses.map((className) {
                  final isSelected = _selectedClasses.contains(className);
                  return FilterChip(
                    label: Text(className),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedClasses.add(className);
                        } else {
                          _selectedClasses.remove(className);
                        }
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.deepPurple.shade100,
                    checkmarkColor: Colors.deepPurple,
                  );
                }).toList(),
              ),
          ],

          const SizedBox(height: 16),

          // Expiry Date
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text("Expiry Date:"),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: _selectExpiryDate,
                  child: Text(
                    _expiryDate == null
                        ? "No expiry (Optional)"
                        : DateFormat('dd MMM yyyy').format(_expiryDate!),
                    style: TextStyle(
                      color: _expiryDate == null ? Colors.grey : Colors.deepPurple,
                    ),
                  ),
                ),
              ),
              if (_expiryDate != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _expiryDate = null),
                ),
            ],
          ),

          // Pin Notice
          SwitchListTile(
            title: const Text("Pin this notice"),
            subtitle: const Text("Pinned notices appear at the top"),
            value: _isPinned,
            onChanged: (value) => setState(() => _isPinned = value),
            activeColor: Colors.deepPurple,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Preview",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _priorityColors[_priority]?.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _priorityColors[_priority]?.withValues(alpha: 0.3) ?? Colors.grey,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _priorityColors[_priority],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _priority.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_isPinned)
                      const Icon(Icons.push_pin, size: 16, color: Colors.deepPurple),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _titleController.text.isEmpty ? "Notice Title" : _titleController.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _messageController.text.isEmpty
                      ? "Notice message will appear here..."
                      : _messageController.text,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Posted by: Admin • ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isValid = _titleController.text.isNotEmpty && _messageController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading || !isValid ? null : _publishNotice,
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.send),
        label: Text(_isLoading ? "Publishing..." : "Publish Notice"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _publishNotice() async {
    if (_titleController.text.trim().isEmpty) {
      _showError("Please enter a title");
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      _showError("Please enter a message");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      final adminName = adminUser?.email?.split('@').first ?? "Admin";

      final noticeData = {
        "title": _titleController.text.trim(),
        "description": _messageController.text.trim(),
        "priority": _priority,
        "targetAudience": _targetAudience,
        "selectedClasses": _targetAudience == "Specific Class" ? _selectedClasses : [],
        "isPinned": _isPinned,
        "expiryDate": _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        "createdBy": adminName,
        "createdByUid": adminUser?.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "isActive": true,
        "viewCount": 0,
      };

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notices')
          .add(noticeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notice published successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _priority = "Normal";
          _targetAudience = "All";
          _selectedClasses.clear();
          _isPinned = false;
          _expiryDate = null;
        });
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPreview() {
    if (_titleController.text.isEmpty && _messageController.text.isEmpty) {
      _showError("Add some content to preview");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Notice Preview"),
        content: SizedBox(
          width: double.maxFinite,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _priorityColors[_priority]?.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _priorityColors[_priority],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _priority.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_isPinned)
                      const Icon(Icons.push_pin, size: 16, color: Colors.deepPurple),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _titleController.text.isEmpty ? "Notice Title" : _titleController.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _messageController.text.isEmpty
                      ? "Notice message will appear here..."
                      : _messageController.text,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Text(
                  "Target: $_targetAudience",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
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
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
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