import 'package:flutter/material.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/providers/assets_provider.dart';
import 'package:flutter_assets_management/services/user_service.dart';

class HomeController extends ChangeNotifier {
  final UserService userService;
  final AssetsProvider assetsProvider;

  HomeController({
    required this.userService,
    required this.assetsProvider,
  }) {
    assetsProvider.addListener(_onAssetsChanged);
  }

  void _onAssetsChanged() {
    notifyListeners();
  }

  String get currentUser => userService.getCurrentUser() ?? 'Unknown';
  List<Asset> get assets => assetsProvider.assets;
  String? get error => assetsProvider.error;
  bool get isLoading => assetsProvider.isLoading;

  Map<String, List<Asset>> get groupedAssets {
    final grouped = <String, List<Asset>>{};
    for (final asset in assetsProvider.assets) {
      final type = asset.type ?? 'Other';
      grouped.putIfAbsent(type, () => []).add(asset);
    }
    return grouped;
  }

  Future<void> initialize() async {
    await assetsProvider.fetchAssets();
    notifyListeners();
  }

  Future<void> refreshAssets() async {
    await assetsProvider.fetchAssets();
    notifyListeners();
  }

  Future<void> logout() async {
    await userService.logout();
  }

  void clearError() {
    assetsProvider.clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    assetsProvider.removeListener(_onAssetsChanged);
    super.dispose();
  }
}
