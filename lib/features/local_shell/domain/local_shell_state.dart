enum LocalShellStage {
  checking,

  unsupported,

  notInstalled,

  downloading,

  extracting,

  configuring,

  ready,

  failed,
}

enum LocalShellErrorKind {
  unsupportedDevice,
  network,
  lowDisk,
  corruptDownload,
  extractionFailed,
  keyringFailed,
  unknown,
}

class LocalShellError {
  const LocalShellError(this.kind, this.message);

  final LocalShellErrorKind kind;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is LocalShellError &&
      other.kind == kind &&
      other.message == message;

  @override
  int get hashCode => Object.hash(kind, message);
}

class LocalShellState {
  const LocalShellState({
    required this.stage,
    this.progress,
    this.message,
    this.error,
    this.installedVersion,
    this.diskUsageBytes,
  });

  final LocalShellStage stage;

  final double? progress;

  final String? message;

  final LocalShellError? error;

  final String? installedVersion;

  final int? diskUsageBytes;

  static const initial = LocalShellState(stage: LocalShellStage.checking);
  static const notInstalled = LocalShellState(
    stage: LocalShellStage.notInstalled,
  );

  bool get isBusy =>
      stage == LocalShellStage.downloading ||
      stage == LocalShellStage.extracting ||
      stage == LocalShellStage.configuring;

  bool get isReady => stage == LocalShellStage.ready;

  bool get isChecking => stage == LocalShellStage.checking;

  bool get isUnsupported => stage == LocalShellStage.unsupported;

  bool get canInstall =>
      stage == LocalShellStage.notInstalled || stage == LocalShellStage.failed;

  LocalShellState copyWith({
    LocalShellStage? stage,
    double? progress,
    String? message,
    LocalShellError? error,
    String? installedVersion,
    int? diskUsageBytes,
    bool clearProgress = false,
    bool clearError = false,
  }) {
    return LocalShellState(
      stage: stage ?? this.stage,
      progress: clearProgress ? null : (progress ?? this.progress),
      message: message ?? this.message,
      error: clearError ? null : (error ?? this.error),
      installedVersion: installedVersion ?? this.installedVersion,
      diskUsageBytes: diskUsageBytes ?? this.diskUsageBytes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LocalShellState &&
      other.stage == stage &&
      other.progress == progress &&
      other.message == message &&
      other.error == error &&
      other.installedVersion == installedVersion &&
      other.diskUsageBytes == diskUsageBytes;

  @override
  int get hashCode => Object.hash(
    stage,
    progress,
    message,
    error,
    installedVersion,
    diskUsageBytes,
  );
}
