import 'package:flutter/material.dart';
import 'package:flutter_assets_management/database/updates_repository.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/models/update.dart';
import 'package:flutter_assets_management/pages/editpage.dart';
import 'package:flutter_assets_management/pages/updatespage.dart';
import 'package:flutter_assets_management/pages/aipage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:flutter_assets_management/services/user_service.dart';
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
        if (asset.type != 'Cash')
          SlidableAction(
            onPressed: (_) => _askAI(context),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.psychology,
            label: 'Ask AI',
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
    final userService = UserService();
    await userService.init();
    final currentUser = userService.getCurrentUser() ?? 'Unknown';

    if (!context.mounted) return;

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

    await UpdatesRepository().createUpdate(
      Update(
        id: '',
        assetId: asset.id,
        date: DateTime.now(),
        value: newValue,
        updatedBy: currentUser,
        updatedAt: DateTime.now()
      ),
    );

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

  void _askAI(BuildContext context) {
   // debugPrint('Asset: ${asset.toString()}');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AIPage(asset: asset)),
    );
  }
}
