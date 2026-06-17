import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/sftp/domain/file_export.dart';
import 'package:conduit/features/sftp/domain/sftp_entry.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/sftp/presentation/sftp_browser_controller.dart';
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
    _controller = SftpBrowserController(
      host: widget.host,
      repository: widget.repository,
      fileExport: widget.fileExport,
    );
    _controller.connect();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
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
                  _Header(
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
                    _TransferBar(transfer: _controller.transfer!),
                ],
              ),
            ),
          ),
          floatingActionButton:
              _controller.status == SftpBrowserStatus.ready &&
                  !_controller.busy &&
                  _controller.transfer == null
              ? _ActionsFab(
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
        return _CenterMessage(
          icon: Icons.folder_open_rounded,
          title: 'Opening files…',
          message: _controller.securityKeyMessage,
          showSpinner: true,
        );
      case SftpBrowserStatus.failed:
        return _CenterMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not open files',
          message: _controller.errorMessage,
          actionLabel: 'Retry',
          onAction: _controller.connect,
        );
      case SftpBrowserStatus.ready:
        final entries = _controller.visibleEntries;
        if (_controller.entries.isEmpty) {
          return const _CenterMessage(
            icon: Icons.inbox_rounded,
            title: 'Empty folder',
            message: 'Upload a file or create a folder to get started.',
          );
        }
        if (entries.isEmpty) {
          return _CenterMessage(
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
            return _EntryTile(
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

  Future<void> _onEntryAction(_EntryAction action, SftpEntry entry) async {
    switch (action) {
      case _EntryAction.download:
        await _download(entry);
      case _EntryAction.rename:
        await _promptRename(entry);
      case _EntryAction.delete:
        await _confirmDelete(entry);
      case _EntryAction.copyPath:
        await Clipboard.setData(ClipboardData(text: entry.path));
        _showSnack('Copied path');
    }
  }

  Future<void> _showEntrySheet(SftpEntry entry) async {
    final action = await showModalBottomSheet<_EntryAction>(
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
              onTap: () => Navigator.of(context).pop(_EntryAction.download),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy path'),
              onTap: () => Navigator.of(context).pop(_EntryAction.copyPath),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: const Text('Rename'),
              onTap: () => Navigator.of(context).pop(_EntryAction.rename),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Delete'),
              onTap: () => Navigator.of(context).pop(_EntryAction.delete),
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

enum _EntryAction { download, rename, delete, copyPath }

class _Header extends StatelessWidget {
  const _Header({
    required this.hostName,
    required this.path,
    required this.busy,
    required this.searchController,
    required this.searchQuery,
    required this.sortMode,
    required this.totalCount,
    required this.visibleCount,
    required this.directoryCount,
    required this.fileCount,
    required this.onBack,
    required this.onSegmentTap,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortChanged,
    required this.onRefresh,
  });

  final String hostName;
  final String path;
  final bool busy;
  final TextEditingController searchController;
  final String searchQuery;
  final SftpSortMode sortMode;
  final int totalCount;
  final int visibleCount;
  final int directoryCount;
  final int fileCount;
  final VoidCallback onBack;
  final ValueChanged<String> onSegmentTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<SftpSortMode> onSortChanged;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final busyIndicator = SizedBox(
      width: 40,
      height: 40,
      child: busy
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: onRefresh,
            ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Files', style: theme.textTheme.headlineSmall),
                    Text(
                      hostName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              busyIndicator,
            ],
          ),
          const SizedBox(height: 10),
          _Breadcrumb(path: path, onSegmentTap: onSegmentTap),
          const SizedBox(height: 12),
          _FileToolbar(
            controller: searchController,
            query: searchQuery,
            sortMode: sortMode,
            totalCount: totalCount,
            visibleCount: visibleCount,
            directoryCount: directoryCount,
            fileCount: fileCount,
            onSearchChanged: onSearchChanged,
            onClearSearch: onClearSearch,
            onSortChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

class _FileToolbar extends StatelessWidget {
  const _FileToolbar({
    required this.controller,
    required this.query,
    required this.sortMode,
    required this.totalCount,
    required this.visibleCount,
    required this.directoryCount,
    required this.fileCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final String query;
  final SftpSortMode sortMode;
  final int totalCount;
  final int visibleCount;
  final int directoryCount;
  final int fileCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<SftpSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasQuery = query.trim().isNotEmpty;
    final itemLabel = hasQuery
        ? '$visibleCount of $totalCount'
        : '$totalCount ${totalCount == 1 ? 'item' : 'items'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search folder',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: hasQuery
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: onClearSearch,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<SftpSortMode>(
              tooltip: 'Sort files',
              initialValue: sortMode,
              onSelected: onSortChanged,
              itemBuilder: (context) => [
                _sortItem(
                  SftpSortMode.name,
                  sortMode,
                  'Name',
                  Icons.sort_by_alpha,
                ),
                _sortItem(
                  SftpSortMode.modified,
                  sortMode,
                  'Modified',
                  Icons.schedule_rounded,
                ),
                _sortItem(
                  SftpSortMode.size,
                  sortMode,
                  'Size',
                  Icons.sd_storage,
                ),
                _sortItem(
                  SftpSortMode.type,
                  sortMode,
                  'Type',
                  Icons.category_outlined,
                ),
              ],
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$itemLabel  ·  $directoryCount folders  ·  $fileCount files',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  PopupMenuItem<SftpSortMode> _sortItem(
    SftpSortMode value,
    SftpSortMode current,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: value == current ? const Icon(Icons.check_rounded) : null,
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 24,
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.path, required this.onSegmentTap});

  final String path;
  final ValueChanged<String> onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final crumbs = <({String label, String target})>[
      (label: 'root', target: '/'),
    ];
    var accumulated = '';
    for (final segment in segments) {
      accumulated = '$accumulated/$segment';
      crumbs.add((label: segment, target: accumulated));
    }

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: crumbs.length,
        itemBuilder: (context, index) {
          final crumb = crumbs[index];
          final isLast = index == crumbs.length - 1;
          return Row(
            children: [
              if (index > 0)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: isLast ? null : () => onSegmentTap(crumb.target),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    crumb.label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
                      color: isLast
                          ? colorScheme.onSurface
                          : colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onTap,
    required this.onAction,
  });

  final SftpEntry entry;
  final VoidCallback onTap;
  final ValueChanged<_EntryAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              _EntryIcon(entry: entry),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(entry),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _EntryActionsButton(entry: entry, onAction: onAction),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(SftpEntry entry) {
    final parts = <String>[];
    if (entry.isDirectory) {
      parts.add('folder');
    } else if (entry.isSymlink) {
      parts.add('link');
    } else if (entry.size != null) {
      parts.add(_formatSize(entry.size!));
    }
    final modified = entry.modifiedAt;
    if (modified != null) {
      parts.add(_formatDate(modified));
    }
    final perms = entry.permissionString;
    if (perms.isNotEmpty) {
      parts.add(perms);
    }
    return parts.join('  ·  ');
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var size = bytes / 1024;
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unit]}';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _EntryActionsButton extends StatelessWidget {
  const _EntryActionsButton({required this.entry, required this.onAction});

  final SftpEntry entry;
  final ValueChanged<_EntryAction> onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: 36,
      child: PopupMenuButton<_EntryAction>(
        tooltip: 'Item options',
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(
          Icons.more_vert_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        onSelected: onAction,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _EntryAction.download,
            child: ListTile(
              leading: const Icon(Icons.download_rounded),
              title: Text(entry.isDirectory ? 'Download as tar' : 'Download'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 24,
            ),
          ),
          const PopupMenuItem(
            value: _EntryAction.copyPath,
            child: ListTile(
              leading: Icon(Icons.copy_rounded),
              title: Text('Copy path'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 24,
            ),
          ),
          const PopupMenuItem(
            value: _EntryAction.rename,
            child: ListTile(
              leading: Icon(Icons.drive_file_rename_outline_rounded),
              title: Text('Rename'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 24,
            ),
          ),
          PopupMenuItem(
            value: _EntryAction.delete,
            child: ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
              ),
              title: const Text('Delete'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryIcon extends StatelessWidget {
  const _EntryIcon({required this.entry});

  final SftpEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, accent) = switch (entry.kind) {
      SftpEntryKind.directory => (Icons.folder_rounded, true),
      SftpEntryKind.symlink => (Icons.link_rounded, false),
      _ => (Icons.insert_drive_file_outlined, false),
    };
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent
            ? Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.16),
                colorScheme.surface,
              )
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Icon(
        icon,
        size: 19,
        color: accent ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _TransferBar extends StatelessWidget {
  const _TransferBar({required this.transfer});

  final SftpTransfer transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                transfer.isUpload
                    ? Icons.upload_rounded
                    : Icons.download_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${transfer.isUpload ? 'Uploading' : 'Downloading'} '
                  '${transfer.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: transfer.fraction,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsFab extends StatelessWidget {
  const _ActionsFab({required this.onNewFolder, required this.onUpload});

  final VoidCallback onNewFolder;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'sftp-new-folder',
          tooltip: 'New folder',
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          onPressed: onNewFolder,
          child: const Icon(Icons.create_new_folder_outlined),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'sftp-upload',
            backgroundColor: Colors.transparent,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            onPressed: onUpload,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Upload'),
          ),
        ),
      ],
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.showSpinner = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.alphaBlend(
                  colorScheme.primary.withValues(alpha: 0.16),
                  colorScheme.surface,
                ),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(icon, size: 32, color: colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (showSpinner) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
