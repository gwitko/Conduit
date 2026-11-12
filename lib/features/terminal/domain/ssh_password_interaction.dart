import 'dart:async';

typedef SshPasswordPrompt =
    Future<String?> Function(SshPasswordPromptRequest request);

/// A server-requested secret during SSH user authentication, typically the
/// account password demanded after a key was accepted with partial success
/// (OpenSSH `AuthenticationMethods publickey,password`).
class SshPasswordPromptRequest {
  const SshPasswordPromptRequest({
    required this.username,
    required this.host,
    this.prompt = 'Password',
    this.instruction = '',
    this.echo = false,
  });

  final String username;
  final String host;

  /// Server-supplied prompt text for keyboard-interactive auth, or
  /// `Password` for the plain password method.
  final String prompt;

  /// Optional keyboard-interactive instruction text from the server.
  final String instruction;

  /// Whether the answer may be shown while typing.
  final bool echo;
}

class SshPasswordInteraction {
  SshPasswordInteraction._();

  static final instance = SshPasswordInteraction._();

  final _prompts = <SshPasswordPrompt>[];

  void registerPrompt(SshPasswordPrompt prompt) {
    _prompts.add(prompt);
  }

  void unregisterPrompt(SshPasswordPrompt prompt) {
    _prompts.remove(prompt);
  }

  /// Asks the topmost registered UI for a secret. Resolves to null when no UI
  /// is listening or the user cancels, which makes the SSH client move on to
  /// its next authentication method.
  Future<String?> requestPassword(SshPasswordPromptRequest request) {
    if (_prompts.isEmpty) {
      return Future<String?>.value();
    }
    return _prompts.last(request);
  }
}
