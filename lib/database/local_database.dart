import 'dart:io';
import 'dart:convert';

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
    final path = join(databasePath, 'flutter_assets.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
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

    await db.execute('CREATE INDEX idx_updates_asset_id ON updates (asset_id)');

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
    
    await db.execute('CREATE INDEX idx_sync_queue_synced ON sync_queue (synced)');
  }

  // ASSET OPERATIONS
  
  // Using Update-then-Insert to avoid ConflictAlgorithm.replace 
  // which triggers DELETE (and thus cascades to updates)
  Future<void> insertAsset(Asset asset) async {
    final db = await database;
    final data = {
      'id': asset.id,
      'name': asset.name,
      'type': asset.type,
      'bank': asset.bank,
      'created_by': asset.createdBy,
      'created': asset.created?.toIso8601String(),
      'notes': asset.notes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final count = await db.update('assets', data, where: 'id = ?', whereArgs: [asset.id]);
    if (count == 0) {
      await db.insert('assets', data);
    }
  }

  Future<void> insertAssets(List<Asset> assets) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var asset in assets) {
        final data = {
          'id': asset.id,
          'name': asset.name,
          'type': asset.type,
          'bank': asset.bank,
          'created_by': asset.createdBy,
          'created': asset.created?.toIso8601String(),
          'notes': asset.notes,
        };
        final count = await txn.update('assets', data, where: 'id = ?', whereArgs: [asset.id]);
        if (count == 0) {
          await txn.insert('assets', data);
        }
      }
    });
  }

  Future<List<Asset>> getAllAssets() async {
    final db = await database;
    final assetMaps = await db.query('assets');
    
    final allUpdateMaps = await db.query('updates', orderBy: 'date ASC');
    final updatesByAssetId = <String, List<Update>>{};
    
    for (var map in allUpdateMaps) {
      final assetId = map['asset_id'] as String;
      final update = Update(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        value: map['value'] as int,
        assetId: assetId,
        updated_by: map['updated_by'] as String?,
        updated_at: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
      );
      updatesByAssetId.putIfAbsent(assetId, () => []).add(update);
    }

    return assetMaps.map((map) {
      final id = map['id'] as String;
      return Asset(
        id: id,
        name: map['name'] as String?,
        type: map['type'] as String?,
        bank: map['bank'] as String?,
        createdBy: map['created_by'] as String?,
        created: map['created'] != null ? DateTime.parse(map['created'] as String) : null,
        notes: map['notes'] as String?,
        updates: updatesByAssetId[id] ?? [],
      );
    }).toList();
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
    if (updates.isEmpty) return;
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
    await batch.commit(noResult: true);
  }

  Future<List<Update>> getUpdatesByAssetId(String assetId) async {
    final db = await database;
    final maps = await db.query('updates', where: 'asset_id = ?', whereArgs: [assetId], orderBy: 'date ASC');
    return maps.map((map) => Update.fromJson(map)).toList();
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
        'data': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', where: 'synced = 0', orderBy: 'created_at ASC');
  }

  Future<void> removeSyncQueueItem(String id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
