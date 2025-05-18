import 'package:flutter/material.dart';

Future<void> showCustomDialog(BuildContext context, String message) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Notification'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<String?> showRenameDialog(
  BuildContext context,
  String originalName, {
  required List<String> existingNames,
  required String originalExtension,
}) async {
  final dotIdx = originalName.lastIndexOf('.');
  final baseName =
      dotIdx > 0 ? originalName.substring(0, dotIdx) : originalName;
  final ext = dotIdx > 0 ? originalName.substring(dotIdx) : '';
  final controller = TextEditingController(text: baseName);
  String? errorText;
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Duplicate File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'A file with this name already exists. Please enter a new name:'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'File name',
                          errorText: errorText,
                        ),
                        autofocus: true,
                      ),
                    ),
                    Text(ext, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(null),
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    setState(() => errorText = 'File name cannot be empty');
                    return;
                  }
                  final newFullName = value + ext;
                  // Check for duplicate (case-insensitive, ignore extension)
                  final lowerName = value.toLowerCase();
                  final lowerExisting = existingNames.map((n) {
                    final idx = n.lastIndexOf('.');
                    return (idx > 0 ? n.substring(0, idx) : n).toLowerCase();
                  }).toList();
                  if (lowerExisting.contains(lowerName)) {
                    setState(() =>
                        errorText = 'A file with this name already exists');
                    return;
                  }
                  // Check extension (should always match, but just in case)
                  if (ext.toLowerCase() != originalExtension.toLowerCase()) {
                    setState(() =>
                        errorText = 'You cannot change the file extension');
                    return;
                  }
                  Navigator.of(context).pop(newFullName);
                },
              ),
            ],
          );
        },
      );
    },
  );
}
