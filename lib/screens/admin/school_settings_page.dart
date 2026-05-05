import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _establishedYearController =
      TextEditingController();
  final TextEditingController _principalNameController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  // Support both mobile and web
  XFile? _selectedImage;
  String _logoUrl = "";
  String? _schoolCode;

  final ImagePicker _picker = ImagePicker();

  // Check platform
  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _establishedYearController.dispose();
    _principalNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSchoolData() async {
    setState(() => _isLoading = true);

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        _nameController.text = data['schoolName'] ?? "";
        _addressController.text = data['address'] ?? "";
        _phoneController.text = data['phone'] ?? "";
        _emailController.text = data['email'] ?? "";
        _websiteController.text = data['website'] ?? "";
        _establishedYearController.text = data['establishedYear'] ?? "";
        _principalNameController.text = data['principalName'] ?? "";
        _logoUrl = data['logoUrl'] ?? "";
        _schoolCode =
            data['schoolCode'] ?? "SCH${widget.schoolId.substring(0, 4)}";
      }
    } catch (e) {
      _showError("Error loading school data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
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
                    if (!isWeb) // Camera not fully supported on web
                      _buildImageSourceOption(
                        icon: Icons.camera_alt,
                        label: "Camera",
                        onTap: () async {
                          Navigator.pop(context);
                          final picked = await _picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (picked != null) {
                            setState(() => _selectedImage = picked);
                          }
                        },
                      ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: "Gallery",
                      onTap: () async {
                        Navigator.pop(context);
                        final picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setState(() => _selectedImage = picked);
                        }
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.delete,
                      label: "Remove",
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedImage = null;
                          _logoUrl = "";
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

  Future<Uint8List?> _getImageBytes() async {
    if (_selectedImage == null) return null;
    return await _selectedImage!.readAsBytes();
  }

  Future<void> _uploadLogo() async {
    if (_selectedImage == null) {
      _showError("Please select an image first");
      return;
    }

    setState(() => _isUploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('school_logos')
          .child(
            '${widget.schoolId}_${DateTime.now().millisecondsSinceEpoch}.png',
          );

      // Upload based on platform
      if (isWeb) {
        // Web platform - upload bytes
        final bytes = await _selectedImage!.readAsBytes();
        await ref.putData(bytes);
      } else {
        // Mobile platform - upload file
        final file = File(_selectedImage!.path);
        await ref.putFile(file);
      }

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .update({"logoUrl": url});

      setState(() {
        _logoUrl = url;
        _selectedImage = null;
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
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveSchool() async {
    if (_nameController.text.trim().isEmpty) {
      _showError("School name is required");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final schoolData = {
        "schoolName": _nameController.text.trim(),
        "address": _addressController.text.trim(),
        "phone": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
        "website": _websiteController.text.trim(),
        "establishedYear": _establishedYearController.text.trim(),
        "principalName": _principalNameController.text.trim(),
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
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // Helper to get image provider for display
  ImageProvider? _getImageProvider() {
    if (_selectedImage != null) {
      if (isWeb) {
        // For web, we need to load the image differently
        return NetworkImage(_selectedImage!.path);
      } else {
        return FileImage(File(_selectedImage!.path));
      }
    }
    if (_logoUrl.isNotEmpty) {
      return NetworkImage(_logoUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            onPressed: _loadSchoolData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLogoSecion(),
            const SizedBox(height: 20),
            _buildSchoolInfoCard(),
            const SizedBox(height: 20),
            _buildContactInfoCard(),
            const SizedBox(height: 20),
            _buildAdditionalInfoCard(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSecion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 65,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _getImageProvider(),
                onBackgroundImageError: (_, __) {
                  setState(() {
                    _logoUrl = "";
                  });
                },
                child:
                    _selectedImage == null && _logoUrl.isEmpty
                        ? Icon(
                          Icons.add_photo_alternate,
                          size: 45,
                          color: Colors.grey.shade400,
                        )
                        : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedImage != null
                ? "New logo selected - tap upload to save"
                : (_logoUrl.isNotEmpty
                    ? "Tap to change logo"
                    : "Tap to add logo"),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadLogo,
                  icon:
                      _isUploading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.cloud_upload, size: 18),
                  label: Text(_isUploading ? "Uploading..." : "Upload Logo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _selectedImage = null);
                  },
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text("Cancel"),
                ),
              ],
            ),
          ],
          if (_logoUrl.isNotEmpty && _selectedImage == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Logo saved",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
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
                child: const Icon(Icons.business, color: Colors.blue, size: 22),
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
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "School Name *",
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
              hintText: "Enter school name",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Address",
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
              hintText: "Enter school address",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _principalNameController,
            decoration: const InputDecoration(
              labelText: "Principal Name",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
              hintText: "Enter principal's name",
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
                      fontSize: 14,
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
                child: const Icon(
                  Icons.contact_phone,
                  color: Colors.blue,
                  size: 22,
                ),
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
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Phone Number",
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
              hintText: "Enter contact number",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Email Address",
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
              hintText: "Enter email address",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: "Website",
              prefixIcon: Icon(Icons.language),
              border: OutlineInputBorder(),
              hintText: "Enter website URL",
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
                child: const Icon(Icons.info, color: Colors.blue, size: 22),
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
            controller: _establishedYearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Established Year",
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
              hintText: "e.g., 2000",
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
        onPressed: _isSaving ? null : _saveSchool,
        icon:
            _isSaving
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Icon(Icons.save),
        label: Text(_isSaving ? "Saving..." : "Save Settings"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
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
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}