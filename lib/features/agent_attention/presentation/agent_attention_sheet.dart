import 'package:conduit/features/agent_attention/domain/agent_attention.dart';
import 'package:conduit/features/agent_attention/presentation/agent_attention_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:flutter/material.dart';

/// Called when the user taps an agent: navigate to the host's terminal tab
/// (and optionally send the provider's focus command first).
typedef AgentAttentionNavigate = void Function(SavedHost host, AgentInfo agent);

/// Shows the Agent Attention dashboard: every monitored host with its
/// agents, their states, and useful empty/error/unavailable states.
Future<void> showAgentAttentionSheet({
  required BuildContext context,
  required AgentAttentionController controller,
  required AgentAttentionNavigate onOpenAgent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollController) => AgentAttentionSheet(
        controller: controller,
        scrollController: scrollController,
        onOpenAgent: onOpenAgent,
      ),
    ),
  );
}

class AgentAttentionSheet extends StatelessWidget {
  const AgentAttentionSheet({
    required this.controller,
    required this.onOpenAgent,
    this.scrollController,
    super.key,
  });

  final AgentAttentionController controller;
  final AgentAttentionNavigate onOpenAgent;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hosts = controller.monitoredHosts;
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Text('Agents', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  controller.provider.label,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hosts.isEmpty)
              const _EmptyState(
                icon: Icons.monitor_heart_outlined,
                message:
                    'No machines are being monitored. Enable agent '
                    "monitoring in a machine's settings, then connect "
                    'to it.',
              )
            else
              for (final host in hosts)
                _HostSection(
                  host: host,
                  status:
                      controller.statusFor(host.id) ??
                      const AgentHostStatus(loading: true),
                  onRefresh: () => controller.refresh(host.id),
                  onOpenAgent: (agent) => onOpenAgent(host, agent),
                ),
          ],
        );
      },
    );
  }
}

class _HostSection extends StatelessWidget {
  const _HostSection({
    required this.host,
    required this.status,
    required this.onRefresh,
    required this.onOpenAgent,
  });

  final SavedHost host;
  final AgentHostStatus status;
  final VoidCallback onRefresh;
  final ValueChanged<AgentInfo> onOpenAgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  host.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                iconSize: 18,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
        if (status.unavailableReason != null)
          _EmptyState(
            icon: Icons.extension_off_outlined,
            message: status.unavailableReason!,
          )
        else if (status.error != null)
          _EmptyState(
            icon: Icons.error_outline_rounded,
            message:
                'Could not read agent state. ${status.error!} '
                'Monitoring keeps retrying while connected.',
          )
        else if (status.loading && status.agents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (status.agents.isEmpty)
          const _EmptyState(
            icon: Icons.check_circle_outline_rounded,
            message: 'No agents are running on this machine.',
          )
        else
          for (final agent in status.agents)
            _AgentTile(agent: agent, onTap: () => onOpenAgent(agent)),
      ],
    );
  }
}

class _AgentTile extends StatelessWidget {
  const _AgentTile({required this.agent, required this.onTap});

  final AgentInfo agent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (icon, color) = switch (agent.state) {
      AgentAttentionState.working => (
        Icons.autorenew_rounded,
        colorScheme.primary,
      ),
      AgentAttentionState.needsInput => (
        Icons.pan_tool_alt_outlined,
        colorScheme.error,
      ),
      AgentAttentionState.blocked => (Icons.block_rounded, colorScheme.error),
      AgentAttentionState.finished => (
        Icons.check_circle_rounded,
        colorScheme.tertiary,
      ),
      AgentAttentionState.idle => (
        Icons.pause_circle_outline_rounded,
        colorScheme.onSurfaceVariant,
      ),
      AgentAttentionState.unknown => (
        Icons.help_outline_rounded,
        colorScheme.onSurfaceVariant,
      ),
    };
    final location = [
      if (agent.kind.isNotEmpty) agent.kind,
      if (agent.workspace != null) 'workspace ${agent.workspace}',
      if (agent.tab != null) 'tab ${agent.tab}',
    ].join(' · ');
    final changed = agent.stateChangedAt;
    return Semantics(
      label:
          'Agent ${agent.name}, ${agent.state.label}'
          '${location.isEmpty ? '' : ', $location'}',
      button: true,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color),
          title: Text(agent.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: location.isEmpty ? null : Text(location, maxLines: 1),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                agent.state.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (changed != null)
                Text(_relativeTime(changed), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final delta = DateTime.now().toUtc().difference(time.toUtc());
    if (delta.inSeconds < 60) {
      return 'just now';
    }
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes}m ago';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours}h ago';
    }
    return '${delta.inDays}d ago';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
