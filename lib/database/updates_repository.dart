import 'package:uuid/uuid.dart';

import '../data/http_update_remote_data_source.dart';
import '../data/update_local_data_source.dart';
import '../models/update.dart';
import '../services/connectivity_service.dart';

class UpdatesRepository {
  final UpdateLocalDataSource _localDataSource;
  final UpdateRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivity;
  final _uuid = const Uuid();

  UpdatesRepository({
    UpdateLocalDataSource? localDataSource,
    UpdateRemoteDataSource? remoteDataSource,
    ConnectivityService? connectivityService,
  })  : _localDataSource = localDataSource ?? SqliteUpdateLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? HttpUpdateRemoteDataSource(),
        _connectivity = connectivityService ?? ConnectivityService();

  Future<Update> createUpdate(Update update) async {
    final updateId = update.id.isEmpty ? _uuid.v4() : update.id;
    final newUpdate = Update(
      id: updateId,
      date: update.date,
      value: update.value,
      assetId: update.assetId,
      updatedBy: update.updatedBy,
      updatedAt: update.updatedAt,
    );

    if (await _connectivity.isOnline) {
      try {
        final createdUpdate = await _remoteDataSource.createUpdate(newUpdate);
        await _localDataSource.saveUpdate(createdUpdate);
        return createdUpdate;
      } catch (_) {
        return _handleOfflineCreate(newUpdate);
      }
    }

    return _handleOfflineCreate(newUpdate);
  }

  Future<List<Update>> getUpdatesForAsset(String assetId) async {
    return _localDataSource.getUpdatesByAssetId(assetId);
  }

  Future<void> deleteUpdate(String id) async {
    if (await _connectivity.isOnline) {
      try {
        await _remoteDataSource.deleteUpdate(id);
        await _localDataSource.deleteUpdate(id);
      } catch (_) {
        await _handleOfflineDelete(id);
      }
    } else {
      await _handleOfflineDelete(id);
    }
  }

  Future<Update> _handleOfflineCreate(Update update) async {
    await _localDataSource.saveUpdate(update);
    await _localDataSource.addToSyncQueue(
      id: _uuid.v4(),
      operation: 'CREATE',
      entityType: 'update',
      entityId: update.id,
      data: update.toJson(),
    );
    return update;
  }

  Future<void> _handleOfflineDelete(String id) async {
    await _localDataSource.deleteUpdate(id);
    await _localDataSource.addToSyncQueue(
      id: _uuid.v4(),
      operation: 'DELETE',
      entityType: 'update',
      entityId: id,
      data: {},
    );
  }

  void dispose() => _remoteDataSource.dispose();
}
