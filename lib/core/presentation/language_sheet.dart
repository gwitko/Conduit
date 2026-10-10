import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/core/l10n/locale_controller.dart';
import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showLanguageSheet({
  required BuildContext context,
  required LocaleController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle(Theme.of(context).brightness),
      child: _LanguageSheet(controller: controller),
    ),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.controller});

  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SafeArea(
      bottom: shouldApplyBottomSafeArea(context),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.languageTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    const ConduitGlyph(size: 24),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.languageSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                _LanguageOption(
                  label: l10n.languageSystem,
                  selected: controller.locale == null,
                  onTap: () => controller.setLocale(null),
                ),
                const SizedBox(height: 8),
                // Language names are always rendered in their own language so
                // the list stays readable no matter which one is active.
                _LanguageOption(
                  label: 'English',
                  selected: controller.locale?.languageCode == 'en',
                  onTap: () => controller.setLocale(const Locale('en')),
                ),
                const SizedBox(height: 8),
                _LanguageOption(
                  label: '简体中文',
                  selected: controller.locale?.languageCode == 'zh',
                  onTap: () => controller.setLocale(const Locale('zh')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    accent.withValues(alpha: 0.12),
                    colorScheme.surface,
                  )
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 20, color: accent)
              else
                const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
