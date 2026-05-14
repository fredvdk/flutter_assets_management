import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  late final Connectivity _connectivity;

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal() {
    _connectivity = Connectivity();
  }

  Stream<bool> get connectionStatusStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result.contains(ConnectivityResult.none) ? false : true;
    });
  }

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
