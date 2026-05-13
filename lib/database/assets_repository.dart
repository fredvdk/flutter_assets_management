import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/asset.dart';
import '../config/env.dart';

class AssetRepository {
  late final String _baseUrl = '${Env.baseUrl}/assets';

  final http.Client _client;

  AssetRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Asset>> fetchAssets() async {
    final response = await _client.get(Uri.parse('$_baseUrl?select=id,name,updates(id,asset_id,date,value,updated_by,updated_at),type,bank,created_by,created,notes'));
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    return (decoded as List).map((item) => Asset.fromJson(item)).toList();
  }

  Future<Asset> fetchAsset(int id) async {
    final response = await _client.get(Uri.parse('$_baseUrl/$id'));
    _ensureSuccess(response);
    return Asset.fromJson(jsonDecode(response.body));
  }

  Future<Asset> createAsset(Asset asset) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(asset.toJson()),
    );
    _ensureSuccess(response, acceptedStatuses: [200, 201]);
    return Asset.fromJson(jsonDecode(response.body));
  }

  Future<Asset> updateAsset(String id, Asset asset) async {
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
    return Asset.fromJson(json.first as Map<String, dynamic>);
  }

  Future<void> deleteAsset(int id) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/$id'));
    _ensureSuccess(response, acceptedStatuses: [200, 204]);
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
