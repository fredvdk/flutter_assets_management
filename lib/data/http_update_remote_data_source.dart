import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/update.dart';

abstract class UpdateRemoteDataSource {
  Future<Update> createUpdate(Update update);
  Future<void> deleteUpdate(String id);
  void dispose() {}
}

class HttpUpdateRemoteDataSource implements UpdateRemoteDataSource {
  final http.Client _client;
  late final String _baseUrl = '${Env.baseUrl}/updates';

  HttpUpdateRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<Update> createUpdate(Update update) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode(update.toJson()),
    );
    _ensureSuccess(response, acceptedStatuses: [200, 201]);
    final decoded = jsonDecode(response.body);
    final data = decoded is List ? decoded.first : decoded;
    return Update.fromJson(data);
  }

  @override
  Future<void> deleteUpdate(String id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl?id=eq.$id'),
      headers: {'Prefer': 'return=minimal'},
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
