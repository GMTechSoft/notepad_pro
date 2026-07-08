// lib/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionStatus {
  online,
  offline,
  unknown,
}

class ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  Stream<ConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;

  Future<ConnectionStatus> checkInitialConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return _getConnectivityStatus(connectivityResult);
  }

  void init() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _connectionStatusController.add(_getConnectivityStatus(result));
    });
  }

  ConnectionStatus _getConnectivityStatus(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet)) {
      return ConnectionStatus.online;
    } else if (result.contains(ConnectivityResult.none)) {
      return ConnectionStatus.offline;
    }
    return ConnectionStatus.unknown;
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
