import 'package:conduit/features/snippets/domain/terminal_snippet.dart';
import 'package:flutter/material.dart';

class SnippetListEditor extends StatelessWidget {
  const SnippetListEditor({
    required this.snippets,
    required this.onChanged,
    this.connectSnippetId = '',
    this.onConnectSnippetChanged,
    this.title = 'Snippets',
    this.caption,
    super.key,
  });

  final List<TerminalSnippet> snippets;
  final ValueChanged<List<TerminalSnippet>> onChanged;
  final String connectSnippetId;
  final ValueChanged<String>? onConnectSnippetChanged;
  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              TextButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Add'),
              ),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (snippets.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                'No snippets saved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final snippet in snippets)
              _SnippetTile(
                snippet: snippet,
                runOnConnect: snippet.id == connectSnippetId,
                canRunOnConnect: onConnectSnippetChanged != null,
                onToggleRunOnConnect: () => _toggleRunOnConnect(snippet),
                onEdit: () => _edit(context, snippet),
                onRemove: () => _remove(snippet),
              ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final snippet = await showSnippetDialog(context: context);
    if (snippet == null) {
      return;
    }
    onChanged([snippet, ...snippets]);
  }

  Future<void> _edit(BuildContext context, TerminalSnippet snippet) async {
    final next = await showSnippetDialog(context: context, initial: snippet);
    if (next == null) {
      return;
    }
    onChanged([
      for (final existing in snippets)
        existing.id == snippet.id ? next : existing,
    ]);
  }

  void _remove(TerminalSnippet snippet) {
    onChanged(snippets.where((item) => item.id != snippet.id).toList());
    if (connectSnippetId == snippet.id) {
      onConnectSnippetChanged?.call('');
    }
  }

  void _toggleRunOnConnect(TerminalSnippet snippet) {
    final callback = onConnectSnippetChanged;
    if (callback == null) {
      return;
    }
    callback(connectSnippetId == snippet.id ? '' : snippet.id);
  }
}

class _SnippetTile extends StatelessWidget {
  const _SnippetTile({
    required this.snippet,
    required this.runOnConnect,
    required this.canRunOnConnect,
    required this.onToggleRunOnConnect,
    required this.onEdit,
    required this.onRemove,
  });

  final TerminalSnippet snippet;
  final bool runOnConnect;
  final bool canRunOnConnect;
  final VoidCallback onToggleRunOnConnect;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visiblePreview = snippet.hidden
        ? 'Hidden'
        : snippet.submit
        ? '${snippet.text} + Enter'
        : snippet.text;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          snippet.hidden ? Icons.visibility_off_rounded : Icons.code_rounded,
        ),
        title: Text(
          snippet.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          visiblePreview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRunOnConnect)
              IconButton(
                tooltip: runOnConnect
                    ? 'Disable run on connect'
                    : 'Run on connect',
                onPressed: onToggleRunOnConnect,
                icon: Icon(
                  runOnConnect
                      ? Icons.play_circle_rounded
                      : Icons.play_circle_outline_rounded,
                ),
              ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

Future<TerminalSnippet?> showSnippetDialog({
  required BuildContext context,
  TerminalSnippet? initial,
}) {
  return showDialog<TerminalSnippet>(
    context: context,
    builder: (context) => _SnippetDialog(initial: initial),
  );
}

class _SnippetDialog extends StatefulWidget {
  const _SnippetDialog({this.initial});

  final TerminalSnippet? initial;

  @override
  State<_SnippetDialog> createState() => _SnippetDialogState();
}

class _SnippetDialogState extends State<_SnippetDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _textController;
  late bool _hidden;
  late bool _submit;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _textController = TextEditingController(text: initial?.text ?? '');
    _hidden = initial?.hidden ?? false;
    _submit = initial?.submit ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.initial == null ? 'Add snippet' : 'Edit snippet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            autofocus: true,
            scrollPadding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            scrollPadding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const InputDecoration(
              labelText: 'Command or text',
              border: OutlineInputBorder(),
            ),
            obscureText: _hidden,
            minLines: _hidden ? 1 : 3,
            maxLines: _hidden ? 1 : 6,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _submit,
            onChanged: (value) => setState(() => _submit = value ?? true),
            title: const Text('Send Enter after snippet'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _hidden,
            onChanged: (value) => setState(() => _hidden = value),
            title: const Text('Hidden snippet'),
            subtitle: const Text('Use for passwords or other secrets.'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitSnippet,
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _submitSnippet() {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      TerminalSnippet(
        id: widget.initial?.id ?? _newSnippetId(),
        label: label,
        text: _textController.text,
        hidden: _hidden,
        submit: _submit,
      ),
    );
  }
}

String _newSnippetId() {
  return 'snippet:${DateTime.now().microsecondsSinceEpoch}';
}
