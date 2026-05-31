import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_assets_management/services/sync_service.dart';
import 'package:flutter_assets_management/services/user_service.dart';
import 'dart:io';
import 'package:flutter_assets_management/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await dotenv.load();

  final userService = UserService();
  await userService.init();

  final syncService = SyncService();
  syncService.startAutoSync();

  runApp(MyApp(
    userService: userService,
    syncService: syncService,
  ));
}

