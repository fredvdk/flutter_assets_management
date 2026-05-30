import 'package:flutter/material.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
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
  final AssetRepository _repository = AssetRepository();
  late String _originalPrompt;
  String _result = '';
  bool _isLoading = false;
  bool _promptChanged = false;

  @override
  void initState() {
    super.initState();
    _originalPrompt = widget.asset.prompt ?? 'What insights can you provide about this asset?';
    _promptController.text = _originalPrompt;
    _promptController.addListener(_onPromptChanged);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _onPromptChanged() {
    final changed = _promptController.text != _originalPrompt;
    if (changed != _promptChanged) {
      setState(() {
        _promptChanged = changed;
      });
    }
  }

  Future<void> _savePrompt() async {
    final newPrompt = _promptController.text;
    setState(() {
      _originalPrompt = newPrompt;
      _promptChanged = false;
    });

    try {
      await _repository.updateAssetPrompt(widget.asset.id, newPrompt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving prompt: $e')),
      );
    }
  }

  Future<void> _askAI() async {
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
      final response = await _aiService.askAI(_promptController.text, useWebSearch: true);
      if (mounted) {
        setState(() {
          _result = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = 'Error: $e';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
              const SizedBox(height: 16),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _askAI,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ask AI'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _promptChanged ? _savePrompt : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: const Text('Save Prompt'),
                  ),
                ],
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
