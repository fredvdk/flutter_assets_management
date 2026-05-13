import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/update.dart';

class UpdatesRepository {
  final String baseUrl = 'http://server:3000/updates';

  // CREATE
  Future<Update> createUpdate(Update update) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
          },
        body: jsonEncode(update.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is List ? decoded.first : decoded;
        return Update.fromJson(data);
      } else {
        throw Exception('Failed to create update: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating update: $e');
    }
  }

  // READ (Get all)
  Future<List<Update>> getAllUpdates() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Update.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load updates: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching updates: $e');
    }
  }

  // READ (Get by ID)
  Future<Update> getUpdateById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        return Update.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load update: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching update: $e');
    }
  }

  // DELETE
  Future<void> deleteUpdate(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete update: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting update: $e');
    }
  }
}
