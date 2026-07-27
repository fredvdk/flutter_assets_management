import 'package:flutter_assets_management/data/asset_local_data_source.dart';
import 'package:flutter_assets_management/data/http_asset_remote_data_source.dart';
import 'package:flutter_assets_management/database/local_database.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/models/update.dart';
import 'package:flutter_assets_management/services/connectivity_service.dart';
import 'package:flutter_assets_management/services/sync_service.dart';

class FakeSyncService extends SyncService {
  FakeSyncService()
    : super(
        localDatabase: LocalDatabase(),
        connectivityService: null,
        client: null,
      );

  @override
  Future<void> refreshPendingOperationsCount() async {}
}


class FakeConnectivityService extends ConnectivityService {
  FakeConnectivityService() : super.withDependencies();

  @override
  Future<bool> get isServerAvailable async => false;
}

class FakeAssetLocalDataSource implements AssetLocalDataSource {
  bool throwError;
  FakeAssetLocalDataSource({this.throwError = false});

  List<Asset> fakeAssets = [
    Asset(
      id: '1',
      name: 'Asset 1',
      type: null,
      bank: 'Bank 1',
      createdBy: 'User 1',
      created: DateTime.now(),
      notes: 'Notes for Asset 1',
      updates: [],
    ),
    Asset(
      id: '2',
      name: 'Asset 2',
      type: 'Type B',
      bank: 'Bank 2',
      createdBy: 'User 2',
      created: DateTime.now(),
      notes: 'Notes for Asset 2',
      updates: [],
    ),
    Asset(
      id: '3',
      name: 'Asset 3',
      type: 'Type A',
      bank: 'Bank 3',
      createdBy: 'User 3',
      created: DateTime.now(),
      notes: 'Notes for Asset 3',
      updates: [],
    ),
    Asset(
      id: '4',
      name: 'Asset 4',
      type: 'Type B',
      bank: 'Bank 4',
      createdBy: 'User 4',
      created: DateTime.now(),
      notes: 'Notes for Asset 4',
      updates: [],
    ),
  ];

  @override
  Future<void> addToSyncQueue({
    required String id,
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {}

  @override
  Future<void> deleteAsset(String id) {
    // TODO: implement deleteAsset
    throw UnimplementedError();
  }

  @override
  Future<List<Asset>> getAllAssets() {
    if (throwError) {
      throw Exception('Simulated error fetching assets');
    }
    return Future.value(List<Asset>.from(fakeAssets));
  }

  @override
  Future<void> insertUpdates(List<Update> updates) {
    // TODO: implement insertUpdates
    throw UnimplementedError();
  }

  @override
  Future<void> saveAsset(Asset asset) async {
    fakeAssets.add(asset);
  }

  @override
  Future<void> saveAssets(List<Asset> assets) {
    // TODO: implement saveAssets
    throw UnimplementedError();
  }

  @override
  Future<void> updateAsset(Asset asset) {
    // TODO: implement updateAsset
    throw UnimplementedError();
  }

  @override
  Future<void> updateAssetPrompt(String assetId, String prompt) {
    // TODO: implement updateAssetPrompt
    throw UnimplementedError();
  }
}

class FakeRemoteDataSource implements AssetRemoteDataSource {
  @override
  Future<Asset> createAsset(Asset asset) {
    // TODO: implement createAsset
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAsset(String id) {
    // TODO: implement deleteAsset
    throw UnimplementedError();
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  Future<List<Asset>> fetchAssets() {
    // TODO: implement fetchAssets
    throw UnimplementedError();
  }

  @override
  Future<Asset> updateAsset(String id, Asset asset) {
    // TODO: implement updateAsset
    throw UnimplementedError();
  }

  @override
  Future<void> updateAssetPrompt(String assetId, String prompt) {
    // TODO: implement updateAssetPrompt
    throw UnimplementedError();
  }
}
