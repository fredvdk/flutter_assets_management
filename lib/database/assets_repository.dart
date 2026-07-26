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

  Future<List<Asset>> getCachedAssets() async {
    return _localDb.getAllAssets();
  }

  Future<List<Asset>> fetchAssets() async {
    final localAssets = await _localDb.getAllAssets();
    if (localAssets.isNotEmpty) {
      print('Loaded ${localAssets.length} assets from local cache');
    } else {
      print('No local assets cached yet');
    }

    if (await _connectivity.isServerAvailable) {
      print('Server available, fetching assets from server');
      try {
        final response = await _client.get(
          Uri.parse(
            '$_baseUrl?select=id,name,updates(id,asset_id,date,value,updated_by,updated_at),type,bank,created_by,created_at,notes,prompt',
          ),
        );
        _ensureSuccess(response);
        final decoded = jsonDecode(response.body);
        final assets = (decoded as List)
            .map((item) => Asset.fromJson(item))
            .toList();

        // Cache the fetched assets locally
        await _localDb.insertAssets(assets);

        // Flatten all updates to insert them in a single batch
        final allUpdates = assets.expand((asset) => asset.updates).toList();
        await _localDb.insertUpdates(allUpdates);

        return assets;
      } catch (e) {
        print('Error fetching from server, falling back to local: $e');
        return localAssets;
      }
    } else {
      print('Server not available, loading assets from local cache');
      return localAssets;
    }
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

    if (isServerAvailable) {
      try {
        final response = await _client.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Prefer': 'return=representation',
          },
          body: jsonEncode(assetWithId.toJson(includeUpdates: false)),
        );
        _ensureSuccess(response, acceptedStatuses: [200, 201]);

        final List<dynamic> json = jsonDecode(response.body);
        final createdAsset = Asset.fromJson(json.first as Map<String, dynamic>);
        await _localDb.insertAsset(createdAsset);

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
      data: asset.toJson(
        includeUpdates: false,
      ), // Updates are handled by their own repo sync
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
