import 'dart:async';

typedef SshPasswordPrompt = Future<String?> Function(SshPasswordRequest request);

class SshPasswordRequest {
  const SshPasswordRequest({required this.endpoint, this.hostName = ''});

  /// For example `root@172.28.28.1:22`.
  final String endpoint;
  final String hostName;
}

/// Lets the SSH layer ask the screen currently on top for a password.
/// The password is only passed back to the caller; it is never stored here.
class SshPasswordInteraction {
  SshPasswordInteraction._();

  static final instance = SshPasswordInteraction._();

  final _prompts = <SshPasswordPrompt>[];

  void registerPrompt(SshPasswordPrompt prompt) => _prompts.add(prompt);

  void unregisterPrompt(SshPasswordPrompt prompt) => _prompts.remove(prompt);

  /// Returns null if the user cancels or no screen can show a prompt.
  Future<String?> requestPassword(SshPasswordRequest request) {
    if (_prompts.isEmpty) {
      return Future<String?>.value();
    }
    return _prompts.last(request);
  }
}
