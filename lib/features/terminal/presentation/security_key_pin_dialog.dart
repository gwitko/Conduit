import 'package:conduit/core/l10n/l10n.dart';
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
      title: Text(context.l10n.securityKeyPinTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          labelText: context.l10n.securityKeyPinLabel,
          helperText: retriesRemaining == null
              ? context.l10n.securityKeyPinBody
              : context.l10n.securityKeyPinAttemptsRemaining(retriesRemaining),
          helperMaxLines: 2,
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(context.l10n.actionContinue),
        ),
      ],
    );
  }
}
