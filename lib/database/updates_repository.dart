import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/update.dart';
import '../config/env.dart';
import 'local_database.dart';
import '../services/connectivity_service.dart';

class UpdatesRepository {
  late final String baseUrl = '${Env.baseUrl}/updates';
  final LocalDatabase _localDb = LocalDatabase();
  final ConnectivityService _connectivity = ConnectivityService();
  final _uuid = const Uuid();

  // CREATE
  Future<Update> createUpdate(Update update) async {
    final isOnline = await _connectivity.isServerAvailable;
    final updateId = update.id.isEmpty ? _uuid.v4() : update.id;
    final newUpdate = Update(
      id: updateId,
      date: update.date,
      value: update.value,
      assetId: update.assetId,
      updated_by: update.updated_by,
      updated_at: update.updated_at,
    );

    if (isOnline) {
      try {
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
            },
          body: jsonEncode(newUpdate.toJson()),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final data = decoded is List ? decoded.first : decoded;
          final createdUpdate = Update.fromJson(data);
          await _localDb.insertUpdate(createdUpdate);
          return createdUpdate;
        } else {
          throw Exception('Failed to create update: ${response.statusCode}');
        }
      } catch (e) {
        await _localDb.insertUpdate(newUpdate);
        await _localDb.addToSyncQueue(
          id: _uuid.v4(),
          operation: 'CREATE',
          entityType: 'update',
          entityId: updateId,
          data: newUpdate.toJson(),
        );
        return newUpdate;
      }
    } else {
      await _localDb.insertUpdate(newUpdate);
      await _localDb.addToSyncQueue(
        id: _uuid.v4(),
        operation: 'CREATE',
        entityType: 'update',
        entityId: updateId,
        data: newUpdate.toJson(),
      );
      return newUpdate;
    }
  }

  // READ (Get all updates for an asset)
  Future<List<Update>> getUpdatesForAsset(String assetId) async {
    // Local database is the primary source for specific asset updates to ensure offline support
    return await _localDb.getUpdatesByAssetId(assetId);
  }

  // DELETE
  Future<void> deleteUpdate(String id) async {
    final isOnline = await _connectivity.isServerAvailable;

    if (isOnline) {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl?id=eq.$id'),
          headers: {'Prefer': 'return=minimal'},
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          await _localDb.deleteUpdate(id);
        } else {
          throw Exception('Failed to delete update: ${response.statusCode}');
        }
      } catch (e) {
        await _localDb.deleteUpdate(id);
        await _localDb.addToSyncQueue(
          id: _uuid.v4(),
          operation: 'DELETE',
          entityType: 'update',
          entityId: id,
          data: {},
        );
      }
    } else {
      await _localDb.deleteUpdate(id);
      await _localDb.addToSyncQueue(
        id: _uuid.v4(),
        operation: 'DELETE',
        entityType: 'update',
        entityId: id,
        data: {},
      );
    }
  }
}
