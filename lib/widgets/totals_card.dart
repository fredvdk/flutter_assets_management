import 'package:flutter/material.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:intl/intl.dart';

final formatter = NumberFormat.decimalPattern('nl_BE');

class TotalsCard extends StatelessWidget {

  final List<Asset> assets;
  final Map<String, int> totals;

  TotalsCard({super.key, required this.assets}) : totals = Asset.getTotalsPerType(assets);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8.0),
            ...totals.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key}:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '€${formatter.format(entry.value)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      ),
    );
  }
}