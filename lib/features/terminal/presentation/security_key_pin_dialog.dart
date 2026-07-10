import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:flutter/material.dart';

Future<String?> showSecurityKeyPinDialog(
  BuildContext context,
  SecurityKeyPinRequest request,
) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SecurityKeyPinDialog(request: request),
  );
}

class _SecurityKeyPinDialog extends StatefulWidget {
  const _SecurityKeyPinDialog({required this.request});

  final SecurityKeyPinRequest request;

  @override
  State<_SecurityKeyPinDialog> createState() => _SecurityKeyPinDialogState();
}

class _SecurityKeyPinDialogState extends State<_SecurityKeyPinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final retriesRemaining = widget.request.retriesRemaining;
    return AlertDialog(
      title: const Text('Security key PIN'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          labelText: 'FIDO2 PIN',
          helperText: retriesRemaining == null
              ? 'Enter the PIN for your hardware security key.'
              : '$retriesRemaining attempts remaining.',
          helperMaxLines: 2,
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
