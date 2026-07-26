import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../database/local_database.dart';
import '../services/connectivity_service.dart';

class SyncService extends ChangeNotifier {
  final LocalDatabase _localDb;
  final ConnectivityService _connectivity;
  late final String _assetsBaseUrl = '${Env.baseUrl}/assets';
  late final String _updatesBaseUrl = '${Env.baseUrl}/updates';
  final http.Client _client;
  bool _isSyncing = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.offline;
  int _pendingOperationsCount = 0;
  DateTime? _lastSyncCompletedAt;

  SyncService({
    LocalDatabase? localDatabase,
    ConnectivityService? connectivityService,
    http.Client? client,
  })  : _localDb = localDatabase ?? LocalDatabase(),
        _connectivity = connectivityService ?? ConnectivityService(),
        _client = client ?? http.Client();

  bool get isSyncing => _isSyncing;
  ConnectionStatus get connectionStatus => _connectionStatus;
  int get pendingOperationsCount => _pendingOperationsCount;
  DateTime? get lastSyncCompletedAt => _lastSyncCompletedAt;

  void startAutoSync() {
    _connectivity.connectionStatusStream.listen((status) {
      _connectionStatus = status;
      if (status == ConnectionStatus.online) {
        unawaited(syncPendingOperations());
      }
      notifyListeners();
    });

    unawaited(refreshPendingOperationsCount());
  }

  Future<void> refreshPendingOperationsCount() async {
    _pendingOperationsCount = (await _localDb.getPendingSyncQueue()).length;
    notifyListeners();
  }

  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final pendingItems = await _localDb.getPendingSyncQueue();
      _pendingOperationsCount = pendingItems.length;
      notifyListeners();
      debugPrint('Syncing ${pendingItems.length} pending operations...');

      for (final item in pendingItems) {
        final success = await _syncItem(item);
        if (success) {
          await _localDb.removeSyncQueueItem(item['id'] as String);
        } else {
          debugPrint('Sync failed for item ${item['id']}, stopping batch');
          break;
        }
      }
    } finally {
      _isSyncing = false;
      _lastSyncCompletedAt = DateTime.now();
      await refreshPendingOperationsCount();
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
      debugPrint('Error syncing item: $e');
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

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
