import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

enum ConnectionStatus { online, offline }

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
    return _connectivity.onConnectivityChanged.map((result) {
      return result.contains(ConnectivityResult.none)
          ? ConnectionStatus.offline
          : ConnectionStatus.online;
    });
  }

  Stream<bool> get isOnlineStream =>
      connectionStatusStream.map((status) => status == ConnectionStatus.online);

  Future<ConnectionStatus> get currentStatus async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.none)
        ? ConnectionStatus.offline
        : ConnectionStatus.online;
  }

  Future<bool> get isOnline async => (await currentStatus) == ConnectionStatus.online;

  Future<bool> get isServerAvailable async {
    if (!await isOnline) {
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
