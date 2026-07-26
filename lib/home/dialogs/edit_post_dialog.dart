import 'package:flutter/material.dart';

class EditPostDialog extends StatefulWidget {
  final String initialText;
  const EditPostDialog({super.key, required this.initialText});

  @override
  State<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Post'),
      content: TextField(
        controller: _controller,
        maxLength: 500,
        maxLines: 5,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "What's on your mind?",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final trimmed = _controller.text.trim();
            if (trimmed.isNotEmpty) {
              Navigator.of(context).pop(trimmed);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
