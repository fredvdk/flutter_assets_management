import 'package:flutter/material.dart';
import 'package:flutter_assets_management/controllers/home_controller.dart';
import 'package:flutter_assets_management/data/asset_local_data_source.dart';
import 'package:flutter_assets_management/data/http_asset_remote_data_source.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/models/update.dart';
import 'package:flutter_assets_management/pages/homepage.dart';
import 'package:flutter_assets_management/providers/assets_provider.dart';
import 'package:flutter_assets_management/providers/sync_status_provider.dart';
import 'package:flutter_assets_management/services/connectivity_service.dart';
import 'package:flutter_assets_management/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakeclasses.dart';


 class FakeAssetLocalDataSource implements AssetLocalDataSource {
  bool throwError;
  FakeAssetLocalDataSource({this.throwError = false});

  List<Asset> fakeAssets = [
    Asset(
      id: '1',
      name: 'Asset 1',
      type: null,
      bank: 'Bank 1',
      createdBy: 'User 1',
      created: DateTime.now(),
      notes: 'Notes for Asset 1',
      updates: [],
    ),
    Asset(
      id: '2',
      name: 'Asset 2',
      type: 'Type B',
      bank: 'Bank 2',
      createdBy: 'User 2',
      created: DateTime.now(),
      notes: 'Notes for Asset 2',
      updates: [],
    ),
    Asset(
      id: '3',
      name: 'Asset 3',
      type: 'Type A',
      bank: 'Bank 3',
      createdBy: 'User 3',
      created: DateTime.now(),
      notes: 'Notes for Asset 3',
      updates: [],
    ),
    Asset(
      id: '4',
      name: 'Asset 4',
      type: 'Type B',
      bank: 'Bank 4',
      createdBy: 'User 4',
      created: DateTime.now(),
      notes: 'Notes for Asset 4',
      updates: [],
    ),
  ];

  @override
  Future<void> addToSyncQueue({
    required String id,
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {}

  @override
  Future<void> deleteAsset(String id) {
    // TODO: implement deleteAsset
    throw UnimplementedError();
  }

  @override
  Future<List<Asset>> getAllAssets() {
    if (throwError) {
      throw Exception('Simulated error fetching assets');
    }
    return Future.value(List<Asset>.from(fakeAssets));
  }

  @override
  Future<void> insertUpdates(List<Update> updates) {
    // TODO: implement insertUpdates
    throw UnimplementedError();
  }

  @override
  Future<void> saveAsset(Asset asset) async {
    fakeAssets.add(asset);
  }

  @override
  Future<void> saveAssets(List<Asset> assets) {
    // TODO: implement saveAssets
    throw UnimplementedError();
  }

  @override
  Future<void> updateAsset(Asset asset) {
    // TODO: implement updateAsset
    throw UnimplementedError();
  }

  @override
  Future<void> updateAssetPrompt(String assetId, String prompt) {
    // TODO: implement updateAssetPrompt
    throw UnimplementedError();
  }
}


class FakeConnectivityService extends ConnectivityService {
  FakeConnectivityService() : super.withDependencies();

  @override
  Future<bool> get isServerAvailable async {
    return false; // Simulate server is always offline
  }
}

class FakeRemoteDataSource implements AssetRemoteDataSource {
  @override
  Future<Asset> createAsset(Asset asset) {
    // TODO: implement createAsset
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAsset(String id) {
    // TODO: implement deleteAsset
    throw UnimplementedError();
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  Future<List<Asset>> fetchAssets() {
    // TODO: implement fetchAssets
    throw UnimplementedError();
  }

  @override
  Future<Asset> updateAsset(String id, Asset asset) {
    // TODO: implement updateAsset
    throw UnimplementedError();
  }

  @override
  Future<void> updateAssetPrompt(String assetId, String prompt) {
    // TODO: implement updateAssetPrompt
    throw UnimplementedError();
  }
  
  }

void main() {
  
  testWidgets('MyHomePage displays grouped assets by type', (WidgetTester tester) async {
    AssetRepository assetRepository = AssetRepository(
      localDataSource: FakeAssetLocalDataSource(),
      remoteDataSource: FakeRemoteDataSource(),
      connectivityService: FakeConnectivityService(),
    );
    
    SharedPreferences.setMockInitialValues({
      'user_name': 'fred',
    }); // Mock SharedPreferences with some initial values
    UserService userService = UserService();
    await userService
        .init(); // Initialize the UserService to load the mock SharedPreferences

    HomeController homeController = HomeController(
      assetsProvider: AssetsProvider(repository: assetRepository),
      userService: userService,
    );

    FakeSyncService fakeSyncService = FakeSyncService();
    
    SyncStatusProvider syncStatusProvider = SyncStatusProvider(syncService: fakeSyncService);


    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeController>.value(value: homeController),
            ChangeNotifierProvider<SyncStatusProvider>.value(value: syncStatusProvider),          ],
          child: MyHomePage(title: 'Test Home Page'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    expect(find.text('Financial Assets'), findsOneWidget);
    expect(find.textContaining('Asset 1'), findsNWidgets(2)); // Asset 1 appears twice: once in the list and once in the totals card
    expect(find.textContaining('Asset 2'), findsNWidgets(2)); // Asset 2 appears twice: once in the list and once in the totals card
    expect(find.textContaining('Other'), findsOneWidget);
    expect(find.textContaining('Asset 3'), findsNWidgets(2)); // Asset 3 appears twice: once in the list and once in the totals card
    expect(find.textContaining('Asset 4'), findsNWidgets(2)); // Asset 4 appears twice: once in the list and once in the totals card
    expect(find.text('fred'), findsOneWidget); // Check if the username is displayed
  });
}
