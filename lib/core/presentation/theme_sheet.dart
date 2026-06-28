import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/app_theme.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showThemeSheet({
  required BuildContext context,
  required ThemeController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle(Theme.of(context).brightness),
      child: _ThemeSheet(controller: controller),
    ),
  );
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.controller});

  final ThemeController controller;

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
                  const SizedBox(height: 22),
                  const ConduitSectionLabel('Home'),
                  const SizedBox(height: 10),
                  _HomeAppearanceControls(controller: controller),
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
                child: Text('Key row', style: theme.textTheme.labelLarge),
              ),
              Text(
                '${controller.terminalKeyboardItems.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    _showKeyboardActionsEditor(context, controller),
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const Text('Edit'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _showKeyboardActionsEditor(
  BuildContext context,
  ThemeController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _KeyboardActionsEditor(controller: controller),
  );
}

class _KeyboardActionsEditor extends StatefulWidget {
  const _KeyboardActionsEditor({required this.controller});

  final ThemeController controller;

  @override
  State<_KeyboardActionsEditor> createState() => _KeyboardActionsEditorState();
}

class _KeyboardActionsEditorState extends State<_KeyboardActionsEditor> {
  late List<TerminalKeyboardItem> _selected;
  final _listController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected = List<TerminalKeyboardItem>.of(
      widget.controller.terminalKeyboardItems,
    );
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
                    'Key Row (${_selected.length})',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
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
                proxyDecorator: _proxyDecorator,
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

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
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

  Future<void> _setSelected(List<TerminalKeyboardItem> next) async {
    setState(() {
      _selected = next;
    });
    await widget.controller.setTerminalKeyboardItems(next);
  }

  Future<void> _reset() {
    return _setSelected(List.of(defaultTerminalKeyboardItems));
  }

  Future<void> _addTmux() {
    final selectedActions = _selected
        .map((item) => item.action)
        .whereType<TerminalKeyboardAction>()
        .toSet();
    return _setSelected([
      ..._selected,
      ...tmuxTerminalKeyboardItems.where(
        (item) => !selectedActions.contains(item.action),
      ),
    ]);
  }

  Future<void> _addBuiltIn(TerminalKeyboardAction action) {
    return _setSelected([..._selected, TerminalKeyboardItem.builtIn(action)]);
  }

  Future<void> _addCustom() async {
    final item = await _showCustomKeyboardItemDialog(context);
    if (item == null || !mounted) {
      return;
    }
    await _setSelected([item, ..._selected]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listController.hasClients) {
        _listController.jumpTo(0);
      }
    });
  }

  Future<void> _remove(int index) {
    return _setSelected([
      ..._selected.take(index),
      ..._selected.skip(index + 1),
    ]);
  }

  Future<void> _reorder(int oldIndex, int newIndex) {
    final next = List<TerminalKeyboardItem>.of(_selected);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    return _setSelected(next);
  }
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
