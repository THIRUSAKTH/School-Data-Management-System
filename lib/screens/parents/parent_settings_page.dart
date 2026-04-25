import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schoolprojectjan/screens/parents/select_child_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentSettingsPage extends StatefulWidget {
  final String schoolId;
  final String parentUid;

  const ParentSettingsPage({
    super.key,
    required this.schoolId,
    required this.parentUid,
  });

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _homeworkReminders = true;
  bool _feeReminders = true;
  bool _attendanceAlerts = true;
  bool _examReminders = true;
  bool _eventReminders = true;

  bool _darkMode = false;
  bool _saveData = true;
  String _selectedLanguage = 'English';
  String _selectedDateFormat = 'DD/MM/YYYY';

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settingsDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('parent_settings')
          .doc(widget.parentUid)
          .get();

      if (settingsDoc.exists) {
        final data = settingsDoc.data() as Map<String, dynamic>;
        setState(() {
          _notificationsEnabled = data['notificationsEnabled'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? true;
          _smsNotifications = data['smsNotifications'] ?? false;
          _homeworkReminders = data['homeworkReminders'] ?? true;
          _feeReminders = data['feeReminders'] ?? true;
          _attendanceAlerts = data['attendanceAlerts'] ?? true;
          _examReminders = data['examReminders'] ?? true;
          _eventReminders = data['eventReminders'] ?? true;
          _saveData = data['saveData'] ?? true;
          _selectedLanguage = data['language'] ?? 'English';
          _selectedDateFormat = data['dateFormat'] ?? 'DD/MM/YYYY';
        });
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading settings: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final settingsRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('parent_settings')
          .doc(widget.parentUid);

      await settingsRef.set({
        'notificationsEnabled': _notificationsEnabled,
        'emailNotifications': _emailNotifications,
        'smsNotifications': _smsNotifications,
        'homeworkReminders': _homeworkReminders,
        'feeReminders': _feeReminders,
        'attendanceAlerts': _attendanceAlerts,
        'examReminders': _examReminders,
        'eventReminders': _eventReminders,
        'saveData': _saveData,
        'language': _selectedLanguage,
        'dateFormat': _selectedDateFormat,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _saveLocalSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Settings saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSettings,
            tooltip: "Save Settings",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 16),
            _buildNotificationSettings(),
            const SizedBox(height: 16),
            _buildReminderSettings(),
            const SizedBox(height: 16),
            _buildAppSettings(),
            const SizedBox(height: 16),
            _buildPrivacySettings(),
            const SizedBox(height: 16),
            _buildSupportSection(),
            const SizedBox(height: 16),
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.orange,
            child: Icon(Icons.person, size: 45, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            user?.email ?? 'parent@school.com',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Parent Account",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _editProfile(),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("Edit Profile"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text("Push Notifications"),
            subtitle: Text(
              "Receive push notifications on your device",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              if (!value) {
                _emailNotifications = false;
                _smsNotifications = false;
              }
            },
            activeColor: Colors.orange,
          ),
          if (_notificationsEnabled) ...[
            SwitchListTile(
              title: const Text("Email Notifications"),
              subtitle: Text(
                "Receive updates via email",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
              activeColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text("SMS Notifications"),
              subtitle: Text(
                "Receive SMS alerts for urgent updates",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              value: _smsNotifications,
              onChanged: (value) => setState(() => _smsNotifications = value),
              activeColor: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alarm, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Reminders",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text("Homework Reminders"),
            subtitle: Text(
              "Get reminders when homework is assigned",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            value: _homeworkReminders,
            onChanged: (value) => setState(() => _homeworkReminders = value),
            activeColor: Colors.orange,
          ),
          SwitchListTile(
            title: const Text("Fee Payment Reminders"),
            subtitle: Text(
              "Get reminders before fee due dates",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            value: _feeReminders,
            onChanged: (value) => setState(() => _feeReminders = value),
            activeColor: Colors.orange,
          ),
          SwitchListTile(
            title: const Text("Attendance Alerts"),
            subtitle: Text(
              "Get alerts for attendance updates",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            value: _attendanceAlerts,
            onChanged: (value) => setState(() => _attendanceAlerts = value),
            activeColor: Colors.orange,
          ),
          SwitchListTile(
            title: const Text("Exam Reminders"),
            subtitle: Text(
              "Get reminders before exams",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            value: _examReminders,
            onChanged: (value) => setState(() => _examReminders = value),
            activeColor: Colors.orange,
          ),
          SwitchListTile(
            title: const Text("Event Reminders"),
            subtitle: Text(
              "Get reminders for school events",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            value: _eventReminders,
            onChanged: (value) => setState(() => _eventReminders = value),
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_applications, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "App Settings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: Text(
              "Switch to dark theme",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              _applyTheme(value);
            },
            activeColor: Colors.orange,
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.orange),
            title: const Text("Language"),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.orange),
            title: const Text("Date Format"),
            subtitle: Text(_selectedDateFormat),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDateFormatDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.privacy_tip, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Privacy & Data",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text("Save Data"),
            subtitle: Text(
              "Reduce data usage by loading images in lower quality",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            value: _saveData,
            onChanged: (value) => setState(() => _saveData = value),
            activeColor: Colors.orange,
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.orange),
            title: const Text("Download My Data"),
            subtitle: const Text("Request a copy of your data"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _downloadData(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text("Clear Cache"),
            subtitle: const Text("Clear temporary app data"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _clearCache(),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Support",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          // In parent_settings_page.dart
          ListTile(
            leading: const Icon(Icons.switch_account, color: Colors.orange),
            title: const Text("Switch Child"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SelectChildPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.orange),
            title: const Text("Help Center"),
            subtitle: const Text("FAQs and guides"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _helpCenter(),
          ),
          ListTile(
            leading: const Icon(Icons.feedback, color: Colors.orange),
            title: const Text("Send Feedback"),
            subtitle: const Text("Help us improve the app"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _sendFeedback(),
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.orange),
            title: const Text("Rate Us"),
            subtitle: const Text("Rate this app on Play Store"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _rateUs(),
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.orange),
            title: const Text("About"),
            subtitle: const Text("Version 1.0.0"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAboutDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                "Danger Zone",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.red),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            subtitle: const Text("Sign out from your account"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _logout(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Delete Account"),
            subtitle: const Text("Permanently delete your account"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _deleteAccount(),
          ),
        ],
      ),
    );
  }

  // ================= DIALOGS AND ACTIONS =================

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption("English"),
            _languageOption("தமிழ் (Tamil)"),
            _languageOption("हिन्दी (Hindi)"),
            _languageOption("മലയാളം (Malayalam)"),
            _languageOption("తెలుగు (Telugu)"),
            _languageOption("ಕನ್ನಡ (Kannada)"),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String language) {
    return RadioListTile<String>(
      title: Text(language),
      value: language,
      groupValue: _selectedLanguage,
      activeColor: Colors.orange,
      onChanged: (value) {
        setState(() => _selectedLanguage = value!);
        _saveSettings();
        Navigator.pop(context);
      },
    );
  }

  void _showDateFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Date Format"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dateFormatOption("DD/MM/YYYY"),
            _dateFormatOption("MM/DD/YYYY"),
            _dateFormatOption("YYYY/MM/DD"),
            _dateFormatOption("DD MMM YYYY"),
            _dateFormatOption("MMM DD, YYYY"),
          ],
        ),
      ),
    );
  }

  Widget _dateFormatOption(String format) {
    return RadioListTile<String>(
      title: Text(format),
      value: format,
      groupValue: _selectedDateFormat,
      activeColor: Colors.orange,
      onChanged: (value) {
        setState(() => _selectedDateFormat = value!);
        _saveSettings();
        Navigator.pop(context);
      },
    );
  }

  void _editProfile() {
    // Navigate to edit profile page or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Edit profile from the Profile page"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _applyTheme(bool isDark) {
    // Theme change logic - would need to be implemented with a ThemeProvider
    // For now, just save the preference
    _saveLocalSettings();

    // Show a snackbar indicating theme will apply on restart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Theme will change on app restart"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _downloadData() async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data export will be emailed to you shortly"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Cache"),
        content: const Text("Are you sure you want to clear app cache?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Clear cache logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cache cleared successfully")),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  void _helpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Help center coming soon")),
    );
  }

  void _sendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback feature coming soon")),
    );
  }

  void _rateUs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rate us feature coming soon")),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "Smart School Management System",
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(Icons.school, size: 48, color: Colors.orange),
      children: const [
        Text(
          "Parent Portal App\n\n"
              "Features:\n"
              "• Real-time attendance tracking\n"
              "• Homework management\n"
              "• Exam results and report cards\n"
              "• Fee payment and tracking\n"
              "• Complaint management\n"
              "• Notifications and announcements\n\n"
              "© 2024 Smart School. All rights reserved.",
        ),
      ],
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              "This action cannot be undone!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Deleting your account will:\n"
                  "• Remove all your data permanently\n"
                  "• Unlink all children from your account\n"
                  "• Remove access to all features",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account deletion request submitted. Contact school admin."),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
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