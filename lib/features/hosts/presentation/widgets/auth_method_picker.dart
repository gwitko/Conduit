import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:flutter/material.dart';

class AuthMethodPicker extends StatelessWidget {
  const AuthMethodPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final SshAuthMethod value;
  final ValueChanged<SshAuthMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        _AuthMethodTile(
          value: SshAuthMethod.password,
          groupValue: value,
          icon: Icons.password_rounded,
          title: 'Password',
          subtitle: 'Use the account password for SSH login.',
          onChanged: onChanged,
        ),
        _AuthMethodTile(
          value: SshAuthMethod.privateKey,
          groupValue: value,
          icon: Icons.vpn_key_rounded,
          title: 'Private key',
          subtitle: 'Use a PEM or OpenSSH private key.',
          onChanged: onChanged,
        ),
        _AuthMethodTile(
          value: SshAuthMethod.hardwareKey,
          groupValue: value,
          icon: Icons.usb_rounded,
          title: 'Hardware key',
          subtitle: 'Use one or more security keys over USB or NFC.',
          onChanged: onChanged,
        ),
        _AuthMethodTile(
          value: SshAuthMethod.external,
          groupValue: value,
          icon: Icons.link_rounded,
          title: 'External',
          subtitle:
              'Let the SSH server authenticate without saved credentials.',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AuthMethodTile extends StatelessWidget {
  const _AuthMethodTile({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final SshAuthMethod value;
  final SshAuthMethod groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<SshAuthMethod> onChanged;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: _selected
                ? Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.12),
                    colorScheme.surface,
                  )
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: _selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _selected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: _selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthExplainer extends StatelessWidget {
  const AuthExplainer({required this.method, super.key});

  final SshAuthMethod method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hardwareKey = method == SshAuthMethod.hardwareKey;
    final external = method == SshAuthMethod.external;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.08),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            external
                ? Icons.link_rounded
                : hardwareKey
                ? Icons.usb_rounded
                : Icons.vpn_key_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hardwareKey
                  ? 'Add the OpenSSH *_sk key stub for each security key you '
                        'own. When you connect, Conduit asks whichever key '
                        'you present to sign over USB or NFC.'
                  : external
                  ? 'Use this when authentication is handled outside Conduit, '
                        'without storing a password or private key in the app.'
                  : 'Use a normal SSH private key. If the key is encrypted, '
                        'enter its passphrase below.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
