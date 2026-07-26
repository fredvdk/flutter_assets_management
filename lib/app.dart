
import 'package:flutter/material.dart';
import 'package:flutter_assets_management/controllers/home_controller.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
import 'package:flutter_assets_management/database/updates_repository.dart';
import 'package:flutter_assets_management/pages/homepage.dart';
import 'package:flutter_assets_management/pages/loginpage.dart';
import 'package:flutter_assets_management/providers/assets_provider.dart';
import 'package:flutter_assets_management/providers/sync_status_provider.dart';
import 'package:flutter_assets_management/services/connectivity_service.dart';
import 'package:flutter_assets_management/services/sync_service.dart';
import 'package:flutter_assets_management/services/user_service.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  final UserService userService;
  final SyncService syncService;
  final ConnectivityService connectivityService;
  final AssetRepository assetRepository;
  final UpdatesRepository updatesRepository;

  const MyApp({
    super.key,
    required this.userService,
    required this.syncService,
    required this.connectivityService,
    required this.assetRepository,
    required this.updatesRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserService>.value(value: userService),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
        Provider<ConnectivityService>.value(value: connectivityService),
        Provider<AssetRepository>.value(value: assetRepository),
        Provider<UpdatesRepository>.value(value: updatesRepository),
        ChangeNotifierProvider(
          create: (context) => AssetsProvider(
            repository: context.read<AssetRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SyncStatusProvider(
            syncService: context.read<SyncService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeController(
            userService: context.read<UserService>(),
            assetsProvider: context.read<AssetsProvider>(),
          ),
        ),
      ],
      child: Consumer<UserService>(
        builder: (context, userService, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Financial Assets',
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
            ),
            home: userService.isLoggedIn()
                ? const MyHomePage(title: 'Financial Assets')
                : const LoginPage(),
          );
        },
      ),
    );
  }
}
