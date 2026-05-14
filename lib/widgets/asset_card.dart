import 'package:flutter/material.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
import 'package:flutter_assets_management/database/updates_repository.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/models/update.dart';
import 'package:flutter_assets_management/pages/editpage.dart';
import 'package:flutter_assets_management/pages/updatespage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'asset_styling.dart';

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
        color: getAssetCardColor(asset),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    '€ ${formatter.format(asset.getLastValue())} '
                    '- ${asset.name ?? 'N/A'}',

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(getAssetTypeIcon(asset), size: 28),
                const SizedBox(width: 8),
                Icon(getValueChangeIcon(asset), size: 24, color: getValueChangeColor(asset)),
              ],
              ),

              const SizedBox(height: 8),

              if(asset.bank != null && asset.bank!.trim().isNotEmpty)
                Text('Bank: ${asset.bank}'),

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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => UpdatesPage(asset: asset)));

  }

  void _editAsset(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditPage(
          asset: asset,
          onUpdate: onUpdate,
        ),
      ),
    );
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
      try {
        await AssetRepository().deleteAsset(asset.id);
        if (context.mounted) {
          onUpdate?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${asset.name} deleted')),
          );
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

}
