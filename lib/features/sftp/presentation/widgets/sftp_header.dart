import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/sftp/presentation/sftp_browser_controller.dart';
import 'package:flutter/material.dart';

class SftpHeader extends StatelessWidget {
  const SftpHeader({
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
    super.key,
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
              tooltip: context.l10n.actionRefresh,
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
                    Text(
                      context.l10n.labelFiles,
                      style: theme.textTheme.headlineSmall,
                    ),
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
    final l10n = context.l10n;
    final itemLabel = hasQuery
        ? l10n.sftpVisibleOfTotal(visibleCount, totalCount)
        : l10n.sftpItemCount(totalCount);
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
                  hintText: context.l10n.sftpSearchFolder,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: hasQuery
                      ? IconButton(
                          tooltip: context.l10n.sftpClearSearch,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: onClearSearch,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<SftpSortMode>(
              tooltip: context.l10n.sftpSortFiles,
              initialValue: sortMode,
              onSelected: onSortChanged,
              itemBuilder: (context) => [
                _sortItem(
                  SftpSortMode.name,
                  sortMode,
                  context.l10n.labelName,
                  Icons.sort_by_alpha,
                ),
                _sortItem(
                  SftpSortMode.modified,
                  sortMode,
                  context.l10n.sftpSortModified,
                  Icons.schedule_rounded,
                ),
                _sortItem(
                  SftpSortMode.size,
                  sortMode,
                  context.l10n.sftpSortSize,
                  Icons.sd_storage,
                ),
                _sortItem(
                  SftpSortMode.type,
                  sortMode,
                  context.l10n.sftpSortType,
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
          l10n.sftpCountsSummary(
            itemLabel,
            l10n.sftpFolderCount(directoryCount),
            l10n.sftpFileCount(fileCount),
          ),
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
