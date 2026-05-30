import 'package:flutter/material.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/widgets/update_card.dart';

class UpdatesPage extends StatelessWidget {
  final Asset asset;

  const UpdatesPage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final sortedUpdates = List.from(asset.updates)
        ..sort((a, b) => b.updated_at.compareTo(a.updated_at));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('${asset.name} - Updates'),
      ),
      body: asset.updates.isEmpty
          ? Center(
              child: Text(
                'No updates yet for ${asset.name}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: sortedUpdates.length,
              itemBuilder: (context, index) {
                final update = sortedUpdates[index];
                final previousValue = index < sortedUpdates.length - 1
                    ? sortedUpdates[index + 1].value
                    : null;
                return UpdateCard(
                  update: update,
                  previousValue: previousValue,
                );
              },
            ),
    );
  }
}
