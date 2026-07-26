import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_assets_management/controllers/home_controller.dart';
import 'package:flutter_assets_management/pages/newassetpage.dart';
import 'package:flutter_assets_management/providers/sync_status_provider.dart';
import 'package:flutter_assets_management/services/connectivity_service.dart';
import 'package:flutter_assets_management/widgets/asset_card.dart';
import 'package:flutter_assets_management/widgets/totals_card.dart';
import 'package:flutter_assets_management/config/version.dart';
import 'package:flutter_assets_management/providers/assets_provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssetsProvider>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Financial Assets',
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
              ),
              Text(
                'v$appVersion',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            Consumer<AssetsProvider>(
              builder: (context, controller, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      controller.currentUser,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            ),
            Consumer<AssetsProvider>(
              builder: (context, controller, _) {
                return PopupMenuButton(
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await controller.logout();
                    }
                  },
                  itemBuilder: (menuContext) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<AssetsProvider>(
          builder: (context, controller, _) {
            if (controller.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(controller.error!)),
              );
              controller.clearError();
            }

            return Column(
              children: [
                TotalsCard(assets: controller.assets),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: controller.groupedAssets.entries.map((entry) {
                        final type = entry.key;
                        final assets = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                type,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...assets.map(
                              (asset) => AssetCard(
                                asset: asset,
                                onUpdate: () {
                                  controller.refreshAssets();
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<AssetsProvider>(
          builder: (context, controller, _) {
            return FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NewAssetPage()),
                );
                if (result == true && mounted) {
                  await controller.refreshAssets();
                }
              },
              tooltip: 'Add Asset',
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}
