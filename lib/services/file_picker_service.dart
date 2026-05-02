// lib/services/file_picker_service.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:schoolprojectjan/app_config.dart';

class FilePickerService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Allowed file types
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'];

  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Pick multiple files
  static Future<List<File>> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? [...allowedImageTypes, ...allowedDocumentTypes],
      );

      if (result != null) {
        return result.paths.map((path) => File(path!)).toList();
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
    return [];
  }

  // Pick images from gallery
  static Future<List<File>> pickImages({bool allowMultiple = true}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.image,
      );

      if (result != null) {
        return result.paths.map((path) => File(path!)).toList();
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
    return [];
  }

  // Upload file to Firebase Storage
  static Future<Map<String, dynamic>?> uploadFile({
    required File file,
    required String folder, // 'notices' or 'homework'
    String? fileName,
  }) async {
    try {
      final extension = file.path.split('.').last;
      final uniqueFileName = fileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      final ref = _storage
          .ref()
          .child('schools')
          .child(AppConfig.schoolId)
          .child(folder)
          .child(uniqueFileName);

      // Upload with progress tracking
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Determine file type
      String fileType = 'other';
      if (allowedImageTypes.contains(extension.toLowerCase())) {
        fileType = 'image';
      } else if (allowedDocumentTypes.contains(extension.toLowerCase())) {
        fileType = 'document';
      }

      return {
        'name': uniqueFileName,
        'originalName': file.path.split('/').last,
        'url': downloadUrl,
        'type': fileType,
        'extension': extension,
        'size': await file.length(),
        'uploadedAt': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Upload multiple files
  static Future<List<Map<String, dynamic>>> uploadMultipleFiles({
    required List<File> files,
    required String folder,
  }) async {
    List<Map<String, dynamic>> uploadedFiles = [];

    for (var file in files) {
      final result = await uploadFile(file: file, folder: folder);
      if (result != null) {
        uploadedFiles.add(result);
      }
    }

    return uploadedFiles;
  }

  // Delete file from storage
  static Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  // Get file size in readable format
  static String getReadableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}