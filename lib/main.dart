import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/widgets/asset_card.dart';
import 'package:flutter_assets_management/widgets/totals_card.dart';
import 'package:flutter_assets_management/services/sync_service.dart';
import 'package:flutter_assets_management/pages/newassetpage.dart';
import 'package:flutter_assets_management/config/version.dart';
import 'dart:io';

late SyncService _syncService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await dotenv.load();

  _syncService = SyncService();
  _syncService.startAutoSync();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Financial Assets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
      ),
      home: const MyHomePage(title: 'Financial Assets'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Asset> _assets = [];

  @override
  void initState() {
    super.initState();
    _fetchAssets().then((assets) {
      setState(() {
        _assets = assets;
      });
    });
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  Future<List<Asset>> _fetchAssets() async {
    try {
      return await AssetRepository().fetchAssets();
    } catch (error) {
      // Handle error, e.g. log it or show a snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load assets: $error')));
      return [];
    }
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
        ),
        body: Column(
          children: [
            TotalsCard(assets: _assets),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _assets.map(
                    (asset) => AssetCard(
                      asset: asset,
                      onUpdate: () {
                        // Refresh the asset list after an update
                        _fetchAssets().then((assets) {
                          setState(() {
                            _assets = assets;
                          });
                        });
                      },
                    ),
                  ).toList(),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NewAssetPage()),
            );
            if (result == true) {
              _fetchAssets().then((assets) {
                setState(() {
                  _assets = assets;
                });
              });
            }
          },
          tooltip: 'Add Asset',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
