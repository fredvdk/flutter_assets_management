import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

import '../models/asset.dart';
import '../models/update.dart';

void _initializeDatabase() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static Database? _database;

  factory LocalDatabase() {
    return _instance;
  }

  LocalDatabase._internal() {
    _initializeDatabase();
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
   // print('Database path: $databasePath');
    final path = join(databasePath, 'flutter_assets.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        bank TEXT,
        created_by TEXT,
        created TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE updates (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        date TEXT NOT NULL,
        value INTEGER NOT NULL,
        updated_by TEXT,
        updated_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        operation TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // ASSET OPERATIONS
  Future<void> insertAsset(Asset asset) async {
    final db = await database;
    await db.insert(
      'assets',
      {
        'id': asset.id,
        'name': asset.name,
        'type': asset.type,
        'bank': asset.bank,
        'created_by': asset.createdBy,
        'created': asset.created?.toIso8601String(),
        'notes': asset.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAssets(List<Asset> assets) async {
    final db = await database;
    final batch = db.batch();
    for (var asset in assets) {
      batch.insert(
        'assets',
        {
          'id': asset.id,
          'name': asset.name,
          'type': asset.type,
          'bank': asset.bank,
          'created_by': asset.createdBy,
          'created': asset.created?.toIso8601String(),
          'notes': asset.notes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  Future<List<Asset>> getAllAssets() async {
    final db = await database;
    final assetMaps = await db.query('assets');
    final assets = <Asset>[];

    for (var assetMap in assetMaps) {
      final updates = await getUpdatesByAssetId(assetMap['id'] as String);
      assets.add(Asset(
        id: assetMap['id'] as String,
        name: assetMap['name'] as String?,
        type: assetMap['type'] as String?,
        bank: assetMap['bank'] as String?,
        createdBy: assetMap['created_by'] as String?,
        created: assetMap['created'] != null
            ? DateTime.parse(assetMap['created'] as String)
            : null,
        notes: assetMap['notes'] as String?,
        updates: updates,
      ));
    }

    return assets;
  }

  Future<Asset?> getAssetById(String id) async {
    final db = await database;
    final assetMaps = await db.query('assets', where: 'id = ?', whereArgs: [id]);
    if (assetMaps.isEmpty) return null;

    final assetMap = assetMaps.first;
    final updates = await getUpdatesByAssetId(id);

    return Asset(
      id: assetMap['id'] as String,
      name: assetMap['name'] as String?,
      type: assetMap['type'] as String?,
      bank: assetMap['bank'] as String?,
      createdBy: assetMap['created_by'] as String?,
      created: assetMap['created'] != null
          ? DateTime.parse(assetMap['created'] as String)
          : null,
      notes: assetMap['notes'] as String?,
      updates: updates,
    );
  }

  Future<void> updateAsset(Asset asset) async {
    final db = await database;
    await db.update(
      'assets',
      {
        'name': asset.name,
        'type': asset.type,
        'bank': asset.bank,
        'created_by': asset.createdBy,
        'created': asset.created?.toIso8601String(),
        'notes': asset.notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  Future<void> deleteAsset(String id) async {
    final db = await database;
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  // UPDATE OPERATIONS
  Future<void> insertUpdate(Update update) async {
    final db = await database;
    await db.insert(
      'updates',
      {
        'id': update.id,
        'asset_id': update.assetId,
        'date': update.date.toIso8601String(),
        'value': update.value,
        'updated_by': update.updated_by,
        'updated_at': update.updated_at?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertUpdates(List<Update> updates) async {
    final db = await database;
    final batch = db.batch();
    for (var update in updates) {
      batch.insert(
        'updates',
        {
          'id': update.id,
          'asset_id': update.assetId,
          'date': update.date.toIso8601String(),
          'value': update.value,
          'updated_by': update.updated_by,
          'updated_at': update.updated_at?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  Future<List<Update>> getUpdatesByAssetId(String assetId) async {
    final db = await database;
    final updateMaps = await db.query(
      'updates',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'date ASC',
    );

    return updateMaps.map((map) => Update(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      value: map['value'] as int,
      assetId: map['asset_id'] as String,
      updated_by: map['updated_by'] as String?,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    )).toList();
  }

  Future<void> deleteUpdate(String id) async {
    final db = await database;
    await db.delete('updates', where: 'id = ?', whereArgs: [id]);
  }

  // SYNC QUEUE OPERATIONS
  Future<void> addToSyncQueue({
    required String id,
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert(
      'sync_queue',
      {
        'id': id,
        'operation': operation,
        'entity_type': entityType,
        'entity_id': entityId,
        'data': _jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncQueue() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markSyncQueueItemAsSynced(String id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeSyncQueueItem(String id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  String _jsonEncode(dynamic object) {
    return object.toString();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
