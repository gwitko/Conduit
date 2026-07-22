import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/features/sftp/domain/remote_file_kind.dart';
import 'package:flutter/material.dart';

class FileViewerToolbar extends StatelessWidget {
  const FileViewerToolbar({
    required this.fileName,
    required this.kind,
    required this.dirty,
    required this.palette,
    required this.brightness,
    required this.htmlPreview,
    required this.onToggleHtmlPreview,
    required this.showSave,
    required this.onSave,
    required this.onReload,
    super.key,
  });

  final String fileName;
  final RemoteFileKind kind;
  final bool dirty;
  final AppPalette palette;
  final Brightness brightness;

  final bool htmlPreview;

  /// Null hides the HTML preview/source toggle.
  final VoidCallback? onToggleHtmlPreview;

  final bool showSave;

  /// Null renders the save button disabled (nothing to save right now).
  final VoidCallback? onSave;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    final muted = palette.mutedForegroundFor(brightness);
    return Container(
      height: 44,
      color: palette.canvasFor(brightness),
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Icon(_kindIcon, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dirty ? '$fileName •' : fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.foregroundFor(brightness),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onToggleHtmlPreview != null)
            IconButton(
              tooltip: htmlPreview ? 'Show source' : 'Show preview',
              iconSize: 19,
              color: muted,
              icon: Icon(
                htmlPreview ? Icons.code_rounded : Icons.visibility_rounded,
              ),
              onPressed: onToggleHtmlPreview,
            ),
          if (showSave)
            IconButton(
              tooltip: 'Save to server',
              iconSize: 19,
              color: dirty ? palette.accent : muted,
              icon: const Icon(Icons.save_rounded),
              onPressed: onSave,
            ),
          IconButton(
            tooltip: 'Reload from server',
            iconSize: 19,
            color: muted,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onReload,
          ),
        ],
      ),
    );
  }

  IconData get _kindIcon {
    return switch (kind) {
      RemoteFileKind.image => Icons.image_rounded,
      RemoteFileKind.pdf => Icons.picture_as_pdf_rounded,
      RemoteFileKind.html => Icons.language_rounded,
      RemoteFileKind.text => Icons.description_rounded,
    };
  }
}
