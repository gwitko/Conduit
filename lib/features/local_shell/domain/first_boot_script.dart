class FirstBootConfig {
  const FirstBootConfig({
    required this.pacmanMirror,
    required this.keyringName,
    required this.doneMarkerPath,
    this.nameservers = const ['1.1.1.1', '8.8.8.8'],
    this.locales = const ['en_US.UTF-8 UTF-8', 'C.UTF-8 UTF-8'],
    this.defaultLocale = 'en_US.UTF-8',
  });

  final String pacmanMirror;
  final String keyringName;

  final String doneMarkerPath;
  final List<String> nameservers;
  final List<String> locales;
  final String defaultLocale;
}

class FirstBootScript {
  const FirstBootScript();

  String generate(FirstBootConfig config) {
    final buffer = StringBuffer()
      ..writeln('#!/bin/bash')
      ..writeln('set -euo pipefail')
      ..writeln()
      ..writeln('# Idempotent: bail out if first boot already completed.')
      ..writeln('if [ -f "${config.doneMarkerPath}" ]; then')
      ..writeln('  exit 0')
      ..writeln('fi')
      ..writeln()
      ..writeln('# --- DNS resolution ---')
      ..writeln('rm -f /etc/resolv.conf');
    for (final nameserver in config.nameservers) {
      buffer.writeln('echo "nameserver $nameserver" >> /etc/resolv.conf');
    }
    buffer
      ..writeln()
      ..writeln('# --- hosts ---')
      ..writeln('cat > /etc/hosts <<EOF')
      ..writeln('127.0.0.1 localhost')
      ..writeln('::1 localhost')
      ..writeln('EOF')
      ..writeln()
      ..writeln('# --- pacman mirror ---')
      ..writeln('mkdir -p /etc/pacman.d')
      ..writeln(
        "echo 'Server = ${config.pacmanMirror}' > /etc/pacman.d/mirrorlist",
      )
      ..writeln()
      ..writeln('# --- locale ---');
    for (final locale in config.locales) {
      buffer.writeln("echo '$locale' >> /etc/locale.gen");
    }
    buffer
      ..writeln('locale-gen')
      ..writeln("echo 'LANG=${config.defaultLocale}' > /etc/locale.conf")
      ..writeln()
      ..writeln('# --- entropy seed (keeps pacman-key from blocking) ---')
      ..writeln('mkdir -p /var/lib')
      ..writeln('head -c 4096 /dev/urandom > /root/.rnd 2>/dev/null || true')
      ..writeln()
      ..writeln('# --- pacman keyring ---')
      ..writeln('pacman-key --init')
      ..writeln('pacman-key --populate ${config.keyringName}')
      ..writeln()
      ..writeln('# --- first-login welcome (shown once) ---')
      ..writeln('mkdir -p /etc/profile.d')
      ..writeln("cat > /etc/profile.d/conduit-welcome.sh <<'WELCOME'")
      ..writeln('if [ ! -f "\$HOME/.conduit-welcomed" ]; then')
      ..writeln('  echo "Arch Linux - running locally via Conduit."')
      ..writeln(
        '  echo "Tip: run  pacman -Syu  to refresh before installing '
        'packages."',
      )
      ..writeln('  echo')
      ..writeln('  touch "\$HOME/.conduit-welcomed" 2>/dev/null || true')
      ..writeln('fi')
      ..writeln('WELCOME')
      ..writeln()
      ..writeln('# --- mark complete ---')
      ..writeln('mkdir -p "\$(dirname "${config.doneMarkerPath}")"')
      ..writeln('touch "${config.doneMarkerPath}"');

    return buffer.toString();
  }
}
