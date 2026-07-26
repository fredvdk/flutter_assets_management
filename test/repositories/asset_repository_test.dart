import 'package:flutter_assets_management/data/asset_local_data_source.dart';
import 'package:flutter_assets_management/data/http_asset_remote_data_source.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/models/update.dart';
import 'package:flutter_assets_management/services/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConnectivityService extends ConnectivityService {
  final bool isConnected;

  FakeConnectivityService(this.isConnected)
      : super.withDependencies();

  @override
  Future<bool> get isOnline async => isConnected;

  @override
  Future<bool> get isServerAvailable async => isConnected;
}

class FakeAssetLocalDataSource implements AssetLocalDataSource {
  final List<Asset> savedAssets = <Asset>[];
  final List<Asset> availableAssets = <Asset>[];

  @override
  Future<List<Asset>> getAllAssets() async => List<Asset>.from(availableAssets);

  @override
  Future<void> saveAsset(Asset asset) async {
    savedAssets.add(asset);
    availableAssets.add(asset);
  }

  @override
  Future<void> saveAssets(List<Asset> assets) async {
    for (final asset in assets) {
      await saveAsset(asset);
    }
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    final index = availableAssets.indexWhere((current) => current.id == asset.id);
    if (index != -1) {
      availableAssets[index] = asset;
    }
  }

  @override
  Future<void> updateAssetPrompt(String assetId, String prompt) async {
    final index = availableAssets.indexWhere((asset) => asset.id == assetId);
    if (index != -1) {
      final asset = availableAssets[index];
      availableAssets[index] = Asset(
        id: asset.id,
        name: asset.name,
        type: asset.type,
        bank: asset.bank,
        createdBy: asset.createdBy,
        created: asset.created,
        notes: asset.notes,
        prompt: prompt,
        updates: asset.updates,
      );
    }
  }

  @override
  Future<void> deleteAsset(String id) async {
    availableAssets.removeWhere((asset) => asset.id == id);
  }

  @override
  Future<void> insertUpdates(List<Update> updates) async {}

  @override
  Future<void> addToSyncQueue({
    required String id,
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {}
}

class FakeAssetRemoteDataSource implements AssetRemoteDataSource {
  final Object? failure;
  int fetchCalls = 0;
  int createCalls = 0;

  FakeAssetRemoteDataSource({this.failure});

  @override
  Future<List<Asset>> fetchAssets() async {
    fetchCalls += 1;
    if (failure != null) {
      throw failure as Object;
    }
    return <Asset>[];
  }

  @override
  Future<Asset> createAsset(Asset asset) async {
    createCalls += 1;
    if (failure != null) {
      throw failure as Object;
    }
    return asset;
  }

  @override
  Future<Asset> updateAsset(String id, Asset asset) async => asset;

  @override
  Future<void> deleteAsset(String id) async {}

  @override
  Future<void> updateAssetPrompt(String assetId, String prompt) async {}

  @override
  void dispose() {}
}

void main() {
  group('AssetRepository', () {
    test('uses local data when offline', () async {
      final local = FakeAssetLocalDataSource();
      final remote = FakeAssetRemoteDataSource();
      final repository = AssetRepository(
        localDataSource: local,
        remoteDataSource: remote,
        connectivityService: FakeConnectivityService(false),
      );

      final asset = Asset(id: 'asset-1', name: 'Cash', updates: []);
      local.availableAssets.add(asset);

      final result = await repository.fetchAssets();

      expect(result.single.id, 'asset-1');
      expect(remote.fetchCalls, 0);
    });

    test('falls back to local storage when remote create fails', () async {
      final local = FakeAssetLocalDataSource();
      final remote = FakeAssetRemoteDataSource(failure: Exception('boom'));
      final repository = AssetRepository(
        localDataSource: local,
        remoteDataSource: remote,
        connectivityService: FakeConnectivityService(true),
      );

      final asset = Asset(id: 'asset-2', name: 'ETF', updates: []);
      final created = await repository.createAsset(asset);

      expect(created.id, 'asset-2');
      expect(local.savedAssets.single.id, 'asset-2');
      expect(remote.createCalls, 1);
    });
  });
}
