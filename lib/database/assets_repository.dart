import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
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

  Future<List<Asset>> fetchAssets() async {;

    if (await _connectivity.isServerAvailable) {
      print('Server available, fetching assets from server');
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
      print('Server not available, loading assets from local cache');
      return _localDb.getAllAssets();
    }
  }


  Future<Asset> createAsset(Asset asset) async {
    final isServerAvailable = await _connectivity.isServerAvailable;
    final assetWithId = asset.id.isEmpty
        ? Asset(
            id: const Uuid().v4(),
            name: asset.name,
            type: asset.type,
            bank: asset.bank,
            createdBy: asset.createdBy,
            created: asset.created,
            notes: asset.notes,
            updates: asset.updates,
          )
        : asset;

    if (isServerAvailable) {
      try {
        final response = await _client.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
            },
          body: jsonEncode(assetWithId.toJson(includeUpdates: false)),
        );
        _ensureSuccess(response, acceptedStatuses: [200, 201]);
        final List<dynamic> json = jsonDecode(response.body);
        final createdAsset = Asset.fromJson(json.first as Map<String, dynamic>);
        await _localDb.insertAsset(createdAsset);

        if (assetWithId.updates.isNotEmpty) {
          final updatesRepository = UpdatesRepository();
          for (var update in assetWithId.updates) {
            await updatesRepository.createUpdate(update);
          }
        }

        return createdAsset;
      } catch (e) {
        await _localDb.insertAsset(assetWithId);
        await _localDb.addToSyncQueue(
          id: assetWithId.id,
          operation: 'CREATE',
          entityType: 'asset',
          entityId: assetWithId.id,
          data: assetWithId.toJson(),
        );
        return assetWithId;
      }
    } else {
      await _localDb.insertAsset(assetWithId);
      await _localDb.addToSyncQueue(
        id: assetWithId.id,
        operation: 'CREATE',
        entityType: 'asset',
        entityId: assetWithId.id,
        data: assetWithId.toJson(),
      );
      return assetWithId;
    }
  }

  Future<Asset> updateAsset(String id, Asset asset) async {
    final isServerAvailable = await _connectivity.isServerAvailable;

    if (isServerAvailable) {
      try {
        final response = await _client.patch(
          Uri.parse('$_baseUrl?id=eq.$id'),
          headers: {
            'Content-Type': 'application/json',
            'Prefer': 'return=representation',
          },
          body: jsonEncode(asset.toJson(includeUpdates: false)),
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

  Future<void> deleteAsset(String id) async {
    final isServerAvailable = await _connectivity.isServerAvailable;

    if (isServerAvailable) {
      try {
        final uri = Uri.parse('$_baseUrl?id=eq.$id');
        final response = await _client.delete(
          uri,
          headers: {'Prefer': 'return=minimal'},
        );
        _ensureSuccess(response, acceptedStatuses: [200, 204]);
        await _localDb.deleteAsset(id);
      } catch (e) {
        await _localDb.addToSyncQueue(
          id: id,
          operation: 'DELETE',
          entityType: 'asset',
          entityId: id,
          data: {},
        );
        rethrow;
      }
    } else {
      await _localDb.addToSyncQueue(
        id: id,
        operation: 'DELETE',
        entityType: 'asset',
        entityId: id,
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
