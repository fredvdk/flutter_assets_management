import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/asset.dart';
import '../config/env.dart';
import 'local_database.dart';
import '../services/connectivity_service.dart';
import 'updates_repository.dart';

class AssetRepository {
  late final String _baseUrl = '${Env.baseUrl}/assets';

  final http.Client _client;
  final LocalDatabase _localDb = LocalDatabase();
  final ConnectivityService _connectivity = ConnectivityService();

  AssetRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Asset>> fetchAssets() async {
    final isOnline = await _connectivity.isConnected;

    if (isOnline) {
      try {
        final response = await _client.get(
          Uri.parse(
            '$_baseUrl?select=id,name,updates(id,asset_id,date,value,updated_by,updated_at),type,bank,created_by,created,notes',
          ),
        );
        _ensureSuccess(response);
        final decoded = jsonDecode(response.body);
        final assets = (decoded as List)
            .map((item) => Asset.fromJson(item))
            .toList();

        // Cache the fetched assets locally    
        await _localDb.insertAssets(assets);
        await Future.wait(
          assets.map((asset) => _localDb.insertUpdates(asset.updates)),
        );
        return assets;
      } catch (e) {
        return _localDb.getAllAssets();
      }
    } else {
      return _localDb.getAllAssets();
    }
  }

  Future<Asset> fetchAsset(int id) async {
    final isOnline = await _connectivity.isConnected;

    if (isOnline) {
      try {
        final response = await _client.get(Uri.parse('$_baseUrl/$id'));
        _ensureSuccess(response);
        final asset = Asset.fromJson(jsonDecode(response.body));
        await _localDb.insertAsset(asset);
        return asset;
      } catch (e) {
        final cached = await _localDb.getAssetById(id.toString());
        if (cached != null) return cached;
        rethrow;
      }
    } else {
      final cached = await _localDb.getAssetById(id.toString());
      if (cached != null) return cached;
      throw Exception('Offline: Asset not available locally');
    }
  }

  Future<Asset> createAsset(Asset asset) async {
    final isOnline = await _connectivity.isConnected;

    if (isOnline) {
      try {
        final response = await _client.post(
          Uri.parse(_baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(asset.toJson(includeUpdates: false)),
        );
        _ensureSuccess(response, acceptedStatuses: [200, 201]);
        final createdAsset = Asset.fromJson(jsonDecode(response.body));
        await _localDb.insertAsset(createdAsset);

        if (asset.updates.isNotEmpty) {
          final updatesRepository = UpdatesRepository();
          for (var update in asset.updates) {
            await updatesRepository.createUpdate(update);
          }
        }

        return createdAsset;
      } catch (e) {
        await _localDb.insertAsset(asset);
        await _localDb.addToSyncQueue(
          id: asset.id,
          operation: 'CREATE',
          entityType: 'asset',
          entityId: asset.id,
          data: asset.toJson(),
        );
        return asset;
      }
    } else {
      await _localDb.insertAsset(asset);
      await _localDb.addToSyncQueue(
        id: asset.id,
        operation: 'CREATE',
        entityType: 'asset',
        entityId: asset.id,
        data: asset.toJson(),
      );
      return asset;
    }
  }

  Future<Asset> updateAsset(String id, Asset asset) async {
    final isOnline = await _connectivity.isConnected;

    if (isOnline) {
      try {
        final response = await _client.patch(
          Uri.parse('$_baseUrl?id=eq.$id'),
          headers: {
            'Content-Type': 'application/json',
            'Prefer': 'return=representation',
          },
          body: jsonEncode(asset.toJson()),
        );
        _ensureSuccess(response);
        final List<dynamic> json = jsonDecode(response.body);
        final updatedAsset = Asset.fromJson(json.first as Map<String, dynamic>);
        await _localDb.updateAsset(updatedAsset);
        return updatedAsset;
      } catch (e) {
        await _localDb.updateAsset(asset);
        await _localDb.addToSyncQueue(
          id: id,
          operation: 'UPDATE',
          entityType: 'asset',
          entityId: id,
          data: asset.toJson(),
        );
        return asset;
      }
    } else {
      await _localDb.updateAsset(asset);
      await _localDb.addToSyncQueue(
        id: id,
        operation: 'UPDATE',
        entityType: 'asset',
        entityId: id,
        data: asset.toJson(),
      );
      return asset;
    }
  }

  Future<void> deleteAsset(int id) async {
    final isOnline = await _connectivity.isConnected;
    final idStr = id.toString();

    if (isOnline) {
      try {
        final response = await _client.delete(Uri.parse('$_baseUrl/$id'));
        _ensureSuccess(response, acceptedStatuses: [200, 204]);
        await _localDb.deleteAsset(idStr);
      } catch (e) {
        await _localDb.deleteAsset(idStr);
        await _localDb.addToSyncQueue(
          id: idStr,
          operation: 'DELETE',
          entityType: 'asset',
          entityId: idStr,
          data: {},
        );
      }
    } else {
      await _localDb.deleteAsset(idStr);
      await _localDb.addToSyncQueue(
        id: idStr,
        operation: 'DELETE',
        entityType: 'asset',
        entityId: idStr,
        data: {},
      );
    }
  }

  void _ensureSuccess(http.Response response, {List<int>? acceptedStatuses}) {
    acceptedStatuses ??= [200];
    if (!acceptedStatuses.contains(response.statusCode)) {
      throw http.ClientException(
        'Request failed: ${response.statusCode} ${response.reasonPhrase}',
        Uri.parse(_baseUrl),
      );
    }
  }

  void dispose() => _client.close();
}
