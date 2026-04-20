import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SchoolSettingsPage extends StatefulWidget {
  final String schoolId;

  const SchoolSettingsPage({super.key, required this.schoolId});

  @override
  State<SchoolSettingsPage> createState() => _SchoolSettingsPageState();
}

class _SchoolSettingsPageState extends State<SchoolSettingsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController establishedYearController = TextEditingController();
  final TextEditingController principalNameController = TextEditingController();

  bool loading = true;
  bool isSaving = false;
  bool isUploading = false;

  File? logoImage;
  String logoUrl = "";
  String? _schoolCode;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadSchool();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    establishedYearController.dispose();
    principalNameController.dispose();
    super.dispose();
  }

  /// LOAD SCHOOL DATA
  Future<void> loadSchool() async {
    setState(() => loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        nameController.text = data['schoolName'] ?? "";
        addressController.text = data['address'] ?? "";
        phoneController.text = data['phone'] ?? "";
        emailController.text = data['email'] ?? "";
        websiteController.text = data['website'] ?? "";
        establishedYearController.text = data['establishedYear'] ?? "";
        principalNameController.text = data['principalName'] ?? "";
        logoUrl = data['logoUrl'] ?? "";
        _schoolCode = data['schoolCode'] ?? "SCH${widget.schoolId.substring(0, 4)}";
      }
    } catch (e) {
      _showError("Error loading school data: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  /// PICK IMAGE
  Future<void> pickLogo() async {
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
              "Choose Logo",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await picker.pickImage(source: ImageSource.camera);
                    if (picked != null) {
                      setState(() => logoImage = File(picked.path));
                    }
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() => logoImage = File(picked.path));
                    }
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.delete,
                  label: "Remove",
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      logoImage = null;
                      logoUrl = "";
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 30, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// UPLOAD LOGO
  Future<void> uploadLogo() async {
    if (logoImage == null) {
      _showError("Please select an image first");
      return;
    }

    setState(() => isUploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('school_logos')
          .child('${widget.schoolId}.png');

      await ref.putFile(logoImage!);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .update({"logoUrl": url});

      setState(() {
        logoUrl = url;
        logoImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logo uploaded successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError("Error uploading logo: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  /// SAVE SCHOOL INFO
  Future<void> saveSchool() async {
    if (nameController.text.trim().isEmpty) {
      _showError("School name is required");
      return;
    }

    setState(() => isSaving = true);

    try {
      final schoolData = {
        "schoolName": nameController.text.trim(),
        "address": addressController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "website": websiteController.text.trim(),
        "establishedYear": establishedYearController.text.trim(),
        "principalName": principalNameController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .update(schoolData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("School details updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError("Error saving school details: $e");
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "School Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadSchool,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Logo Section
            _buildLogoSecion(),
            const SizedBox(height: 20),

            // School Information Card
            _buildSchoolInfoCard(),
            const SizedBox(height: 20),

            // Contact Information Card
            _buildContactInfoCard(),
            const SizedBox(height: 20),

            // Additional Information Card
            _buildAdditionalInfoCard(),
            const SizedBox(height: 24),

            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSecion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          GestureDetector(
            onTap: pickLogo,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: logoImage != null
                    ? FileImage(logoImage!)
                    : (logoUrl.isNotEmpty
                    ? NetworkImage(logoUrl)
                    : null) as ImageProvider?,
                child: logoImage == null && logoUrl.isEmpty
                    ? Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            logoImage != null ? "New logo selected" : (logoUrl.isNotEmpty ? "Tap to change logo" : "Tap to add logo"),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (logoImage != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isUploading ? null : uploadLogo,
                  icon: isUploading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.cloud_upload),
                  label: Text(isUploading ? "Uploading..." : "Upload Logo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() => logoImage = null);
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text("Cancel"),
                ),
              ],
            ),
          ],
          if (logoUrl.isNotEmpty && logoImage == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Logo saved successfully",
                style: TextStyle(fontSize: 11, color: Colors.green.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSchoolInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              const Text(
                "School Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "School Name",
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Address",
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: principalNameController,
            decoration: const InputDecoration(
              labelText: "Principal Name",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          if (_schoolCode != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text("School Code:"),
                  const SizedBox(width: 8),
                  Text(
                    _schoolCode!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.contact_phone, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              const Text(
                "Contact Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Phone Number",
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Email Address",
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: websiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: "Website",
              prefixIcon: Icon(Icons.language),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              const Text(
                "Additional Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: establishedYearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Established Year",
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : saveSchool,
        icon: isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.save),
        label: Text(isSaving ? "Saving..." : "Save Settings"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
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