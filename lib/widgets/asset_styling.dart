import 'package:flutter/material.dart';
import 'package:flutter_assets_management/models/asset.dart';

Color? getAssetCardColor(Asset asset) {
  switch (asset.type?.toLowerCase()) {
    case 'beleggingen':
      return Colors.green[100];

    case 'cash':
      return Colors.blue[100];

    case 'vastgoed':
      return Colors.orange[100];

    default:
      return Colors.grey[100];
  }
}

IconData getAssetTypeIcon(Asset asset) {
  switch (asset.type?.toLowerCase()) {
    case 'beleggingen':
      return Icons.trending_up;

    case 'cash':
      return Icons.money;

    case 'vastgoed':
      return Icons.home;

    default:
      return Icons.help_outline;
  }
}

IconData getValueChangeIcon(Asset asset) {
  if (asset.updates.length < 2) {
    return Icons.remove;
  }

  final sortedUpdates = List.from(asset.updates)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  final lastValue = sortedUpdates.first.value;
  final previousValue = sortedUpdates[1].value;

  if (lastValue > previousValue) {
    return Icons.arrow_upward;
  } else if (lastValue < previousValue) {
    return Icons.arrow_downward;
  } else {
    return Icons.remove;
  }
}

Color getValueChangeColor(Asset asset) {
  if (asset.updates.length < 2) {
    return Colors.grey;
  }

  final sortedUpdates = List.from(asset.updates)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  final lastValue = sortedUpdates.first.value;
  final previousValue = sortedUpdates[1].value;

  if (lastValue > previousValue) {
    return Colors.green;
  } else if (lastValue < previousValue) {
    return Colors.red;
  } else {
    return Colors.grey;
  }
}
