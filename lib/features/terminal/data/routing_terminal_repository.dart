import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_session.dart';

class RoutingTerminalRepository implements SshTerminalRepository {
  const RoutingTerminalRepository({required this.ssh, required this.mosh});

  final SshTerminalRepository ssh;
  final SshTerminalRepository mosh;

  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) {
    final repository = host.useMosh ? mosh : ssh;
    return repository.connect(host, columns: columns, rows: rows);
  }
}
