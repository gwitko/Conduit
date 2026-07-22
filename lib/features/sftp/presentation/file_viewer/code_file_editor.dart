import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/features/sftp/presentation/file_viewer/code_languages.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

/// Code editor with syntax highlighting and line numbers, built on Re-Editor
/// (https://github.com/reqable/re-editor, MIT).
class CodeFileEditor extends StatelessWidget {
  const CodeFileEditor({
    required this.controller,
    required this.fileName,
    required this.palette,
    required this.brightness,
    required this.fontFamily,
    required this.readOnly,
    super.key,
  });

  final CodeLineEditingController controller;
  final String fileName;
  final AppPalette palette;
  final Brightness brightness;
  final String fontFamily;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final language = codeLanguageForFile(fileName);
    final foreground = palette.foregroundFor(brightness);
    return CodeEditor(
      controller: controller,
      readOnly: readOnly,
      wordWrap: false,
      style: CodeEditorStyle(
        fontSize: 13,
        fontFamily: fontFamily,
        textColor: foreground,
        backgroundColor: palette.canvasFor(brightness),
        selectionColor: palette.accent.withValues(alpha: 0.3),
        cursorColor: palette.accent,
        cursorLineColor: palette.accent.withValues(alpha: 0.06),
        chunkIndicatorColor: palette.mutedForegroundFor(brightness),
        codeTheme: CodeHighlightTheme(
          languages: {language.id: CodeHighlightThemeMode(mode: language.mode)},
          theme: brightness == Brightness.dark
              ? atomOneDarkTheme
              : atomOneLightTheme,
        ),
      ),
      indicatorBuilder:
          (context, editingController, chunkController, notifier) {
            return DefaultCodeLineNumber(
              controller: editingController,
              notifier: notifier,
              textStyle: TextStyle(
                fontFamily: fontFamily,
                fontSize: 12,
                color: palette.subtleForegroundFor(brightness),
              ),
              focusedTextStyle: TextStyle(
                fontFamily: fontFamily,
                fontSize: 12,
                color: palette.accent,
              ),
            );
          },
    );
  }
}
