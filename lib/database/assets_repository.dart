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
  final UpdatesRepository _updatesRepo = UpdatesRepository();
  final _uuid = const Uuid();

  AssetRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Asset>> fetchAssets() async {
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
        
        // Flatten all updates to insert them in a single batch
        final allUpdates = assets.expand((asset) => asset.updates).toList();
        await _localDb.insertUpdates(allUpdates);
        
        return assets;
      } catch (e) {
        print('Error fetching from server, falling back to local: $e');
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
            id: _uuid.v4(),
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

        // Sync updates if any exist
        if (assetWithId.updates.isNotEmpty) {
          for (var update in assetWithId.updates) {
            await _updatesRepo.createUpdate(update);
          }
        }

        return createdAsset;
      } catch (e) {
        return _handleOfflineCreate(assetWithId);
      }
    } else {
      return _handleOfflineCreate(assetWithId);
    }
  }

  Future<Asset> _handleOfflineCreate(Asset asset) async {
    await _localDb.insertAsset(asset);
    await _localDb.addToSyncQueue(
      id: _uuid.v4(),
      operation: 'CREATE',
      entityType: 'asset',
      entityId: asset.id,
      data: asset.toJson(includeUpdates: false), // Updates are handled by their own repo sync
    );
    return asset;
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
        return _handleOfflineUpdate(id, asset);
      }
    } else {
      return _handleOfflineUpdate(id, asset);
    }
  }

  Future<Asset> _handleOfflineUpdate(String id, Asset asset) async {
    await _localDb.updateAsset(asset);
    await _localDb.addToSyncQueue(
      id: _uuid.v4(),
      operation: 'UPDATE',
      entityType: 'asset',
      entityId: id,
      data: asset.toJson(includeUpdates: false),
    );
    return asset;
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
        await _handleOfflineDelete(id);
      }
    } else {
      await _handleOfflineDelete(id);
    }
  }

  Future<void> _handleOfflineDelete(String id) async {
    await _localDb.deleteAsset(id);
    await _localDb.addToSyncQueue(
      id: _uuid.v4(),
      operation: 'DELETE',
      entityType: 'asset',
      entityId: id,
      data: {},
    );
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
