import '../database/local_database.dart';
import '../models/update.dart';

abstract class UpdateLocalDataSource {
  Future<Update> saveUpdate(Update update);
  Future<List<Update>> getUpdatesByAssetId(String assetId);
  Future<void> deleteUpdate(String id);
  Future<void> addToSyncQueue({
    required String id,
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  });
}

class SqliteUpdateLocalDataSource implements UpdateLocalDataSource {
  final LocalDatabase _database;

  SqliteUpdateLocalDataSource({LocalDatabase? database})
      : _database = database ?? LocalDatabase();

  @override
  Future<Update> saveUpdate(Update update) async {
    await _database.insertUpdate(update);
    return update;
  }

  @override
  Future<List<Update>> getUpdatesByAssetId(String assetId) =>
      _database.getUpdatesByAssetId(assetId);

  @override
  Future<void> deleteUpdate(String id) => _database.deleteUpdate(id);

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
