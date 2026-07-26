import 'package:flutter_assets_management/data/http_update_remote_data_source.dart';
import 'package:flutter_assets_management/data/update_local_data_source.dart';
import 'package:flutter_assets_management/database/updates_repository.dart';
import 'package:flutter_assets_management/models/update.dart';
import 'package:flutter_assets_management/services/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConnectivityService extends ConnectivityService {
  final bool isConnected;

  FakeConnectivityService(this.isConnected) : super.withDependencies();

  @override
  Future<bool> get isOnline async => isConnected;

  @override
  Future<bool> get isServerAvailable async => isConnected;
}

class FakeUpdateLocalDataSource implements UpdateLocalDataSource {
  final List<Update> savedUpdates = <Update>[];

  @override
  Future<Update> saveUpdate(Update update) async {
    savedUpdates.add(update);
    return update;
  }

  @override
  Future<List<Update>> getUpdatesByAssetId(String assetId) async {
    return savedUpdates.where((update) => update.assetId == assetId).toList();
  }

  @override
  Future<void> deleteUpdate(String id) async {
    savedUpdates.removeWhere((update) => update.id == id);
  }

  @override
  Future<void> addToSyncQueue({
    required String id,
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {}
}

class FakeUpdateRemoteDataSource implements UpdateRemoteDataSource {
  final Object? failure;

  FakeUpdateRemoteDataSource({this.failure});

  @override
  Future<Update> createUpdate(Update update) async {
    if (failure != null) {
      throw failure as Object;
    }
    return update;
  }

  @override
  Future<void> deleteUpdate(String id) async {}

  @override
  void dispose() {}
}

void main() {
  test('queues an update locally when remote create fails', () async {
    final local = FakeUpdateLocalDataSource();
    final repository = UpdatesRepository(
      localDataSource: local,
      remoteDataSource: FakeUpdateRemoteDataSource(failure: Exception('boom')),
      connectivityService: FakeConnectivityService(true),
    );

    final update = Update(
      id: 'update-1',
      date: DateTime.now(),
      value: 42,
      assetId: 'asset-1',
      updatedBy: 'Tester',
      updatedAt: DateTime.now(),
    );

    final created = await repository.createUpdate(update);

    expect(created.id, 'update-1');
    expect(local.savedUpdates.single.id, 'update-1');
  });
}
