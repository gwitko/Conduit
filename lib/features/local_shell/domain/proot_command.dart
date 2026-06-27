class ProotCommand {
  const ProotCommand({
    required this.executable,
    required this.arguments,
    required this.environment,
  });

  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
}

class ProotCommandBuilder {
  const ProotCommandBuilder({
    required this.prootBinary,
    required this.loaderPath,
    required this.libraryPath,
    required this.tmpDir,
  });

  final String prootBinary;
  final String loaderPath;

  final String libraryPath;
  final String tmpDir;

  static const _path =
      '/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin';

  Map<String, String> _environment() => {
    'PROOT_LOADER': loaderPath,
    'PROOT_TMP_DIR': tmpDir,
    'LD_LIBRARY_PATH': libraryPath,
  };

  List<String> _guestBindings() => const [
    '-b',
    '/dev',
    '-b',
    '/proc',
    '-b',
    '/sys',
    '-b',
    '/dev/pts',
    '-b',
    '/dev/urandom:/dev/random',
    '-b',
    '/proc/self/fd:/dev/fd',
    '-b',
    '/proc/self/fd/0:/dev/stdin',
    '-b',
    '/proc/self/fd/1:/dev/stdout',
    '-b',
    '/proc/self/fd/2:/dev/stderr',
  ];

  ProotCommand login({
    required String rootfsDir,
    List<String> command = const ['/bin/bash', '--login'],
    Map<String, String> extraEnv = const {},
  }) {
    final env = <String>[
      'HOME=/root',
      'TERM=xterm-256color',
      'LANG=C.UTF-8',
      'PATH=$_path',
      'PS1=[\\u@archlinux \\W]\\\$ ',
      for (final entry in extraEnv.entries) '${entry.key}=${entry.value}',
    ];

    return ProotCommand(
      executable: prootBinary,
      arguments: [
        '--kill-on-exit',
        '--link2symlink',
        '-0',
        '-r',
        rootfsDir,
        ..._guestBindings(),
        '--cwd=/root',
        '-k',
        '5.4.0',
        '/usr/bin/env',
        '-i',
        ...env,
        ...command,
      ],
      environment: _environment(),
    );
  }

  ProotCommand runScript({required String rootfsDir, required String script}) {
    return login(rootfsDir: rootfsDir, command: ['/bin/bash', '-lc', script]);
  }

  ProotCommand extractTar({
    required String archivePath,
    required String rootfsDir,
    required String tarBinary,
    required String xzBinary,
    int stripComponents = 1,
    List<String> excludes = const [],
  }) {
    return ProotCommand(
      executable: prootBinary,
      arguments: [
        '--kill-on-exit',
        '--link2symlink',
        '-0',
        tarBinary,
        '--use-compress-program=$xzBinary',
        '--warning=no-unknown-keyword',
        '--delay-directory-restore',
        '--strip-components=$stripComponents',
        '-x',
        '-p',
        '-f',
        archivePath,
        '-C',
        rootfsDir,
        for (final exclude in excludes) '--exclude=$exclude',
      ],
      environment: _environment(),
    );
  }
}
