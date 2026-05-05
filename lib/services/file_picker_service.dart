import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// Conditional imports - only on web
// Using 'dart:html' will not be available on Android, so we use conditional export
import 'package:universal_html/html.dart' as html;

// Platform detection helpers - using kIsWeb which works everywhere
bool get isWeb => kIsWeb;
bool get isMobile => !kIsWeb;

class FilePickerService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Format file size
  static String getReadableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Pick multiple files (Works on Web & Android)
  static Future<List<FilePickerResult>?> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      if (result == null) return null;
      return [result];
    } catch (e) {
      debugPrint('Error picking files: $e');
      return null;
    }
  }

  // Pick images (Works on Web & Android)
  static Future<List<XFile>?> pickImages({bool allowMultiple = true}) async {
    try {
      final ImagePicker picker = ImagePicker();

      if (allowMultiple) {
        return await picker.pickMultiImage(imageQuality: 80, limit: 10);
      } else {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        return image != null ? [image] : null;
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      return null;
    }
  }

  // Take photo with camera (Android only, Web returns null)
  static Future<XFile?> takePhoto() async {
    if (isWeb) {
      debugPrint('Camera not supported on Web');
      return null;
    }

    try {
      final ImagePicker picker = ImagePicker();
      return await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  // Upload files from FilePickerResult (Works on Web & Android)
  static Future<List<Map<String, dynamic>>> uploadFiles({
    required String folderPath,
    required List<FilePickerResult> files,
    Function(int, int)? onProgress,
  }) async {
    List<Map<String, dynamic>> uploadedFiles = [];
    int completed = 0;

    for (var result in files) {
      for (var file in result.files) {
        try {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final ref = _storage.ref().child('$folderPath/$fileName');

          UploadTask uploadTask;

          if (isWeb && file.bytes != null) {
            // Web platform
            uploadTask = ref.putData(file.bytes!);
          } else if (file.path != null) {
            // Mobile platform
            uploadTask = ref.putFile(File(file.path!));
          } else {
            continue;
          }

          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          uploadedFiles.add({
            'name': fileName,
            'originalName': file.name,
            'url': downloadUrl,
            'type': _getFileType(file.name),
            'size': file.size,
          });

          completed++;
          if (onProgress != null) {
            onProgress(completed, files.length);
          }
        } catch (e) {
          debugPrint('Upload error for ${file.name}: $e');
        }
      }
    }

    return uploadedFiles;
  }

  // Upload images from XFile list (Works on Web & Android)
  static Future<List<Map<String, dynamic>>> uploadImages({
    required String folderPath,
    required List<XFile> images,
    Function(int, int)? onProgress,
  }) async {
    List<Map<String, dynamic>> uploadedFiles = [];
    int completed = 0;

    for (var image in images) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final ref = _storage.ref().child('$folderPath/$fileName');

        UploadTask uploadTask;

        if (isWeb) {
          final bytes = await image.readAsBytes();
          uploadTask = ref.putData(bytes);
        } else {
          uploadTask = ref.putFile(File(image.path));
        }

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        uploadedFiles.add({
          'name': fileName,
          'originalName': image.name,
          'url': downloadUrl,
          'type': 'image',
          'size': await image.length(),
        });

        completed++;
        if (onProgress != null) {
          onProgress(completed, images.length);
        }
      } catch (e) {
        debugPrint('Upload error for ${image.name}: $e');
      }
    }

    return uploadedFiles;
  }

  // Upload multiple files (convenience method)
  static Future<List<Map<String, dynamic>>> uploadMultipleFiles({
    required List<dynamic> files,
    required String folder,
  }) async {
    List<Map<String, dynamic>> uploadedFiles = [];

    for (var fileItem in files) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_getFileName(fileItem)}';
        final ref = _storage.ref().child('$folder/$fileName');

        UploadTask uploadTask;

        if (isWeb) {
          // Web platform
          if (fileItem is XFile) {
            final bytes = await fileItem.readAsBytes();
            uploadTask = ref.putData(bytes);
          } else if (fileItem is FilePickerResult) {
            final file = fileItem.files.first;
            if (file.bytes != null) {
              uploadTask = ref.putData(file.bytes!);
            } else {
              continue;
            }
          } else {
            continue;
          }
        } else {
          // Mobile platform
          if (fileItem is XFile) {
            uploadTask = ref.putFile(File(fileItem.path));
          } else if (fileItem is FilePickerResult) {
            final file = fileItem.files.first;
            if (file.path != null) {
              uploadTask = ref.putFile(File(file.path!));
            } else {
              continue;
            }
          } else if (fileItem is File) {
            uploadTask = ref.putFile(fileItem);
          } else {
            continue;
          }
        }

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        uploadedFiles.add({
          'name': fileName,
          'originalName': _getOriginalName(fileItem),
          'url': downloadUrl,
          'type': _getFileType(_getOriginalName(fileItem)),
          'size': await _getFileSize(fileItem),
        });
      } catch (e) {
        debugPrint('Error uploading file: $e');
      }
    }

    return uploadedFiles;
  }

  // Download file (Works on Web & Android)
  static Future<void> downloadFile({
    required String url,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      if (isWeb) {
        // Web download - using universal_html
        html.AnchorElement anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download started...'), backgroundColor: Colors.green),
          );
        }
      } else {
        // Mobile download
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Downloading...'),
                ],
              ),
            ),
          );
        }

        final response = await http.get(Uri.parse(url));

        final Directory directory = await getApplicationDocumentsDirectory();
        final String filePath = '${directory.path}/$fileName';
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded: $fileName'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download error: ${e.toString().substring(0, 100)}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper methods for cross-platform file handling
  static String _getFileName(dynamic fileItem) {
    if (fileItem is FilePickerResult) {
      return fileItem.files.first.name;
    } else if (fileItem is XFile) {
      return fileItem.name;
    } else if (fileItem is File) {
      return fileItem.path.split('/').last;
    }
    return 'file';
  }

  static String _getOriginalName(dynamic fileItem) {
    if (fileItem is FilePickerResult) {
      return fileItem.files.first.name;
    } else if (fileItem is XFile) {
      return fileItem.name;
    } else if (fileItem is File) {
      return fileItem.path.split('/').last;
    }
    return 'file';
  }

  static Future<int> _getFileSize(dynamic fileItem) async {
    if (fileItem is FilePickerResult) {
      return fileItem.files.first.size;
    } else if (fileItem is XFile) {
      return await fileItem.length();
    } else if (fileItem is File) {
      return await fileItem.length();
    }
    return 0;
  }

  static String _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    const images = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    const pdfs = ['pdf'];
    const documents = ['doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'];

    if (images.contains(extension)) return 'image';
    if (pdfs.contains(extension)) return 'pdf';
    if (documents.contains(extension)) return 'document';
    return 'file';
  }
}