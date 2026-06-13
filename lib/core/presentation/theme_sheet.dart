import 'package:conduit/core/platform/platform_support.dart';
import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_theme.dart';
import 'package:conduit/core/theme/app_palette.dart';
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
                min: 10,
                max: 22,
                divisions: 24,
                value: controller.terminalFontSize.clamp(10, 22).toDouble(),
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
            ),
          ),
        ),
        if (shouldShowTerminalKeyboardBar) ...[
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
                  '${controller.terminalKeyboardActions.length}',
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
    builder: (context) {
      var selected = List<TerminalKeyboardAction>.of(
        controller.terminalKeyboardActions,
      );

      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final available = TerminalKeyboardAction.values
              .where((action) => !selected.contains(action))
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
                        Text('Key Row', style: theme.textTheme.titleLarge),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {
                            selected = List.of(defaultTerminalKeyboardActions);
                          }),
                          child: const Text('Reset'),
                        ),
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
                      itemCount: selected.length,
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final elevation = Curves.easeOut.transform(
                              animation.value,
                            );
                            return Transform.scale(
                              scale: 1 + (0.015 * elevation),
                              child: Material(
                                color: Colors.transparent,
                                elevation: 8 * elevation,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.22,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: child,
                              ),
                            );
                          },
                          child: child,
                        );
                      },
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final action = selected.removeAt(oldIndex);
                          selected.insert(newIndex, action);
                        });
                      },
                      itemBuilder: (context, index) {
                        final action = selected[index];
                        return Card(
                          key: ValueKey(action),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(_keyboardActionIcon(action)),
                            title: Text(action.label),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: selected.length == 1
                                      ? null
                                      : () => setState(() {
                                          selected.remove(action);
                                        }),
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
                      },
                    ),
                  ),
                  if (available.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final action in available)
                            ActionChip(
                              avatar: Icon(
                                _keyboardActionIcon(action),
                                size: 16,
                              ),
                              label: Text(action.label),
                              onPressed: () => setState(() {
                                selected.add(action);
                              }),
                            ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                    child: FilledButton.icon(
                      onPressed: () async {
                        await controller.setTerminalKeyboardActions(selected);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save row'),
                    ),
                  ),
                  Container(height: 1, color: colorScheme.outlineVariant),
                ],
              ),
            ),
          );
        },
      );
    },
  );
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
