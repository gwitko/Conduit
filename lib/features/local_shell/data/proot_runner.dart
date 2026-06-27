import 'dart:convert';
import 'dart:io';

import 'package:conduit/features/local_shell/domain/proot_command.dart';

class ProotRunResult {
  const ProotRunResult({required this.exitCode, required this.stderr});

  final int exitCode;
  final String stderr;
}

Future<ProotRunResult> runProot(ProotCommand command) async {
  final process = await Process.start(
    command.executable,
    command.arguments,
    environment: command.environment,
  );

  final stderrBuffer = StringBuffer();
  final stdoutDrain = process.stdout.drain<void>();
  final stderrDrain = process.stderr
      .transform(utf8.decoder)
      .forEach(stderrBuffer.write);

  final exitCode = await process.exitCode;
  await stdoutDrain;
  await stderrDrain;

  return ProotRunResult(exitCode: exitCode, stderr: stderrBuffer.toString());
}
