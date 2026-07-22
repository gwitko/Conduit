import 'dart:convert';
import 'dart:typed_data';

import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/features/sftp/domain/remote_file_kind.dart';
import 'package:conduit/features/sftp/presentation/file_viewer/code_file_editor.dart';
import 'package:conduit/features/sftp/presentation/file_viewer/file_viewer_toolbar.dart';
import 'package:conduit/features/sftp/presentation/file_viewer/media_file_views.dart';
import 'package:conduit/features/sftp/presentation/widgets/center_message.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

typedef SftpFileRead =
    Future<Uint8List> Function(void Function(int read, int? total)? onProgress);
typedef SftpFileWrite = Future<void> Function(Uint8List bytes);

enum _ViewerStatus { loading, failed, ready }

/// Remote file preview and editor: images, PDFs, rendered HTML, and code with
/// syntax highlighting. Embeddable — used by the SFTP browser and by terminal
/// file tabs.
class SftpFileViewer extends StatefulWidget {
  const SftpFileViewer({
    required this.path,
    required this.palette,
    required this.brightness,
    required this.fontFamily,
    required this.read,
    required this.write,
    super.key,
  });

  final String path;
  final AppPalette palette;
  final Brightness brightness;
  final String fontFamily;
  final SftpFileRead read;

  /// Null makes the viewer read-only (no way to write back).
  final SftpFileWrite? write;

  @override
  State<SftpFileViewer> createState() => SftpFileViewerState();
}

class SftpFileViewerState extends State<SftpFileViewer> {
  _ViewerStatus _status = _ViewerStatus.loading;
  Uint8List _bytes = Uint8List(0);
  String? _error;
  double? _progress;
  bool _binary = false;
  bool _htmlPreview = true;
  bool _saving = false;
  bool _dirty = false;
  String _loadedText = '';
  CodeLineEditingController? _editor;

  RemoteFileKind get _kind => remoteFileKindForPath(widget.path);
  String get _fileName => remoteFileName(widget.path);

  bool get isDirty => _dirty;

  bool get _editable =>
      widget.write != null && _bytes.length <= remoteFileEditorMaxBytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposeEditor();
    super.dispose();
  }

  void _disposeEditor() {
    _editor?.removeListener(_handleEdited);
    _editor?.dispose();
    _editor = null;
  }

  Future<void> _load() async {
    _disposeEditor();
    setState(() {
      _status = _ViewerStatus.loading;
      _error = null;
      _progress = null;
      _dirty = false;
    });
    try {
      final bytes = await widget.read((read, total) {
        if (!mounted || total == null || total <= 0) return;
        setState(() => _progress = (read / total).clamp(0.0, 1.0));
      });
      if (!mounted) return;
      if (bytes.length > remoteFileViewerMaxBytes) {
        setState(() {
          _status = _ViewerStatus.failed;
          _error =
              'This file is too large to preview. Download it from the file '
              'browser instead.';
        });
        return;
      }
      _bytes = bytes;
      _binary = _kind == RemoteFileKind.text && !remoteFileLooksTextual(bytes);
      if ((_kind == RemoteFileKind.text || _kind == RemoteFileKind.html) &&
          !_binary) {
        _loadedText = utf8.decode(bytes, allowMalformed: true);
        final editor = CodeLineEditingController.fromText(_loadedText);
        editor.addListener(_handleEdited);
        _editor = editor;
      }
      setState(() => _status = _ViewerStatus.ready);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _ViewerStatus.failed;
        _error = '$error';
      });
    }
  }

  void _handleEdited() {
    final dirty = _editor?.text != _loadedText;
    if (dirty != _dirty) {
      setState(() => _dirty = dirty);
    }
  }

  Future<void> _save() async {
    final editor = _editor;
    final write = widget.write;
    if (editor == null || write == null || _saving) return;
    final text = editor.text;
    setState(() => _saving = true);
    try {
      await write(Uint8List.fromList(utf8.encode(text)));
      if (!mounted) return;
      _loadedText = text;
      setState(() {
        _dirty = false;
        _saving = false;
      });
      _showSnack('Saved $_fileName');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('$error');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        if (_saving)
          const LinearProgressIndicator(minHeight: 2)
        else
          Divider(
            height: 1,
            thickness: 1,
            color: widget.palette.hairlineFor(widget.brightness),
          ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildToolbar() {
    return FileViewerToolbar(
      fileName: _fileName,
      kind: _kind,
      dirty: _dirty,
      palette: widget.palette,
      brightness: widget.brightness,
      htmlPreview: _htmlPreview,
      onToggleHtmlPreview:
          _kind == RemoteFileKind.html &&
              _status == _ViewerStatus.ready &&
              !_binary
          ? () => setState(() => _htmlPreview = !_htmlPreview)
          : null,
      showSave:
          _editor != null && (!_htmlPreview || _kind != RemoteFileKind.html),
      onSave: _dirty && _editable && !_saving ? _save : null,
      onReload: _status == _ViewerStatus.loading ? null : _load,
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ViewerStatus.loading:
        return Center(
          child: SizedBox(
            width: 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 12),
                Text(
                  'Opening $_fileName…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: widget.palette.mutedForegroundFor(widget.brightness),
                  ),
                ),
              ],
            ),
          ),
        );
      case _ViewerStatus.failed:
        return CenterMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not open file',
          message: _error,
          actionLabel: 'Retry',
          onAction: _load,
        );
      case _ViewerStatus.ready:
        return _buildReadyBody();
    }
  }

  Widget _buildReadyBody() {
    if (_binary) {
      return const CenterMessage(
        icon: Icons.raw_on_rounded,
        title: 'Binary file',
        message:
            'This file does not look like text. Download it from the file '
            'browser to open it in another app.',
      );
    }
    switch (_kind) {
      case RemoteFileKind.image:
        return ImageFileView(
          bytes: _bytes,
          palette: widget.palette,
          brightness: widget.brightness,
        );
      case RemoteFileKind.pdf:
        return PdfFileView(bytes: _bytes, path: widget.path);
      case RemoteFileKind.html:
        if (_htmlPreview) {
          return HtmlFileView(html: _editor?.text ?? _loadedText);
        }
        return _buildEditor();
      case RemoteFileKind.text:
        return _buildEditor();
    }
  }

  Widget _buildEditor() {
    final editor = _editor;
    if (editor == null) {
      return const SizedBox.shrink();
    }
    return CodeFileEditor(
      controller: editor,
      fileName: _fileName,
      palette: widget.palette,
      brightness: widget.brightness,
      fontFamily: widget.fontFamily,
      readOnly: !_editable,
    );
  }
}
