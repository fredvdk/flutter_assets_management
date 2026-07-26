import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class AIService {
  static const String openaiUrl = 'https://api.openai.com/v1/chat/completions';

  String get _openaiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY not configured in .env file');
    }
    return key;
  } 
 

  Future<String> askAI(String prompt, {bool useWebSearch = true}) async {
    debugPrint('AIService: Starting request');

    try {
      final requestBody = {
        "model": "gpt-4.1-mini",
        "input": prompt,
        "temperature": 0.7,
      };

      if (useWebSearch) {
        requestBody["tools"] = [
          {"type": "web_search"},
        ];

        requestBody["tool_choice"] = "auto";
      }

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/responses"),
        headers: {
          "Authorization": "Bearer $_openaiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "OpenAI API Error: ${response.statusCode}\n${response.body}",
        );
      }

      final data = jsonDecode(response.body);

      // Extract text safely from Responses API structure
      final output = data["output"] as List<dynamic>;

      final text = output
          .expand((item) => item["content"] ?? [])
          .where((c) => c["type"] == "output_text")
          .map((c) => c["text"])
          .join("\n");

      return text;
    } catch (e) {
      debugPrint('AIService: Error: $e');
      throw Exception('Failed to get AI response: $e');
    }
  }
}
