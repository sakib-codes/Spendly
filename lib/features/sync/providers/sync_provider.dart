import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/sync/services/sync_service.dart';

enum SyncStatus {
  synced,
  syncing,
  offline,
  error,
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final int pendingCount;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.synced,
    this.lastSyncTime,
    this.pendingCount = 0,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    int? pendingCount,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingCount: pendingCount ?? this.pendingCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  final SyncService _syncService = SyncService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  VoidCallback? _syncingListener;
  VoidCallback? _pendingListener;

  @override
  SyncState build() {
    _init();
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      if (_syncingListener != null) {
        SyncService.isSyncingNotifier.removeListener(_syncingListener!);
      }
      if (_pendingListener != null) {
        SyncService.pendingCountNotifier.removeListener(_pendingListener!);
      }
    });
    return const SyncState();
  }

  Future<void> _init() async {
    final lastTime = await _syncService.getLastSyncTime();
    final pending = await _syncService.refreshPendingCount();

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none);

    state = state.copyWith(
      lastSyncTime: lastTime,
      pendingCount: pending,
      status: isOffline
          ? SyncStatus.offline
          : (SyncService.isSyncingNotifier.value
              ? SyncStatus.syncing
              : (pending > 0 ? SyncStatus.synced : SyncStatus.synced)),
    );

    // Listen to SyncService.isSyncingNotifier
    _syncingListener = () {
      if (SyncService.isSyncingNotifier.value) {
        state = state.copyWith(status: SyncStatus.syncing);
      } else {
        _syncService.getLastSyncTime().then((time) {
          state = state.copyWith(
            status: state.status == SyncStatus.offline
                ? SyncStatus.offline
                : SyncStatus.synced,
            lastSyncTime: time,
          );
        });
      }
    };
    SyncService.isSyncingNotifier.addListener(_syncingListener!);

    // Listen to SyncService.pendingCountNotifier
    _pendingListener = () {
      state = state.copyWith(
        pendingCount: SyncService.pendingCountNotifier.value,
      );
    };
    SyncService.pendingCountNotifier.addListener(_pendingListener!);

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (isOffline) {
        state = state.copyWith(status: SyncStatus.offline);
      } else {
        if (state.status == SyncStatus.offline) {
          // Came back online: trigger auto-sync if pending items exist
          state = state.copyWith(status: SyncStatus.synced);
          if (state.pendingCount > 0) {
            syncNow();
          }
        }
      }
    });
  }

  Future<bool> syncNow() async {
    if (state.status == SyncStatus.syncing) return false;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      final pending = await _syncService.refreshPendingCount();
      state = state.copyWith(
        status: SyncStatus.offline,
        pendingCount: pending,
        errorMessage: 'Device is offline',
      );
      return false;
    }

    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);

    try {
      final success = await _syncService.syncAll();
      final lastTime = await _syncService.getLastSyncTime();
      final pending = await _syncService.refreshPendingCount();

      if (success) {
        state = state.copyWith(
          status: SyncStatus.synced,
          lastSyncTime: lastTime,
          pendingCount: pending,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          pendingCount: pending,
          errorMessage: 'Sync failed. Please try again.',
        );
        return false;
      }
    } catch (e) {
      final pending = await _syncService.refreshPendingCount();
      state = state.copyWith(
        status: SyncStatus.error,
        pendingCount: pending,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
