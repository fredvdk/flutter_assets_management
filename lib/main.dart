import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:flutter_assets_management/services/sync_service.dart';
import 'package:flutter_assets_management/services/user_service.dart';
import 'package:flutter_assets_management/providers/assets_provider.dart';
import 'package:flutter_assets_management/pages/loginpage.dart';
import 'package:flutter_assets_management/pages/homepage.dart';
import 'dart:io';

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

class MyApp extends StatelessWidget {
  final UserService userService;
  final SyncService syncService;

  const MyApp({
    super.key,
    required this.userService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UserService>.value(value: userService),
        ChangeNotifierProvider(create: (_) => AssetsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Financial Assets',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
        ),
        home: userService.isLoggedIn()
            ? const MyHomePage(title: 'Financial Assets')
            : LoginPage(
                onLoginSuccess: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                },
              ),
        routes: {
          '/home': (_) => const MyHomePage(title: 'Financial Assets'),
        },
      ),
    );
  }
}
