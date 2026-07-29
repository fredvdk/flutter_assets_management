import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

enum ConnectionStatus { serverAvailable, noServer, offline }

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final Connectivity _connectivity;
  final http.Client _client;

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService.withDependencies({Connectivity? connectivity, http.Client? client})
      : _connectivity = connectivity ?? Connectivity(),
        _client = client ?? http.Client();

  ConnectivityService._internal({Connectivity? connectivity, http.Client? client})
      : _connectivity = connectivity ?? Connectivity(),
        _client = client ?? http.Client();

  Stream<ConnectionStatus> get connectionStatusStream {
    return _connectivity.onConnectivityChanged.asyncMap((result) async {
      if (result.contains(ConnectivityResult.none)) {
        return ConnectionStatus.offline;
      }
      return (await isServerAvailable) ? ConnectionStatus.serverAvailable : ConnectionStatus.noServer;
    });
  }

  Stream<bool> get isOnlineStream =>
      connectionStatusStream.map((status) => status == ConnectionStatus.serverAvailable);

  Future<ConnectionStatus> get currentStatus async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      return ConnectionStatus.offline;
    }
    return (await isServerAvailable) ? ConnectionStatus.serverAvailable : ConnectionStatus.noServer;
  }

  Future<bool> get isOnline async => (await currentStatus) == ConnectionStatus.serverAvailable;

  Future<bool> get isServerAvailable async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final response = await _client
          .head(
            Uri.parse(Env.baseUrl),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (e) {
      return false;
    }
  }
}
