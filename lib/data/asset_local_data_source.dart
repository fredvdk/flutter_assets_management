import '../database/local_database.dart';
import '../models/asset.dart';
import '../models/update.dart';

abstract class AssetLocalDataSource {
  Future<List<Asset>> getAllAssets();
  Future<void> saveAsset(Asset asset);
  Future<void> saveAssets(List<Asset> assets);
  Future<void> updateAsset(Asset asset);
  Future<void> updateAssetPrompt(String assetId, String prompt);
  Future<void> deleteAsset(String id);
  Future<void> insertUpdates(List<Update> updates);
  Future<void> addToSyncQueue({
    required String id,
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  });
}

class SqliteAssetLocalDataSource implements AssetLocalDataSource {
  final LocalDatabase _database;

  SqliteAssetLocalDataSource({LocalDatabase? database})
      : _database = database ?? LocalDatabase();

  @override
  Future<List<Asset>> getAllAssets() => _database.getAllAssets();

  @override
  Future<void> saveAsset(Asset asset) => _database.insertAsset(asset);

  @override
  Future<void> saveAssets(List<Asset> assets) => _database.insertAssets(assets);

  @override
  Future<void> updateAsset(Asset asset) => _database.updateAsset(asset);

  @override
  Future<void> updateAssetPrompt(String assetId, String prompt) =>
      _database.updateAssetPrompt(assetId, prompt);

  @override
  Future<void> deleteAsset(String id) => _database.deleteAsset(id);

  @override
  Future<void> insertUpdates(List<Update> updates) => _database.insertUpdates(updates);

  @override
  Future<void> addToSyncQueue({
    required String id,
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) => _database.addToSyncQueue(
        id: id,
        operation: operation,
        entityType: entityType,
        entityId: entityId,
        data: data,
      );
}
