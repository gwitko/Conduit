import 'package:conduit/core/l10n/l10n.dart';
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
      title: Text(context.l10n.securityKeyChooseTitle),
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
          child: Text(context.l10n.actionCancel),
        ),
      ],
    );
  }
}
