import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_session.dart';

class RoutingTerminalRepository implements SshTerminalRepository {
  const RoutingTerminalRepository({
    required this.ssh,
    required this.mosh,
    required this.local,
  });

  final SshTerminalRepository ssh;
  final SshTerminalRepository mosh;
  final SshTerminalRepository local;

  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) {
    final repository = host.isLocal
        ? local
        : host.useMosh
        ? mosh
        : ssh;
    return repository.connect(host, columns: columns, rows: rows);
  }
}
