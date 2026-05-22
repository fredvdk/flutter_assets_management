import 'package:flutter/material.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/services/ai_service.dart';

class AIPage extends StatefulWidget {
  final Asset asset;
  const AIPage({super.key, required this.asset});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final AIService _aiService = AIService();
  final TextEditingController _promptController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.asset.prompt != null) {
      //_askAI();
      _promptController.text = widget.asset.prompt!;
    }
    else {
      _promptController.text = 'What insights can you provide about this asset?';
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _askAI() async {
    debugPrint('Prompt: ${_promptController.text}');
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final response = await _aiService.askAI(_promptController.text);
      setState(() {
        _result = response;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Ask AI'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _promptController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Enter your prompt',
                  hintText: 'Ask me anything...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _askAI,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ask AI'),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: _result.isEmpty
                    ? const Text(
                        'Results will appear here',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Text(_result),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
