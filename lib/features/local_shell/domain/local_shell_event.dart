import 'package:conduit/features/local_shell/domain/local_shell_state.dart';

sealed class LocalShellEvent {
  const LocalShellEvent();
}

class DeviceUnsupported extends LocalShellEvent {
  const DeviceUnsupported(this.reason);

  final String reason;
}

class EnvironmentReady extends LocalShellEvent {
  const EnvironmentReady({required this.version, this.diskUsageBytes});

  final String version;
  final int? diskUsageBytes;
}

class EnvironmentMissing extends LocalShellEvent {
  const EnvironmentMissing();
}

class InstallRequested extends LocalShellEvent {
  const InstallRequested();
}

class DownloadProgressed extends LocalShellEvent {
  const DownloadProgressed(this.progress);

  final double progress;
}

class DownloadFinished extends LocalShellEvent {
  const DownloadFinished();
}

class ExtractFinished extends LocalShellEvent {
  const ExtractFinished();
}

class ConfigureStarted extends LocalShellEvent {
  const ConfigureStarted();
}

class InstallSucceeded extends LocalShellEvent {
  const InstallSucceeded({required this.version, this.diskUsageBytes});

  final String version;
  final int? diskUsageBytes;
}

class InstallFailed extends LocalShellEvent {
  const InstallFailed(this.error);

  final LocalShellError error;
}

class ResetRequested extends LocalShellEvent {
  const ResetRequested();
}
