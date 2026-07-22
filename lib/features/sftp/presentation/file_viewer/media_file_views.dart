import 'dart:typed_data';

import 'package:conduit/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ImageFileView extends StatelessWidget {
  const ImageFileView({
    required this.bytes,
    required this.palette,
    required this.brightness,
    super.key,
  });

  final Uint8List bytes;
  final AppPalette palette;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 12,
      child: Center(
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not decode this image.',
              style: TextStyle(color: palette.mutedForegroundFor(brightness)),
            ),
          ),
        ),
      ),
    );
  }
}

/// PDF rendering via pdfrx (https://github.com/espresso3389/pdfrx, MIT).
class PdfFileView extends StatelessWidget {
  const PdfFileView({required this.bytes, required this.path, super.key});

  final Uint8List bytes;
  final String path;

  @override
  Widget build(BuildContext context) {
    return PdfViewer.data(bytes, sourceName: path);
  }
}

/// Rendered HTML via the official webview_flutter plugin.
class HtmlFileView extends StatefulWidget {
  const HtmlFileView({required this.html, super.key});

  final String html;

  @override
  State<HtmlFileView> createState() => _HtmlFileViewState();
}

class _HtmlFileViewState extends State<HtmlFileView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(widget.html);
  }

  @override
  void didUpdateWidget(covariant HtmlFileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _controller.loadHtmlString(widget.html);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
