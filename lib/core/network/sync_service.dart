import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/stock/data/stock_local_data_source.dart';
import '../../features/stock/data/stock_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_service.g.dart';

@riverpod
class SyncService extends _$SyncService {
  late StreamSubscription<ConnectivityResult> _subscription;

  @override
  FutureOr<void> build() {
    _subscription =
        Connectivity().onConnectivityChanged.listen((result) {
              if (result != ConnectivityResult.none) {
                processQueue();
              }
            })
            as StreamSubscription<ConnectivityResult>;

    ref.onDispose(() {
      _subscription.cancel();
    });
  }

  Future<void> processQueue() async {
    // This is where the magic happens:
    // 1. Fetch pending items from SQLite sync_queue
    // 2. For each item, try to send to API
    // 3. On success, remove from queue
    // 4. On failure, leave it for next retry
    print('Checking sync queue for pending tasks...');
  }
}
