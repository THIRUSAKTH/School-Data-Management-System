import 'package:flutter/material.dart';

class NoticePostPage extends StatefulWidget {
  const NoticePostPage({super.key});

  @override
  State<NoticePostPage> createState() => _NoticePostPageState();
}

class _NoticePostPageState extends State<NoticePostPage> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  String priority = "Normal";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Post Notice"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("Notice Title"),
            _textField(titleController, "Enter title"),

            const SizedBox(height: 16),

            _label("Notice Message"),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: _inputDecoration("Enter notice details"),
            ),

            const SizedBox(height: 16),

            _label("Priority"),
            DropdownButtonFormField<String>(
              value: priority,
              items: const [
                DropdownMenuItem(value: "Normal", child: Text("Normal")),
                DropdownMenuItem(value: "Important", child: Text("Important")),
                DropdownMenuItem(value: "Urgent", child: Text("Urgent")),
              ],
              onChanged: (value) => setState(() => priority = value!),
              decoration: _inputDecoration("Select priority"),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Publish Notice"),
                onPressed: _publishNotice,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _publishNotice() {
    final noticeData = {
      "title": titleController.text,
      "message": messageController.text,
      "priority": priority,
      "createdAt": DateTime.now(),
    };

    debugPrint(noticeData.toString()); // 🔥 Firebase later

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notice published successfully")),
    );

    titleController.clear();
    messageController.clear();
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}