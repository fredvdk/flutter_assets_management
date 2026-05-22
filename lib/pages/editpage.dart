import 'package:flutter/material.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
import 'package:flutter_assets_management/models/asset.dart';

class EditPage extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onUpdate;

  const EditPage({super.key, required this.asset, this.onUpdate});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late TextEditingController _nameController;
  late TextEditingController _bankController;
  late TextEditingController _notesController;
  late String _selectedType;
  bool _isSaving = false;
  bool _isDeleting = false;

  final List<String> _assetTypes = ['Beleggingen', 'Cash', 'Vastgoed'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset.name ?? '');
    _bankController = TextEditingController(text: widget.asset.bank ?? '');
    _notesController = TextEditingController(text: widget.asset.notes ?? '');
    _selectedType = widget.asset.type!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _notesController.dispose();
    super.dispose();
  }

   Future<void> _deleteAsset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Asset'),
          content: Text('Are you sure you want to delete ${widget.asset.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await AssetRepository().deleteAsset(widget.asset.id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${widget.asset.name} deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete asset: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveAsset() async {
    if (_nameController.text.isEmpty) {
      _showError('Asset name is required');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedAsset = Asset(
        id: widget.asset.id,
        name: _nameController.text,
        type: _selectedType,
        bank: _bankController.text.isEmpty ? null : _bankController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdBy: widget.asset.createdBy,
        created: widget.asset.created,
        updates: widget.asset.updates,
      );

      await AssetRepository().updateAsset(widget.asset.id, updatedAsset);

      if (mounted) {
        widget.onUpdate?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset updated successfully')),
        );
      }
    } catch (e) {
      _showError('Failed to update asset: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Edit ${widget.asset.name}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Asset Name',
                  hintText: 'Enter asset name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Asset Type',
                  border: OutlineInputBorder(),
                ),
                items: _assetTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bankController,
                decoration: const InputDecoration(
                  labelText: 'Bank (Optional)',
                  hintText: 'Enter bank name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Enter notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAsset,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 240, 189, 189),
                ),
                onPressed: () => _deleteAsset(context),
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete Asset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
