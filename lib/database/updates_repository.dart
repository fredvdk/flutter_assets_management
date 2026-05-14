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

  // CREATE
  Future<Update> createUpdate(Update update) async {
    final isOnline = await _connectivity.isConnected;
    final updateId = const Uuid().v4();
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
          id: updateId,
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
        id: updateId,
        operation: 'CREATE',
        entityType: 'update',
        entityId: updateId,
        data: newUpdate.toJson(),
      );
      return newUpdate;
    }
  }

  // READ (Get all)
  Future<List<Update>> getAllUpdates() async {
    final isOnline = await _connectivity.isConnected;

    if (isOnline) {
      try {
        final response = await http.get(Uri.parse(baseUrl));

        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          final updates = data.map((json) => Update.fromJson(json)).toList();
          await _localDb.insertUpdates(updates);
          return updates;
        } else {
          return _localDb.getUpdatesByAssetId('');
        }
      } catch (e) {
        return [];
      }
    } else {
      return [];
    }
  }

  // READ (Get by ID)
  Future<Update> getUpdateById(String id) async {
    final isOnline = await _connectivity.isConnected;

    if (isOnline) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/$id'));

        if (response.statusCode == 200) {
          final update = Update.fromJson(jsonDecode(response.body));
          await _localDb.insertUpdate(update);
          return update;
        } else {
          throw Exception('Failed to load update: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error fetching update: $e');
      }
    } else {
      throw Exception('Offline: Cannot fetch update details');
    }
  }

  // DELETE
  Future<void> deleteUpdate(String id) async {
    final isOnline = await _connectivity.isConnected;

    if (isOnline) {
      try {
        final response = await http.delete(Uri.parse('$baseUrl/$id'));

        if (response.statusCode == 200 || response.statusCode == 204) {
          await _localDb.deleteUpdate(id);
        } else {
          throw Exception('Failed to delete update: ${response.statusCode}');
        }
      } catch (e) {
        await _localDb.deleteUpdate(id);
        await _localDb.addToSyncQueue(
          id: id,
          operation: 'DELETE',
          entityType: 'update',
          entityId: id,
          data: {},
        );
      }
    } else {
      await _localDb.deleteUpdate(id);
      await _localDb.addToSyncQueue(
        id: id,
        operation: 'DELETE',
        entityType: 'update',
        entityId: id,
        data: {},
      );
    }
  }
}
