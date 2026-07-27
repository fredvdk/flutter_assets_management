import 'package:flutter_assets_management/controllers/home_controller.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/providers/assets_provider.dart';
import 'package:flutter_assets_management/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/fakeclasses.dart';


void main() {
  test('HomeController groupedAssets returns assets grouped by type', () async {
    AssetRepository repository = AssetRepository(
      localDataSource: FakeAssetLocalDataSource(),
      remoteDataSource: FakeRemoteDataSource(),
      connectivityService: FakeConnectivityService(),
    );

    AssetsProvider assetsProvider = AssetsProvider(repository: repository);

    UserService userService = UserService();

    HomeController homeController = HomeController(
      userService: userService,
      assetsProvider: assetsProvider,
    );

    await homeController.initialize();

    Map<String, List<Asset>> groupedAssets = homeController.groupedAssets;

    expect(groupedAssets["Other"]!.first.name, 'Asset 1');
    expect(groupedAssets['Type A']!.first.name, 'Asset 3');
    expect(groupedAssets['Type B']!.first.name, 'Asset 2');
    expect(groupedAssets['Type B']!.map((asset) => asset.id), ['2', '4']);
    expect(groupedAssets.keys, ['Other', 'Type B', 'Type A']);
  });

  group('HomeController userService getCurrentUser', () {
    test('returns the current user when a user is logged in', () async {
      AssetsProvider assetsProvider = AssetsProvider();

      SharedPreferences.setMockInitialValues({
        'user_name': 'test_user',
      }); // Mock SharedPreferences with a logged-in user
      UserService userService = UserService();
      await userService
          .init(); // Initialize the UserService to load the mock SharedPreferences

      HomeController homeController = HomeController(
        userService: userService,
        assetsProvider: assetsProvider,
      );

      expect(homeController.currentUser, "test_user");
    });

    test(
      'HomeController userService getCurrentUser returns Unknown when no user is logged in',
      () async {
        AssetsProvider assetsProvider = AssetsProvider();

        SharedPreferences.setMockInitialValues({
          'some': 'some_value',
        }); // Mock SharedPreferences with some initial values
        UserService userService = UserService();
        await userService
            .init(); // Initialize the UserService to load the mock SharedPreferences

        HomeController homeController = HomeController(
          userService: userService,
          assetsProvider: assetsProvider,
        );

        expect(homeController.currentUser, "Unknown");
      },
    );
  });

  test('HomeController notifies listeners when change occurs in AssetsProvider and stops notifying after disposal', () async {

    AssetsProvider assetsProvider = AssetsProvider();

    UserService userService = UserService();

    HomeController homeController = HomeController(
      userService: userService,
      assetsProvider: assetsProvider,
    );

    bool notified = false;

    homeController.addListener(() {
      notified = true;
    });

    expect(notified, isFalse);
    assetsProvider.clearError();
    expect(notified, isTrue);

    notified = false;
    homeController.dispose();
    expect(notified, isFalse);
    expect(() => assetsProvider.clearError(), returnsNormally);
    expect(notified, isFalse);

  });

  test('HomeController clears error in AssetsProvider', () async {
     AssetRepository repository = AssetRepository(
        localDataSource: FakeAssetLocalDataSource(throwError: true),
        remoteDataSource: FakeRemoteDataSource(),
        connectivityService: FakeConnectivityService(),
      );

      AssetsProvider assetsProvider = AssetsProvider(repository: repository);

      UserService userService = UserService();

      HomeController homeController = HomeController(
        userService: userService,
        assetsProvider: assetsProvider,
      );

      await homeController.initialize(); //should throw an error and set the error property in assetsProvider

      expect(homeController.error, isNotNull);
      homeController.clearError();
      expect(homeController.error, isNull);
  
  });

  test('HomeController initialises and refreshAssets work correctly and loads assets and confirms isLoading/error settle correctly', () async {
    FakeAssetLocalDataSource fakeLocalDataSource = FakeAssetLocalDataSource(throwError: false);
    
    AssetRepository repository = AssetRepository(
      localDataSource: fakeLocalDataSource,
      remoteDataSource: FakeRemoteDataSource(),
      connectivityService: FakeConnectivityService(),
    );

    AssetsProvider assetsProvider = AssetsProvider(repository: repository);

    UserService userService = UserService();

    HomeController homeController = HomeController(
      userService: userService,
      assetsProvider: assetsProvider,
    );

    expect(homeController.isLoading, isFalse);
    expect(homeController.error, isNull);
    expect(homeController.assets, isEmpty);
    await homeController.initialize();
    expect(homeController.isLoading, isFalse);
    expect(homeController.error, isNull);
    expect(homeController.assets.length, equals(4));

    //print('after initialization: ${homeController.assets.length}');
    Asset newAsset = Asset(
      id: '5',
      name: 'Asset 5',
      type: 'Type C',
      bank: 'Bank 5',
      createdBy: 'User 5',
      created: DateTime.now(),
      notes: 'Notes for Asset 5',
      updates: [],
    );

    //print('before createAsset: ${homeController.assets.length}');
    //print('before createAsset: ${fakeLocalDataSource.fakeAssets.length}');
    
    await homeController.assetsProvider.createAsset(newAsset);
    await homeController.refreshAssets();
    expect(homeController.assets.length, equals(5));

    //print('after refreshAssets: ${homeController.assets.length}');
    //print('after refreshAssets: ${fakeLocalDataSource.fakeAssets.length}');
  });

}
