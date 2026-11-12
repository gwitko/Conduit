import 'package:conduit/features/terminal/domain/ssh_password_interaction.dart';
import 'package:flutter/material.dart';

Future<String?> showSshPasswordDialog(
  BuildContext context,
  SshPasswordRequest request,
) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SshPasswordDialog(request: request),
  );
}

class _SshPasswordDialog extends StatefulWidget {
  const _SshPasswordDialog({required this.request});

  final SshPasswordRequest request;

  @override
  State<_SshPasswordDialog> createState() => _SshPasswordDialogState();
}

class _SshPasswordDialogState extends State<_SshPasswordDialog> {
  final _controller = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _controller.clear();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    if (value.isEmpty) {
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('SSH password'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: !_show,
        enableSuggestions: false,
        autocorrect: false,
        enableIMEPersonalizedLearning: false,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          labelText: 'Password for ${widget.request.endpoint}',
          helperText: 'Used for this connection only. Never saved.',
          helperMaxLines: 2,
          suffixIcon: IconButton(
            tooltip: _show ? 'Hide' : 'Show',
            icon: Icon(
              _show
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () => setState(() => _show = !_show),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Connect')),
      ],
    );
  }
}
