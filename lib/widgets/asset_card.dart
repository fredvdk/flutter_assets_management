import 'package:flutter/material.dart';
import 'package:flutter_assets_management/database/updates_repository.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/models/update.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

final formatter = NumberFormat.decimalPattern('nl_BE');

class AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onUpdate;

  const AssetCard({super.key, required this.asset, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(asset.id),

      startActionPane: ActionPane(
        motion: const DrawerMotion(),

        children: [
          SlidableAction(
            onPressed: (_) => _updateValue(context),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.update,
            label: 'Update',
          ),

          SlidableAction(
            onPressed: (_) => _getHistory(context),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.history,
            label: 'History',
          ),
        ],
      ),

      endActionPane: ActionPane(
        motion: const DrawerMotion(),

        children: [
          SlidableAction(
            onPressed: (_) => _editAsset(context),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),

          SlidableAction(
            onPressed: (_) => _deleteAsset(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),

      child: Card(
        color: _getColor(),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              Text(
                '€ ${formatter.format(asset.getLastValue())} '
                '- ${asset.name ?? 'N/A'}',

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text('Bank: ${asset.bank ?? 'N/A'}'),

              if (asset.notes != null && asset.notes!.trim().isNotEmpty)
                Text('Notes: ${asset.notes}'),

              Text(
                'Updated by '
                '${asset.getLastUpdatedBy()} '
                'on '
                '${DateFormat('dd-MMM-yy HH:mm').format(asset.getLastUpdatedAt())}',

                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateValue(BuildContext context) async {
    final controller = TextEditingController();

    final newValue = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Update ${asset.name}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'New Value',
              prefixText: '€ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(
                  controller.text.replaceAll('.', ''),
                );

                Navigator.of(dialogContext).pop(parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newValue == null) return;

    // Update the asset value
    await UpdatesRepository().createUpdate(
      Update(
        id: '',
        assetId: asset.id,
        date: DateTime.now(),
        value: newValue,
        updated_by: 'Frederick',// Replace with actual user info
        updated_at: DateTime.now()
      ),
    );

    // Notify parent to rebuild
    onUpdate?.call();

  }

  void _getHistory(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Get history')));
  }

  void _editAsset(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit asset')));
  }

  Future<void> _deleteAsset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Asset'),
          content: Text('Are you sure you want to delete ${asset.name}?'),
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
      // delete logic here

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${asset.name} deleted')));
    }
  }

  Color? _getColor() {
    switch (asset.type?.toLowerCase()) {
      case 'beleggingen':
        return Colors.green[50];

      case 'cash':
        return Colors.blue[50];

      case 'vastgoed':
        return Colors.brown[50];

      default:
        return Colors.grey[50];
    }
  }
}
