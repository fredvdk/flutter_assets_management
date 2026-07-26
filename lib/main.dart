import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_assets_management/app.dart';
import 'package:flutter_assets_management/data/asset_local_data_source.dart';
import 'package:flutter_assets_management/data/http_asset_remote_data_source.dart';
import 'package:flutter_assets_management/data/http_update_remote_data_source.dart';
import 'package:flutter_assets_management/data/update_local_data_source.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';
import 'package:flutter_assets_management/database/updates_repository.dart';
import 'package:flutter_assets_management/services/connectivity_service.dart';
import 'package:flutter_assets_management/services/sync_service.dart';
import 'package:flutter_assets_management/services/user_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await dotenv.load();

  final userService = UserService();
  await userService.init();

  final connectivityService = ConnectivityService();
  final assetRepository = AssetRepository(
    localDataSource: SqliteAssetLocalDataSource(),
    remoteDataSource: HttpAssetRemoteDataSource(),
    connectivityService: connectivityService,
  );
  final updatesRepository = UpdatesRepository(
    localDataSource: SqliteUpdateLocalDataSource(),
    remoteDataSource: HttpUpdateRemoteDataSource(),
    connectivityService: connectivityService,
  );
  final syncService = SyncService(
    connectivityService: connectivityService,
  );
  syncService.startAutoSync();

  runApp(MyApp(
    userService: userService,
    syncService: syncService,
    connectivityService: connectivityService,
    assetRepository: assetRepository,
    updatesRepository: updatesRepository,
  ));
}

