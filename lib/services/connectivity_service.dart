import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  late final Connectivity _connectivity;
  final http.Client _client = http.Client();

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


  Future<bool> get isServerAvailable async {
    print("checking server up");
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
