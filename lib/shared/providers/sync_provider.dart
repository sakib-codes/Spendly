import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/sync/services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

class SyncManager {
  final SyncService _syncService;
  StreamSubscription? _connectivitySubscription;

  SyncManager(this._syncService) {
    _init();
  }

  void _init() {
    // Run sync on startup
    _syncService.syncAll();

    // Listen to network changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        // Network restored, try syncing
        _syncService.syncAll();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

final syncManagerProvider = Provider<SyncManager>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final manager = SyncManager(syncService);
  
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});
