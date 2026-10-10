import 'package:conduit/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

class TagEditor extends StatelessWidget {
  const TagEditor({
    required this.tags,
    required this.controller,
    required this.focusNode,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<String> tags;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.l10n.labelTags,
            hintText: context.l10n.hostFormTagsHint,
            prefixIcon: const Icon(Icons.tag_rounded),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.trim().isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: context.l10n.hostFormAddTag,
                  icon: Icon(
                    Icons.add_circle_rounded,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => onAdd(value.text),
                );
              },
            ),
          ),
          onSubmitted: (value) {
            onAdd(value);
            focusNode.requestFocus();
          },
          onChanged: (value) {
            if (value.contains(',')) {
              final parts = value.split(',');
              for (final part in parts.take(parts.length - 1)) {
                onAdd(part);
              }
              controller.text = parts.last.trimLeft();
              controller.selection = TextSelection.collapsed(
                offset: controller.text.length,
              );
            }
          },
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                _EditableTagChip(label: tag, onRemove: () => onRemove(tag)),
            ],
          ),
        ],
      ],
    );
  }
}

class _EditableTagChip extends StatelessWidget {
  const _EditableTagChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.14),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag_rounded, size: 13, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
