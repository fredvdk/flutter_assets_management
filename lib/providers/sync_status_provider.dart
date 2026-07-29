import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class SyncStatusProvider extends ChangeNotifier {
  final SyncService _syncService;

  SyncStatusProvider({required SyncService syncService})
      : _syncService = syncService {
    _syncService.addListener(_handleSyncChanged);
    unawaited(_syncService.refreshPendingOperationsCount());
  }

  bool get isSyncing => _syncService.isSyncing;
  ConnectionStatus get connectionStatus => _syncService.connectionStatus;
  int get pendingOperations => _syncService.pendingOperationsCount;
  DateTime? get lastSyncTime => _syncService.lastSyncCompletedAt;

  String get statusLabel {
    if (isSyncing) {
      return 'Syncing…';
    }
    if (connectionStatus == ConnectionStatus.offline) {
      return 'Offline';
    }
    if (connectionStatus == ConnectionStatus.noServer) {
      return 'No server';
    }
    if (pendingOperations > 0) {
      return 'Pending sync ($pendingOperations)';
    }
    return 'Up to date';
  }

  void _handleSyncChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _syncService.removeListener(_handleSyncChanged);
    super.dispose();
  }
}
