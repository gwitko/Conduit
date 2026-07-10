import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/app_theme.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/backup/data/app_backup_service.dart';
import 'package:conduit/features/backup/presentation/backup_sheet.dart';
import 'package:conduit/features/snippets/presentation/snippet_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showThemeSheet({
  required BuildContext context,
  required ThemeController controller,
  AppBackupService? backupService,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle(Theme.of(context).brightness),
      child: _ThemeSheet(controller: controller, backupService: backupService),
    ),
  );
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.controller, required this.backupService});

  final ThemeController controller;
  final AppBackupService? backupService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return SafeArea(
              bottom: shouldApplyBottomSafeArea(context),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                children: [
                  Row(
                    children: [
                      Text('Appearance', style: theme.textTheme.headlineSmall),
                      const Spacer(),
                      const ConduitGlyph(size: 24),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick a developer palette. The home screen, editor, and dialogs share the same look.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const ConduitSectionLabel('Mode'),
                  const SizedBox(height: 10),
                  _ModeSelector(controller: controller),
                  const SizedBox(height: 22),
                  const ConduitSectionLabel('Terminal'),
                  const SizedBox(height: 10),
                  _TerminalAppearanceControls(controller: controller),
                  if (defaultTargetPlatform == TargetPlatform.android) ...[
                    const SizedBox(height: 22),
                    const ConduitSectionLabel('Home'),
                    const SizedBox(height: 10),
                    _HomeAppearanceControls(controller: controller),
                  ],
                  if (backupService != null) ...[
                    const SizedBox(height: 22),
                    const ConduitSectionLabel('Backup'),
                    const SizedBox(height: 10),
                    _BackupControls(backupService: backupService!),
                  ],
                  const SizedBox(height: 22),
                  const ConduitSectionLabel('Palette'),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.25,
                        ),
                    itemCount: AppPalette.values.length,
                    itemBuilder: (context, index) {
                      final palette = AppPalette.values[index];
                      return _PaletteCard(
                        palette: palette,
                        selected: controller.palette == palette,
                        onTap: () => controller.setPalette(palette),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeAppearanceControls extends StatelessWidget {
  const _HomeAppearanceControls({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        secondary: const Icon(Icons.terminal_rounded),
        title: const Text('Show local shell'),
        subtitle: Text(
          'Show the local terminal shortcut on the home screen.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        value: controller.showLocalShell,
        onChanged: controller.setShowLocalShell,
      ),
    );
  }
}

class _BackupControls extends StatelessWidget {
  const _BackupControls({required this.backupService});

  final AppBackupService backupService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.backup_rounded),
        title: const Text('Backup and restore'),
        subtitle: Text(
          'Export settings and machines or import a saved backup.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () =>
            showBackupSheet(context: context, backupService: backupService),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto),
          label: Text('System'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode),
          label: Text('Dark'),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode),
          label: Text('Light'),
        ),
      ],
      selected: {controller.themeMode},
      onSelectionChanged: (selection) =>
          controller.setThemeMode(selection.single),
    );
  }
}

class _TerminalAppearanceControls extends StatelessWidget {
  const _TerminalAppearanceControls({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<TerminalFontOption>(
          segments: [
            for (final font in TerminalFontOption.values)
              ButtonSegment(
                value: font,
                icon: Icon(
                  font == TerminalFontOption.atkynsonNerdFont
                      ? Icons.extension_rounded
                      : Icons.terminal_rounded,
                ),
                label: Text(font.label),
              ),
          ],
          selected: {controller.terminalFont},
          onSelectionChanged: (selection) =>
              controller.setTerminalFont(selection.single),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_size_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Font size', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  Text(
                    controller.terminalFontSize.toStringAsFixed(1),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Slider(
                min: terminalFontSizeMin,
                max: terminalFontSizeMax,
                divisions: terminalFontSizeDivisions,
                value: clampTerminalFontSize(controller.terminalFontSize),
                label: controller.terminalFontSize.toStringAsFixed(1),
                onChanged: controller.setTerminalFontSize,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 72,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Text(
            r'  ~/conduit  ❯ git status',
            style: TextStyle(
              fontFamily: controller.terminalFont.fontFamily,
              fontSize: controller.terminalFontSize,
              color: colorScheme.onSurface,
              letterSpacing: 0,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              const Icon(Icons.keyboard_command_key_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Key rows', style: theme.textTheme.labelLarge),
              ),
              Text(
                '${controller.terminalKeyboardRows.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => _showKeyboardRowsEditor(context, controller),
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const Text('Edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: SnippetListEditor(
            title: 'Global snippets',
            caption: 'Shown from the Snip key-row menu on every machine.',
            snippets: controller.terminalSnippets,
            onChanged: controller.setTerminalSnippets,
          ),
        ),
      ],
    );
  }
}

Future<void> _showKeyboardRowsEditor(
  BuildContext context,
  ThemeController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _KeyboardRowsEditor(controller: controller),
  );
}

class _KeyboardRowsEditor extends StatefulWidget {
  const _KeyboardRowsEditor({required this.controller});

  final ThemeController controller;

  @override
  State<_KeyboardRowsEditor> createState() => _KeyboardRowsEditorState();
}

class _KeyboardRowsEditorState extends State<_KeyboardRowsEditor> {
  late List<TerminalKeyboardRow> _rows;
  final List<int> _rowIds = [];
  var _nextRowId = 0;

  @override
  void initState() {
    super.initState();
    _rows = List.of(widget.controller.terminalKeyboardRows);
    for (var index = 0; index < _rows.length; index += 1) {
      _rowIds.add(_nextRowId++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      bottom: shouldApplyBottomSafeArea(context),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
              child: Row(
                children: [
                  Text(
                    'Key Rows (${_rows.length})',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                itemCount: _rows.length,
                proxyDecorator: _reorderProxyDecorator,
                onReorderItem: _reorder,
                itemBuilder: _buildRow,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('Add row'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final row = _rows[index];
    return Card(
      key: ValueKey(_rowIds[index]),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Row ${index + 1}',
                        style: theme.textTheme.labelLarge,
                      ),
                      Text(
                        row.items.length == 1
                            ? '1 key'
                            : '${row.items.length} keys',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit keys',
                  onPressed: () => _editRowKeys(index),
                  icon: const Icon(Icons.tune_rounded),
                ),
                IconButton(
                  tooltip: 'Remove row',
                  onPressed: _rows.length == 1 ? null : () => _removeRow(index),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle_rounded),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.height_rounded,
                  size: 17,
                  color: colorScheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Slider(
                    value: row.height,
                    min: terminalKeyboardRowHeightMin,
                    max: terminalKeyboardRowHeightMax,
                    divisions: 8,
                    label: '${row.height.round()}',
                    onChanged: (value) => setState(
                      () => _rows[index] = row.copyWith(height: value),
                    ),
                    onChangeEnd: (_) => _persist(),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${row.height.round()}',
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRowKeys(int index) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _KeyboardActionsEditor(
        title: 'Row ${index + 1} Keys',
        initialItems: _rows[index].items,
        onChanged: (items) {
          setState(() => _rows[index] = _rows[index].copyWith(items: items));
          _persist();
        },
      ),
    );
    if (!mounted) {
      return;
    }
    if (_rows.length > 1 && _rows[index].items.isEmpty) {
      setState(() {
        _rows.removeAt(index);
        _rowIds.removeAt(index);
      });
      _persist();
    }
  }

  Future<void> _addRow() {
    setState(() {
      _rows.add(const TerminalKeyboardRow(items: []));
      _rowIds.add(_nextRowId++);
    });
    return _editRowKeys(_rows.length - 1);
  }

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index);
      _rowIds.removeAt(index);
    });
    _persist();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      _rows.insert(newIndex, _rows.removeAt(oldIndex));
      _rowIds.insert(newIndex, _rowIds.removeAt(oldIndex));
    });
    _persist();
  }

  void _reset() {
    setState(() {
      _rows = List.of(defaultTerminalKeyboardRows);
      _rowIds
        ..clear()
        ..addAll([for (final _ in _rows) _nextRowId++]);
    });
    _persist();
  }

  void _persist() {
    widget.controller.setTerminalKeyboardRows(List.of(_rows));
  }
}

class _KeyboardActionsEditor extends StatefulWidget {
  const _KeyboardActionsEditor({
    required this.title,
    required this.initialItems,
    required this.onChanged,
  });

  final String title;
  final List<TerminalKeyboardItem> initialItems;
  final ValueChanged<List<TerminalKeyboardItem>> onChanged;

  @override
  State<_KeyboardActionsEditor> createState() => _KeyboardActionsEditorState();
}

class _KeyboardActionsEditorState extends State<_KeyboardActionsEditor> {
  late List<TerminalKeyboardItem> _selected;
  final _listController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected = List<TerminalKeyboardItem>.of(widget.initialItems);
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedActions = _selected
        .map((item) => item.action)
        .whereType<TerminalKeyboardAction>()
        .toSet();
    final available = TerminalKeyboardAction.values
        .where((action) => !selectedActions.contains(action))
        .toList(growable: false);

    return SafeArea(
      bottom: shouldApplyBottomSafeArea(context),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
              child: Row(
                children: [
                  Text(
                    '${widget.title} (${_selected.length})',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(onPressed: _addTmux, child: const Text('Tmux')),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: _listController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                itemCount: _selected.length,
                proxyDecorator: _reorderProxyDecorator,
                onReorderItem: _reorder,
                itemBuilder: _buildItem,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final action in available)
                    ActionChip(
                      avatar: Icon(_keyboardActionIcon(action), size: 16),
                      label: Text(action.label),
                      onPressed: () => _addBuiltIn(action),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Custom'),
                    onPressed: _addCustom,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Done'),
              ),
            ),
            Container(height: 1, color: colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _selected[index];
    return Card(
      key: ValueKey(item.stableId),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(_keyboardItemIcon(item)),
        title: Text(item.displayLabel),
        subtitle: _keyboardItemSubtitle(item),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Remove',
              onPressed: _selected.length == 1 ? null : () => _remove(index),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setSelected(List<TerminalKeyboardItem> next) {
    setState(() {
      _selected = next;
    });
    widget.onChanged(next);
  }

  void _addTmux() {
    final selectedActions = _selected
        .map((item) => item.action)
        .whereType<TerminalKeyboardAction>()
        .toSet();
    _setSelected([
      ..._selected,
      ...tmuxTerminalKeyboardItems.where(
        (item) => !selectedActions.contains(item.action),
      ),
    ]);
  }

  void _addBuiltIn(TerminalKeyboardAction action) {
    _setSelected([..._selected, TerminalKeyboardItem.builtIn(action)]);
  }

  Future<void> _addCustom() async {
    final item = await _showCustomKeyboardItemDialog(context);
    if (item == null || !mounted) {
      return;
    }
    _setSelected([item, ..._selected]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listController.hasClients) {
        _listController.jumpTo(0);
      }
    });
  }

  void _remove(int index) {
    _setSelected([..._selected.take(index), ..._selected.skip(index + 1)]);
  }

  void _reorder(int oldIndex, int newIndex) {
    final next = List<TerminalKeyboardItem>.of(_selected);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    _setSelected(next);
  }
}

Widget _reorderProxyDecorator(
  Widget child,
  int index,
  Animation<double> animation,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final elevation = Curves.easeOut.transform(animation.value);
      return Transform.scale(
        scale: 1 + (0.015 * elevation),
        child: Material(
          color: Colors.transparent,
          elevation: 8 * elevation,
          shadowColor: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      );
    },
    child: child,
  );
}

Future<TerminalKeyboardItem?> _showCustomKeyboardItemDialog(
  BuildContext context,
) {
  return showDialog<TerminalKeyboardItem>(
    context: context,
    builder: (context) => const _CustomKeyboardItemDialog(),
  );
}

class _CustomKeyboardItemDialog extends StatefulWidget {
  const _CustomKeyboardItemDialog();

  @override
  State<_CustomKeyboardItemDialog> createState() =>
      _CustomKeyboardItemDialogState();
}

class _CustomKeyboardItemDialogState extends State<_CustomKeyboardItemDialog> {
  final _labelController = TextEditingController();
  final _textController = TextEditingController();
  var _kind = TerminalKeyboardItemKind.customText;
  var _controlKey = terminalKeyboardControlKeys.first;
  var _submit = false;

  @override
  void dispose() {
    _labelController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textMode = _kind == TerminalKeyboardItemKind.customText;
    final controlMode = _kind == TerminalKeyboardItemKind.customControl;
    return AlertDialog(
      title: const Text('Custom key'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TerminalKeyboardItemKind>(
              segments: const [
                ButtonSegment(
                  value: TerminalKeyboardItemKind.customText,
                  label: Text('Text'),
                ),
                ButtonSegment(
                  value: TerminalKeyboardItemKind.customControl,
                  label: Text('Ctrl'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) {
                setState(() => _kind = value.single);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            if (textMode) ...[
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _submit,
                onChanged: (value) {
                  setState(() => _submit = value ?? false);
                },
                title: const Text('Send Enter after text'),
              ),
            ] else if (controlMode)
              DropdownButtonFormField<String>(
                initialValue: _controlKey,
                decoration: const InputDecoration(
                  labelText: 'Control key',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final key in terminalKeyboardControlKeys)
                    DropdownMenuItem(value: key, child: Text('Ctrl+$key')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _controlKey = value);
                  }
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submitItem, child: const Text('Add')),
      ],
    );
  }

  void _submitItem() {
    final label = _labelController.text.trim();
    final text = _textController.text;
    final textMode = _kind == TerminalKeyboardItemKind.customText;
    final controlMode = _kind == TerminalKeyboardItemKind.customControl;
    if (label.isEmpty || (textMode && text.isEmpty)) {
      return;
    }
    Navigator.of(context).pop(
      TerminalKeyboardItem(
        id: _newCustomKeyboardItemId(),
        kind: _kind,
        label: label,
        text: textMode ? text : null,
        controlKey: controlMode ? _controlKey : null,
        submit: textMode && _submit,
      ),
    );
  }
}

String _newCustomKeyboardItemId() {
  return 'custom:${DateTime.now().microsecondsSinceEpoch}';
}

Widget? _keyboardItemSubtitle(TerminalKeyboardItem item) {
  final text = switch (item.kind) {
    TerminalKeyboardItemKind.builtIn => null,
    TerminalKeyboardItemKind.customText =>
      item.submit ? '${item.text ?? ''} + Enter' : item.text,
    TerminalKeyboardItemKind.customControl => 'Ctrl+${item.controlKey}',
  };
  return text == null ? null : Text(text, maxLines: 1);
}

IconData _keyboardItemIcon(TerminalKeyboardItem item) {
  return switch (item.kind) {
    TerminalKeyboardItemKind.builtIn => _keyboardActionIcon(item.action!),
    TerminalKeyboardItemKind.customText => Icons.text_fields_rounded,
    TerminalKeyboardItemKind.customControl =>
      Icons.keyboard_command_key_rounded,
  };
}

IconData _keyboardActionIcon(TerminalKeyboardAction action) {
  return switch (action) {
    TerminalKeyboardAction.escape => Icons.keyboard_rounded,
    TerminalKeyboardAction.control => Icons.keyboard_control_key_rounded,
    TerminalKeyboardAction.alt => Icons.keyboard_option_key_rounded,
    TerminalKeyboardAction.tab => Icons.keyboard_tab_rounded,
    TerminalKeyboardAction.fullscreen => Icons.fullscreen_rounded,
    TerminalKeyboardAction.arrowUp => Icons.keyboard_arrow_up_rounded,
    TerminalKeyboardAction.arrowDown => Icons.keyboard_arrow_down_rounded,
    TerminalKeyboardAction.arrowLeft => Icons.keyboard_arrow_left_rounded,
    TerminalKeyboardAction.arrowRight => Icons.keyboard_arrow_right_rounded,
    TerminalKeyboardAction.home => Icons.first_page_rounded,
    TerminalKeyboardAction.end => Icons.last_page_rounded,
    TerminalKeyboardAction.pageUp => Icons.vertical_align_top_rounded,
    TerminalKeyboardAction.pageDown => Icons.vertical_align_bottom_rounded,
    TerminalKeyboardAction.controlC ||
    TerminalKeyboardAction.controlD ||
    TerminalKeyboardAction.controlZ ||
    TerminalKeyboardAction.controlL => Icons.keyboard_command_key_rounded,
    TerminalKeyboardAction.colon ||
    TerminalKeyboardAction.slash ||
    TerminalKeyboardAction.pipe ||
    TerminalKeyboardAction.dash => Icons.text_fields_rounded,
    TerminalKeyboardAction.paste => Icons.content_paste_rounded,
    TerminalKeyboardAction.functionKeys => Icons.keyboard_rounded,
    TerminalKeyboardAction.tmuxPrefix => Icons.keyboard_command_key_rounded,
    TerminalKeyboardAction.tmuxScrollback => Icons.swap_vert_rounded,
    TerminalKeyboardAction.tmuxMenu => Icons.view_quilt_rounded,
    TerminalKeyboardAction.snippets => Icons.snippet_folder_rounded,
    TerminalKeyboardAction.compose => Icons.edit_note_rounded,
  };
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: palette.panelFor(brightness),
              borderRadius: BorderRadius.circular(14),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? palette.accent
                    : palette.hairlineFor(brightness),
                width: selected ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [palette.canvas, palette.panelElevated],
                          ),
                        ),
                      ),
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                palette.accent.withValues(alpha: 0.55),
                                palette.accent.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConduitGlyph(size: 22, color: palette.accent),
                            const Spacer(),
                            Row(
                              children: [
                                _Swatch(color: palette.accent),
                                const SizedBox(width: 4),
                                _Swatch(color: palette.accentSecondary),
                                const SizedBox(width: 4),
                                _Swatch(color: palette.success),
                                const SizedBox(width: 4),
                                _Swatch(color: palette.warning),
                                const SizedBox(width: 4),
                                _Swatch(color: palette.danger),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: palette.panelElevated,
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              palette.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.foreground,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              palette.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.mutedForeground,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
