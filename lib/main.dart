import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/widgets/asset_card.dart';
import 'package:flutter_assets_management/widgets/totals_card.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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

  Future<List<Asset>> _fetchAssets() async {
    try {
      return await AssetRepository().fetchAssets();
    } catch (error) {
      // Handle error, e.g. log it or show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load assets: $error')),
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TotalsCard(assets: _assets),
            ..._assets.map((asset) => AssetCard(asset: asset, onUpdate: () {
              // Refresh the asset list after an update
              _fetchAssets().then((assets) {
                setState(() {
                  _assets = assets;
                });
              });
            },)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fetchAssets().then((assets) {
            setState(() {
              _assets = assets;
            });
          });
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
