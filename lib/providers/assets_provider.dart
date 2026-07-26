import 'package:flutter/material.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/database/assets_repository.dart';

class AssetsProvider extends ChangeNotifier {
  final AssetRepository _repository;

  AssetsProvider({AssetRepository? repository})
      : _repository = repository ?? AssetRepository();

  List<Asset> _assets = [];
  String? _error;
  bool _isLoading = false;

  List<Asset> get assets => _assets;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> fetchAssets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assets = await _repository.fetchAssets();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch assets: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Asset> createAsset(Asset asset) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdAsset = await _repository.createAsset(asset);
      _assets.add(createdAsset);
      _isLoading = false;
      notifyListeners();
      return createdAsset;
    } catch (e) {
      _error = 'Failed to create asset: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Asset> updateAsset(String id, Asset asset) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAsset = await _repository.updateAsset(id, asset);
      final index = _assets.indexWhere((a) => a.id == id);
      if (index != -1) {
        _assets[index] = updatedAsset;
      }
      _isLoading = false;
      notifyListeners();
      return updatedAsset;
    } catch (e) {
      _error = 'Failed to update asset: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAssetPrompt(String assetId, String prompt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateAssetPrompt(assetId, prompt);
      final index = _assets.indexWhere((a) => a.id == assetId);
      if (index != -1) {
        final asset = _assets[index];
        final updatedAsset = Asset(
          id: asset.id,
          name: asset.name,
          type: asset.type,
          bank: asset.bank,
          createdBy: asset.createdBy,
          created: asset.created,
          notes: asset.notes,
          prompt: prompt,
          updates: asset.updates,
        );
        _assets[index] = updatedAsset;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update asset prompt: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAsset(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteAsset(id);
      _assets.removeWhere((asset) => asset.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete asset: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
