import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class AIService {
  static const String openaiUrl = 'https://api.openai.com/v1/chat/completions';
  static const Duration _timeout = Duration(seconds: 30);

  String get _openaiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY not configured in .env file');
    }
    return key;
  }

  Future<String> askAI(String prompt) async {
    debugPrint('AIService: Starting request');

    try {
      final response = await http.post(
        Uri.parse(openaiUrl),
        headers: {
          'Authorization': 'Bearer $_openaiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
        }),
      ).timeout(_timeout);

      debugPrint('AIService: Got response ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          'OpenAI API Error: ${response.statusCode}\n${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final result = data['choices'][0]['message']['content'];
      return result;
    } on SocketException catch (e) {
      debugPrint('AIService: Socket error: $e');
      throw Exception('Network error: $e. Check your internet connection.');
    } on TimeoutException catch (e) {
      debugPrint('AIService: Timeout: $e');
      throw Exception('Request timed out after ${_timeout.inSeconds}s');
    } catch (e) {
      debugPrint('AIService: Error: $e');
      throw Exception('Failed to get AI response: $e');
    }
  }
}
