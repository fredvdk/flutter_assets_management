import 'package:uuid/uuid.dart';

import '../data/asset_local_data_source.dart';
import '../data/http_asset_remote_data_source.dart';
import '../models/asset.dart';
import '../services/connectivity_service.dart';
import 'updates_repository.dart';

class AssetRepository {
  final AssetLocalDataSource _localDataSource;
  final AssetRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivity;
  final UpdatesRepository _updatesRepository;
  final _uuid = const Uuid();

  AssetRepository({
    AssetLocalDataSource? localDataSource,
    AssetRemoteDataSource? remoteDataSource,
    ConnectivityService? connectivityService,
    UpdatesRepository? updatesRepository,
  })  : _localDataSource = localDataSource ?? SqliteAssetLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? HttpAssetRemoteDataSource(),
        _connectivity = connectivityService ?? ConnectivityService(),
        _updatesRepository = updatesRepository ?? UpdatesRepository();

  Future<List<Asset>> fetchAssets() async {
    return _runWithFallback(
      remoteAction: () async {
        final assets = await _remoteDataSource.fetchAssets();
        await _localDataSource.saveAssets(assets);
        await _localDataSource.insertUpdates(
          assets.expand((asset) => asset.updates).toList(),
        );
        return assets;
      },
      localAction: () => _localDataSource.getAllAssets(),
    );
  }

  Future<void> updateAssetPrompt(String assetId, String prompt) async {
    await _runWithFallback<void>(
      remoteAction: () async {
        await _remoteDataSource.updateAssetPrompt(assetId, prompt);
        await _localDataSource.updateAssetPrompt(assetId, prompt);
      },
      localAction: () => _handleOfflinePromptUpdate(assetId, prompt),
    );
  }

  Future<Asset> createAsset(Asset asset) async {
    final assetWithId = asset.id.isEmpty
        ? Asset(
            id: _uuid.v4(),
            name: asset.name,
            type: asset.type,
            bank: asset.bank,
            createdBy: asset.createdBy,
            created: asset.created,
            notes: asset.notes,
            updates: asset.updates,
          )
        : asset;

    return _runWithFallback<Asset>(
      remoteAction: () async {
        final createdAsset = await _remoteDataSource.createAsset(assetWithId);
        await _localDataSource.saveAsset(createdAsset);

        if (assetWithId.updates.isNotEmpty) {
          for (final update in assetWithId.updates) {
            await _updatesRepository.createUpdate(update);
          }
        }

        return createdAsset;
      },
      localAction: () => _handleOfflineCreate(assetWithId),
    );
  }

  Future<Asset> updateAsset(String id, Asset asset) async {
    return _runWithFallback<Asset>(
      remoteAction: () async {
        final updatedAsset = await _remoteDataSource.updateAsset(id, asset);
        await _localDataSource.updateAsset(updatedAsset);
        return updatedAsset;
      },
      localAction: () => _handleOfflineUpdate(id, asset),
    );
  }

  Future<void> deleteAsset(String id) async {
    await _runWithFallback<void>(
      remoteAction: () async {
        await _remoteDataSource.deleteAsset(id);
        await _localDataSource.deleteAsset(id);
      },
      localAction: () => _handleOfflineDelete(id),
    );
  }

  Future<T> _runWithFallback<T>({
    required Future<T> Function() remoteAction,
    required Future<T> Function() localAction,
  }) async {
    if (await _connectivity.isServerAvailable) {
      try {
        return await remoteAction();
      } catch (_) {
        return localAction();
      }
    }

    return localAction();
  }

  Future<void> _handleOfflinePromptUpdate(String assetId, String prompt) async {
    await _localDataSource.updateAssetPrompt(assetId, prompt);
    await _localDataSource.addToSyncQueue(
      id: _uuid.v4(),
      operation: 'UPDATE_PROMPT',
      entityType: 'asset',
      entityId: assetId,
      data: {'prompt': prompt},
    );
  }

  Future<Asset> _handleOfflineCreate(Asset asset) async {
    await _localDataSource.saveAsset(asset);
    await _localDataSource.addToSyncQueue(
      id: _uuid.v4(),
      operation: 'CREATE',
      entityType: 'asset',
      entityId: asset.id,
      data: asset.toJson(includeUpdates: false),
    );
    return asset;
  }

  Future<Asset> _handleOfflineUpdate(String id, Asset asset) async {
    await _localDataSource.updateAsset(asset);
    await _localDataSource.addToSyncQueue(
      id: _uuid.v4(),
      operation: 'UPDATE',
      entityType: 'asset',
      entityId: id,
      data: asset.toJson(includeUpdates: false),
    );
    return asset;
  }

  Future<void> _handleOfflineDelete(String id) async {
    await _localDataSource.deleteAsset(id);
    await _localDataSource.addToSyncQueue(
      id: _uuid.v4(),
      operation: 'DELETE',
      entityType: 'asset',
      entityId: id,
      data: {},
    );
  }

  void dispose() {
    _remoteDataSource.dispose();
  }
}
