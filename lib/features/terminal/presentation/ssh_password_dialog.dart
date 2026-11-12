import 'package:conduit/features/terminal/domain/ssh_password_interaction.dart';
import 'package:flutter/material.dart';

Future<String?> showSshPasswordDialog(
  BuildContext context,
  SshPasswordPromptRequest request,
) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SshPasswordDialog(request: request),
  );
}

class _SshPasswordDialog extends StatefulWidget {
  const _SshPasswordDialog({required this.request});

  final SshPasswordPromptRequest request;

  @override
  State<_SshPasswordDialog> createState() => _SshPasswordDialogState();
}

class _SshPasswordDialogState extends State<_SshPasswordDialog> {
  final _controller = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final label = request.prompt.trim().replaceFirst(RegExp(r':$'), '');
    final obscure = !request.echo && !_show;
    return AlertDialog(
      title: Text('${request.username}@${request.host}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (request.instruction.trim().isNotEmpty) ...[
            Text(request.instruction.trim()),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: obscure,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              labelText: label.isEmpty ? 'Password' : label,
              helperText: 'The server asks for this after key authentication.',
              helperMaxLines: 2,
              suffixIcon: request.echo
                  ? null
                  : IconButton(
                      tooltip: _show ? 'Hide' : 'Show',
                      icon: Icon(
                        _show
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _show = !_show),
                    ),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
        ],
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
