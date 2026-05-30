import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_assets_management/widgets/asset_card.dart';
import 'package:flutter_assets_management/widgets/totals_card.dart';
import 'package:flutter_assets_management/services/user_service.dart';
import 'package:flutter_assets_management/pages/newassetpage.dart';
import 'package:flutter_assets_management/config/version.dart';
import 'package:flutter_assets_management/providers/assets_provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _currentUser = '';

  @override
  void initState() {
    super.initState();
    final userService = context.read<UserService>();
    _currentUser = userService.getCurrentUser() ?? 'Unknown';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssetsProvider>().fetchAssets();
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _currentUser,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            PopupMenuButton(
              onSelected: (value) async {
                if (value == 'logout') {
                  final userService = context.read<UserService>();
                  await userService.logout();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                    );
                  }
                }
              },
              itemBuilder: (menuContext) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
            ),
          ],
        ),
        body: Consumer<AssetsProvider>(
          builder: (context, assetsProvider, _) {
            if (assetsProvider.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(assetsProvider.error!)),
              );
              assetsProvider.clearError();
            }

            final groupedAssets = <String, List>{};
            for (final asset in assetsProvider.assets) {
              final type = asset.type ?? 'Other';
              groupedAssets.putIfAbsent(type, () => []).add(asset);
            }

            return Column(
              children: [
                TotalsCard(assets: assetsProvider.assets),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: groupedAssets.entries.map((entry) {
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
                                  assetsProvider.fetchAssets();
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
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final assetsProvider = context.read<AssetsProvider>();
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NewAssetPage()),
            );
            if (result == true && mounted) {
              assetsProvider.fetchAssets();
            }
          },
          tooltip: 'Add Asset',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
