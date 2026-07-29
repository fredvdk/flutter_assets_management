import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_assets_management/services/connectivity_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class FakeConnectivity implements Connectivity {
  List<ConnectivityResult> checkResults = [ConnectivityResult.wifi];

  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => checkResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> result) => _controller.add(result);
}

class FakeHttpClient extends http.BaseClient {
  int statusCode = 200;
  Object? error;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (error != null) {
      throw error!;
    }
    return http.StreamedResponse(Stream.value(<int>[]), statusCode);
  }
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'BASE_URL=http://localhost:3000');
  });

  group('ConnectivityService', () {
    test('when device is offline isOnline reports false', () async {
      final fakeConnectivity = FakeConnectivity();
      fakeConnectivity.checkResults = [ConnectivityResult.none];

      final fakeHttpClient = FakeHttpClient();

      final connectivityService = ConnectivityService.withDependencies(
        connectivity: fakeConnectivity,
        client: fakeHttpClient,
      );

      final result = await connectivityService.isOnline;
      expect(result, false);
      expect(await connectivityService.currentStatus, ConnectionStatus.offline);
    });

    test(
      'when device is online and server responds with 200 isOnline reports true',
      () async {
        final fakeConnectivity = FakeConnectivity();

        final fakeHttpClient = FakeHttpClient();
        fakeHttpClient.statusCode = 200;

        final connectivityService = ConnectivityService.withDependencies(
          connectivity: fakeConnectivity,
          client: fakeHttpClient,
        );

        final result = await connectivityService.isOnline;
        expect(result, true);
        expect(
          await connectivityService.currentStatus,
          ConnectionStatus.serverAvailable,
        );
      },
    );

    test(
      'when device is online and server responds with 500 isOnline reports false',
      () async {
        final fakeConnectivity = FakeConnectivity();

        final fakeHttpClient = FakeHttpClient();
        fakeHttpClient.statusCode = 500;

        final connectivityService = ConnectivityService.withDependencies(
          connectivity: fakeConnectivity,
          client: fakeHttpClient,
        );

        final result = await connectivityService.isOnline;
        expect(result, false);
        expect(
          await connectivityService.currentStatus,
          ConnectionStatus.noServer,
        );
      },
    );
  });
}
