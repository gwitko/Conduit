import 'package:conduit/features/terminal/domain/network_connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityPlusNetwork implements NetworkConnectivity {
  ConnectivityPlusNetwork([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<void> get onNetworkChanged => _connectivity.onConnectivityChanged
      .where(
        (results) => results.any((result) => result != ConnectivityResult.none),
      )
      .map<void>((_) {});
}
