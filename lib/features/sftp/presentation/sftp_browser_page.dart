import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/sftp/domain/file_export.dart';
import 'package:conduit/features/sftp/domain/sftp_entry.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/sftp/presentation/sftp_browser_controller.dart';
import 'package:conduit/features/sftp/presentation/widgets/actions_fab.dart';
import 'package:conduit/features/sftp/presentation/widgets/center_message.dart';
import 'package:conduit/features/sftp/presentation/widgets/entry_tile.dart';
import 'package:conduit/features/sftp/presentation/widgets/sftp_header.dart';
import 'package:conduit/features/sftp/presentation/widgets/transfer_bar.dart';
import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:conduit/features/terminal/presentation/security_key_picker_dialog.dart';
import 'package:conduit/features/terminal/presentation/security_key_pin_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SftpBrowserPage extends StatefulWidget {
  const SftpBrowserPage({
    required this.host,
    required this.repository,
    required this.fileExport,
    required this.themeController,
    super.key,
  });

  final SavedHost host;
  final SftpRepository repository;
  final FileExport fileExport;
  final ThemeController themeController;

  @override
  State<SftpBrowserPage> createState() => _SftpBrowserPageState();
}

class _SftpBrowserPageState extends State<SftpBrowserPage> {
  late final SftpBrowserController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SecurityKeyInteraction.instance.registerPinPrompt(_promptSecurityKeyPin);
    SecurityKeyInteraction.instance.registerSelectionPrompt(
      _promptSecurityKeySelection,
    );
    _controller = SftpBrowserController(
      host: widget.host,
      repository: widget.repository,
      fileExport: widget.fileExport,
    );
    _controller.connect();
  }

  @override
  void dispose() {
    SecurityKeyInteraction.instance.unregisterPinPrompt(_promptSecurityKeyPin);
    SecurityKeyInteraction.instance.unregisterSelectionPrompt(
      _promptSecurityKeySelection,
    );
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _promptSecurityKeyPin(SecurityKeyPinRequest request) {
    if (!mounted) {
      return Future<String?>.value();
    }
    return showSecurityKeyPinDialog(context, request);
  }

  Future<int?> _promptSecurityKeySelection(
    SecurityKeySelectionRequest request,
  ) {
    if (!mounted) {
      return Future<int?>.value();
    }
    return showSecurityKeyPickerDialog(context, request);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.themeController.palette;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          body: ConduitBackdrop(
            palette: palette,
            child: SafeArea(
              bottom: shouldApplyBottomSafeArea(context),
              child: Column(
                children: [
                  SftpHeader(
                    hostName: widget.host.name,
                    path: _controller.path,
                    busy: _controller.busy,
                    searchController: _searchController,
                    searchQuery: _controller.searchQuery,
                    sortMode: _controller.sortMode,
                    totalCount: _controller.entries.length,
                    visibleCount: _controller.visibleEntries.length,
                    directoryCount: _controller.visibleDirectoryCount,
                    fileCount: _controller.visibleFileCount,
                    onBack: () => Navigator.of(context).pop(),
                    onSegmentTap: _navigateToPath,
                    onSearchChanged: _controller.setSearchQuery,
                    onClearSearch: _clearSearch,
                    onSortChanged: _controller.setSortMode,
                    onRefresh: _controller.status == SftpBrowserStatus.ready
                        ? _controller.refresh
                        : null,
                  ),
                  Expanded(child: _buildBody(context)),
                  if (_controller.transfer != null)
                    TransferBar(transfer: _controller.transfer!),
                ],
              ),
            ),
          ),
          floatingActionButton:
              _controller.status == SftpBrowserStatus.ready &&
                  !_controller.busy &&
                  _controller.transfer == null
              ? ActionsFab(
                  onNewFolder: _promptNewFolder,
                  onUpload: _pickAndUpload,
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.status) {
      case SftpBrowserStatus.connecting:
        return CenterMessage(
          icon: Icons.folder_open_rounded,
          title: 'Opening files…',
          message: _controller.securityKeyMessage,
          showSpinner: true,
        );
      case SftpBrowserStatus.failed:
        return CenterMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not open files',
          message: _controller.errorMessage,
          actionLabel: 'Retry',
          onAction: _controller.connect,
        );
      case SftpBrowserStatus.ready:
        final entries = _controller.visibleEntries;
        if (_controller.entries.isEmpty) {
          return const CenterMessage(
            icon: Icons.inbox_rounded,
            title: 'Empty folder',
            message: 'Upload a file or create a folder to get started.',
          );
        }
        if (entries.isEmpty) {
          return CenterMessage(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            message:
                'Nothing in this folder matches “${_controller.searchQuery}”.',
            actionLabel: 'Clear search',
            onAction: _clearSearch,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return EntryTile(
              entry: entry,
              onTap: () => _onEntryTap(entry),
              onAction: (action) => _onEntryAction(action, entry),
            );
          },
        );
    }
  }

  Future<void> _navigateToPath(String path) async {
    try {
      await _controller.navigateTo(path);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _onEntryTap(SftpEntry entry) async {
    if (entry.isNavigable) {
      try {
        await _controller.open(entry);
      } catch (error) {
        _showError(error);
      }
      return;
    }
    await _showEntrySheet(entry);
  }

  Future<void> _onEntryAction(EntryAction action, SftpEntry entry) async {
    switch (action) {
      case EntryAction.download:
        await _download(entry);
      case EntryAction.rename:
        await _promptRename(entry);
      case EntryAction.delete:
        await _confirmDelete(entry);
      case EntryAction.copyPath:
        await Clipboard.setData(ClipboardData(text: entry.path));
        _showSnack('Copied path');
    }
  }

  Future<void> _showEntrySheet(SftpEntry entry) async {
    final action = await showModalBottomSheet<EntryAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        bottom: shouldApplyBottomSafeArea(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: Text(entry.isDirectory ? 'Download as tar' : 'Download'),
              onTap: () => Navigator.of(context).pop(EntryAction.download),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy path'),
              onTap: () => Navigator.of(context).pop(EntryAction.copyPath),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: const Text('Rename'),
              onTap: () => Navigator.of(context).pop(EntryAction.rename),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Delete'),
              onTap: () => Navigator.of(context).pop(EntryAction.delete),
            ),
          ],
        ),
      ),
    );
    if (action != null) {
      await _onEntryAction(action, entry);
    }
  }

  Future<void> _download(SftpEntry entry) async {
    try {
      final location = await _controller.download(entry);
      if (location != null) {
        _showSnack(
          entry.isDirectory ? 'Saved ${entry.name}.tar' : 'Saved ${entry.name}',
        );
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _promptNewFolder() async {
    final name = await _promptName(
      title: 'New folder',
      label: 'Folder name',
      action: 'Create',
    );
    if (name == null || name.isEmpty) return;
    try {
      await _controller.makeDirectory(name);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _promptRename(SftpEntry entry) async {
    final name = await _promptName(
      title: 'Rename',
      label: 'New name',
      action: 'Rename',
      initial: entry.name,
    );
    if (name == null || name.isEmpty || name == entry.name) return;
    try {
      await _controller.rename(entry, name);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _confirmDelete(SftpEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${entry.isDirectory ? 'folder' : 'file'}?'),
        content: Text('“${entry.name}” will be removed from the server.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      try {
        await _controller.delete(entry);
      } catch (error) {
        _showError(error);
      }
    }
  }

  Future<void> _pickAndUpload() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        allowMultiple: true,
        withReadStream: true,
      );
    } catch (error) {
      _showError(error);
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final files = <SftpUploadFile>[];
    for (final file in result.files) {
      final readStream = file.readStream;
      final path = file.path;
      if (readStream == null && path == null) {
        _showSnack('One of those files could not be read.');
        return;
      }
      files.add(
        readStream == null
            ? SftpUploadFile.local(
                localPath: path!,
                name: file.name,
                size: file.size,
              )
            : SftpUploadFile(
                source: () => readStream,
                name: file.name,
                size: file.size,
              ),
      );
    }
    try {
      await _controller.uploadFiles(files);
      final uploaded = files.length == 1
          ? files.single.name
          : '${files.length} files';
      _showSnack('Uploaded $uploaded');
    } catch (error) {
      _showError(error);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.clearSearch();
  }

  Future<String?> _promptName({
    required String title,
    required String label,
    required String action,
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) => _showSnack('$error');
}
