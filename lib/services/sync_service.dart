import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/local_database.dart';
import '../services/connectivity_service.dart';
import '../config/env.dart';

class SyncService {
  final LocalDatabase _localDb = LocalDatabase();
  final ConnectivityService _connectivity = ConnectivityService();
  late final String _assetsBaseUrl = '${Env.baseUrl}/assets';
  late final String _updatesBaseUrl = '${Env.baseUrl}/updates';
  final http.Client _client;
  bool _isSyncing = false;

  SyncService({http.Client? client}) : _client = client ?? http.Client();

  void startAutoSync() {
    _connectivity.connectionStatusStream.listen((isConnected) {
      if (isConnected) {
        syncPendingOperations();
      }
    });
  }

  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingItems = await _localDb.getPendingSyncQueue();
      print('Syncing ${pendingItems.length} pending operations...');

      for (var item in pendingItems) {
        final success = await _syncItem(item);
        if (success) {
          await _localDb.removeSyncQueueItem(item['id'] as String);
        } else {
          // If a sync fails, we stop to maintain order (especially for CREATE then UPDATE)
          print('Sync failed for item ${item['id']}, stopping batch');
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _syncItem(Map<String, dynamic> item) async {
    try {
      final operation = item['operation'] as String;
      final entityType = item['entity_type'] as String;
      final entityId = item['entity_id'] as String;
      final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

      if (entityType == 'asset') {
        return await _syncAssetOperation(operation, entityId, data);
      } else if (entityType == 'update') {
        return await _syncUpdateOperation(operation, entityId, data);
      }

      return false;
    } catch (e) {
      print('Error syncing item: $e');
      return false;
    }
  }

  Future<bool> _syncAssetOperation(
    String operation,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (operation) {
        case 'CREATE':
          final response = await _client.post(
            Uri.parse(_assetsBaseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          );
          return response.statusCode == 200 || response.statusCode == 201;

        case 'UPDATE':
          final response = await _client.patch(
            Uri.parse('$_assetsBaseUrl?id=eq.$entityId'),
            headers: {
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: jsonEncode(data),
          );
          return response.statusCode == 200;

        case 'DELETE':
          final response = await _client.delete(
            Uri.parse('$_assetsBaseUrl?id=eq.$entityId'),
            headers: {'Prefer': 'return=minimal'},
          );
          return response.statusCode == 200 || response.statusCode == 204;

        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _syncUpdateOperation(
    String operation,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (operation) {
        case 'CREATE':
          final response = await _client.post(
            Uri.parse(_updatesBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: jsonEncode(data),
          );
          return response.statusCode == 200 || response.statusCode == 201;

        case 'DELETE':
          final response = await _client.delete(
            Uri.parse('$_updatesBaseUrl?id=eq.$entityId'),
            headers: {'Prefer': 'return=minimal'},
          );
          return response.statusCode == 200 || response.statusCode == 204;

        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  void dispose() => _client.close();
}
