import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_assets_management/models/asset.dart';

final formatter = NumberFormat.decimalPattern('nl_BE');

class UpdatesPage extends StatelessWidget {
  final Asset asset;

  const UpdatesPage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
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
              itemCount: asset.updates.length,
              reverse: true,
              itemBuilder: (context, index) {
                final update = asset.updates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '€ ${formatter.format(update.value)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (index < asset.updates.length - 1)
                              _buildComparisonBadge(
                                update.value,
                                asset.updates[index + 1].value,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd-MMM-yy HH:mm').format(update.date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (update.updated_by != null)
                          Text(
                            'By ${update.updated_by}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildComparisonBadge(int currentValue, int previousValue) {
    if (currentValue > previousValue) {
      final difference = currentValue - previousValue;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.arrow_upward, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              '+€ ${formatter.format(difference)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (currentValue < previousValue) {
      final difference = previousValue - currentValue;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.arrow_downward, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              '-€ ${formatter.format(difference)}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.remove, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            const Text(
              'No change',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }
}
