import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/presentation/theme_sheet.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/app_lock/presentation/app_lock_controller.dart';
import 'package:flutter/material.dart';

class LockPage extends StatefulWidget {
  const LockPage({
    required this.controller,
    required this.themeController,
    super.key,
  });

  final AppLockController controller;
  final ThemeController themeController;

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.unlock(context.l10n),
    );
  }

  String? _noticeText(AppLocalizations l10n) =>
      switch (widget.controller.notice) {
        AppLockNotice.deviceNotConfigured => l10n.lockNoticeNotConfigured,
        AppLockNotice.cancelled => l10n.lockNoticeCancelled,
        AppLockNotice.deviceUnavailable => l10n.lockNoticeUnavailable,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.themeController]),
      builder: (context, _) {
        final status = widget.controller.status;
        final checking = status == AppLockStatus.checking;
        final unavailable = status == AppLockStatus.unavailable;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final palette = widget.themeController.palette;

        return Scaffold(
          body: ConduitBackdrop(
            palette: palette,
            child: SafeArea(
              bottom: shouldApplyBottomSafeArea(context),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: IconButton(
                        tooltip: context.l10n.appearanceTitle,
                        icon: const Icon(Icons.palette_outlined),
                        color: colorScheme.onSurfaceVariant,
                        onPressed: () => showThemeSheet(
                          context: context,
                          controller: widget.themeController,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _UnlockHero(
                              palette: palette,
                              checking: checking,
                              unavailable: unavailable,
                            ),
                            const SizedBox(height: 32),
                            const ConduitWordmark(size: 36),
                            const SizedBox(height: 14),
                            Text(
                              _noticeText(context.l10n) ??
                                  context.l10n.lockSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: unavailable
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: checking
                                    ? null
                                    : () => widget.controller.unlock(
                                        context.l10n,
                                      ),
                                icon: checking
                                    ? SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: colorScheme.onPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.lock_open_rounded),
                                label: Text(
                                  unavailable
                                      ? context.l10n.actionRetry
                                      : context.l10n.actionUnlock,
                                ),
                              ),
                            ),
                            if (unavailable) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed:
                                      widget.controller.continueWithoutAuth,
                                  child: Text(
                                    context.l10n.lockContinueWithoutAuth,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        context.l10n.lockFooter,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UnlockHero extends StatelessWidget {
  const _UnlockHero({
    required this.palette,
    required this.checking,
    required this.unavailable,
  });

  final AppPalette palette;
  final bool checking;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final ring = unavailable ? colorScheme.error : palette.accent;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  ring.withValues(alpha: 0.0),
                  ring.withValues(alpha: 0.7),
                  ring.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.panelFor(brightness),
              border: Border.all(color: palette.hairlineFor(brightness)),
            ),
            child: Center(
              child: Icon(
                unavailable
                    ? Icons.gpp_maybe_outlined
                    : (checking ? Icons.hourglass_top : Icons.fingerprint),
                size: 56,
                color: ring,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
