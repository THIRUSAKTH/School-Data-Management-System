import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  bool loading = true;

  File? logoImage;
  String logoUrl = "";

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadSchool();
  }

  /// LOAD SCHOOL DATA
  Future<void> loadSchool() async {

    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .get();

    if (doc.exists) {

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      nameController.text = data['schoolName'] ?? "";
      addressController.text = data['address'] ?? "";
      phoneController.text = data['phone'] ?? "";
      logoUrl = data['logoUrl'] ?? "";
    }

    setState(() {
      loading = false;
    });
  }

  /// PICK IMAGE
  Future<void> pickLogo() async {

    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        logoImage = File(picked.path);
      });
    }
  }

  /// UPLOAD LOGO
  Future<void> uploadLogo() async {

    if (logoImage == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child('school_logos')
        .child('${widget.schoolId}.png');

    await ref.putFile(logoImage!);

    String url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .update({
      "logoUrl": url
    });

    setState(() {
      logoUrl = url;
      logoImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logo Updated")),
    );
  }

  /// SAVE SCHOOL INFO
  Future<void> saveSchool() async {

    await FirebaseFirestore.instance
        .collection('schoolprofile')
        .doc(widget.schoolId)
        .update({
      "schoolName": nameController.text,
      "address": addressController.text,
      "phone": phoneController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("School details updated")),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("School Settings"),
        backgroundColor: Colors.blue,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// LOGO PREVIEW
            GestureDetector(
              onTap: pickLogo,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[300],
                backgroundImage: logoImage != null
                    ? FileImage(logoImage!)
                    : (logoUrl.isNotEmpty
                    ? NetworkImage(logoUrl)
                    : null) as ImageProvider?,
                child: logoImage == null && logoUrl.isEmpty
                    ? const Icon(Icons.camera_alt, size: 30)
                    : null,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: uploadLogo,
              child: const Text("Upload Logo"),
            ),

            const SizedBox(height: 30),

            /// SCHOOL NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "School Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// ADDRESS
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// PHONE
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveSchool,
                child: const Text("Save Settings"),
              ),
            )
          ],
        ),
      ),
    );
  }
}