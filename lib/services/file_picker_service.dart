// lib/services/file_picker_service.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schoolprojectjan/app_config.dart';

class FilePickerService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'];

  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  static Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return true;
    }
    return true;
  }

  // Pick multiple files
  static Future<List<File>> pickFiles({bool allowMultiple = true}) async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      debugPrint('Storage permission denied');
      return [];
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.custom,
        allowedExtensions: [...allowedImageTypes, ...allowedDocumentTypes],
      );

      if (result != null) {
        List<File> files = [];
        for (var path in result.paths) {
          if (path != null) {
            files.add(File(path));
          }
        }
        return files;
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
    return [];
  }

  // Pick images from gallery
  static Future<List<File>> pickImages({bool allowMultiple = true}) async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      debugPrint('Storage permission denied');
      return [];
    }

    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        return images.map((xfile) => File(xfile.path)).toList();
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
    return [];
  }

  // Upload single file to Firebase Storage
  static Future<Map<String, dynamic>?> uploadFile({
    required File file,
    required String folder,
  }) async {
    try {
      // Get file info
      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      final fileSize = await file.length();

      // Check file size
      if (fileSize > maxFileSize) {
        debugPrint('File too large: ${fileSize} bytes');
        return null;
      }

      // Create unique file name
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Create storage reference
      final ref = _storage
          .ref()
          .child('schools')
          .child(AppConfig.schoolId)
          .child(folder)
          .child(uniqueFileName);

      // Upload file
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Determine file type
      String fileType = 'other';
      if (allowedImageTypes.contains(extension)) {
        fileType = 'image';
      } else if (allowedDocumentTypes.contains(extension)) {
        fileType = 'document';
      }

      return {
        'name': uniqueFileName,
        'originalName': fileName,
        'url': downloadUrl,
        'type': fileType,
        'extension': extension,
        'size': fileSize,
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
      // Add small delay between uploads
      await Future.delayed(const Duration(milliseconds: 500));
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

  static String getReadableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}