import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/asset.dart';

abstract class AssetRemoteDataSource {
  Future<List<Asset>> fetchAssets();
  Future<Asset> createAsset(Asset asset);
  Future<Asset> updateAsset(String id, Asset asset);
  Future<void> deleteAsset(String id);
  Future<void> updateAssetPrompt(String assetId, String prompt);
  void dispose() {}
}

class HttpAssetRemoteDataSource implements AssetRemoteDataSource {
  final http.Client _client;
  late final String _baseUrl = '${Env.baseUrl}/assets';

  HttpAssetRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<List<Asset>> fetchAssets() async {
    final response = await _client.get(
      Uri.parse(
        '$_baseUrl?select=id,name,updates(id,asset_id,date,value,updated_by,updated_at),type,bank,created_by,created_at,notes,prompt',
      ),
    );
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    return (decoded as List).map((item) => Asset.fromJson(item)).toList();
  }

  @override
  Future<Asset> createAsset(Asset asset) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode(asset.toJson(includeUpdates: false)),
    );
    _ensureSuccess(response, acceptedStatuses: [200, 201]);

    final List<dynamic> json = jsonDecode(response.body);
    return Asset.fromJson(json.first as Map<String, dynamic>);
  }

  @override
  Future<Asset> updateAsset(String id, Asset asset) async {
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
    return Asset.fromJson(json.first as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAsset(String id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl?id=eq.$id'),
      headers: {'Prefer': 'return=minimal'},
    );
    _ensureSuccess(response, acceptedStatuses: [200, 204]);
  }

  @override
  Future<void> updateAssetPrompt(String assetId, String prompt) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl?id=eq.$assetId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );
    _ensureSuccess(response, acceptedStatuses: [200, 204]);
  }

  @override
  void dispose() => _client.close();

  void _ensureSuccess(http.Response response, {List<int>? acceptedStatuses}) {
    acceptedStatuses ??= [200];
    if (!acceptedStatuses.contains(response.statusCode)) {
      throw http.ClientException(
        'Request failed: ${response.statusCode} ${response.reasonPhrase}',
        Uri.parse(_baseUrl),
      );
    }
  }
}
