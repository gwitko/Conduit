import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:flutter/material.dart';

Future<int?> showSecurityKeyPickerDialog(
  BuildContext context,
  SecurityKeySelectionRequest request,
) {
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SecurityKeyPickerDialog(request: request),
  );
}

class _SecurityKeyPickerDialog extends StatelessWidget {
  const _SecurityKeyPickerDialog({required this.request});

  final SecurityKeySelectionRequest request;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose security key'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: SizedBox(
        width: double.minPositive,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: request.labels.length,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.key),
            title: Text(request.labels[index]),
            onTap: () => Navigator.of(context).pop(index),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
