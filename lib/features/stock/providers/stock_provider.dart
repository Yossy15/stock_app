import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/stock.dart';
import '../data/stock_repository.dart';
import 'dart:async';

part 'stock_provider.g.dart';

enum StockSortMode {
  none,
  qtyAsc, // จำนวนน้อยไปมาก
}

enum ActivityType {
  create,
  update,
  delete,
  qtyChange,
}

class StockActivity {
  final String id;
  final String stockId;
  final String stockName;
  final ActivityType type;
  final int diff; // +5, -2
  final int finalQty;
  final double price; // Price at the time of activity
  final DateTime timestamp;

  StockActivity({
    required this.id,
    required this.stockId,
    required this.stockName,
    required this.type,
    required this.diff,
    required this.finalQty,
    required this.price,
    required this.timestamp,
  });

  factory StockActivity.fromJson(Map<String, dynamic> json) {
    ActivityType type;
    switch (json['type']) {
      case 'create': type = ActivityType.create; break;
      case 'update': type = ActivityType.update; break;
      case 'delete': type = ActivityType.delete; break;
      case 'qtyChange': type = ActivityType.qtyChange; break;
      default: type = ActivityType.update;
    }

    return StockActivity(
      id: json['timestamp'] ?? '',
      stockId: json['stockId'] ?? '',
      stockName: json['stockName'] ?? 'Unknown',
      type: type,
      diff: json['diff'] ?? 0,
      finalQty: json['finalQty'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

@riverpod
class StockSort extends _$StockSort {
  @override
  StockSortMode build() => StockSortMode.none;

  void setSortMode(StockSortMode mode) => state = mode;
}

@riverpod
class StockViewMode extends _$StockViewMode {
  @override
  bool build() => false; // false = List, true = Grid

  void toggle() => state = !state;
}

@riverpod
class StockSearchQuery extends _$StockSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

@riverpod
class StockTotalCount extends _$StockTotalCount {
  @override
  int build() => 0;

  void update(int count) => state = count;
}

@riverpod
FutureOr<List<StockActivity>> stockActivities(StockActivitiesRef ref) async {
  final repository = ref.watch(stockRepositoryProvider);
  final data = await repository.getActivities();
  return data.map((e) => StockActivity.fromJson(e)).toList();
}

@riverpod
FutureOr<List<Stock>> stockSummary(StockSummaryRef ref) async {
  final repository = ref.watch(stockRepositoryProvider);
  final result = await repository.getStocks(page: 1, limit: 1000);
  final total = result['pagination']['total'] ?? 0;
  ref.read(stockTotalCountProvider.notifier).update(total);
  return result['stocks'] as List<Stock>;
}

@riverpod
class StockList extends _$StockList {
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounceTimer;

  @override
  FutureOr<List<Stock>> build() async {
    _currentPage = 1;
    _hasMore = true;
    
    // Watch sort provider to trigger rebuild when sort changes
    ref.watch(stockSortProvider);
    
    return await _fetchStocks();
  }

  Future<List<Stock>> _fetchStocks() async {
    final repository = ref.read(stockRepositoryProvider);
    final searchQuery = ref.watch(stockSearchQueryProvider);
    final sortMode = ref.watch(stockSortProvider);
    
    String? sortBy;
    String? order;

    if (sortMode == StockSortMode.qtyAsc) {
      sortBy = 'qty';
      order = 'asc';
    }

    final result = await repository.getStocks(
      page: _currentPage,
      search: searchQuery,
      sortBy: sortBy,
      order: order,
    );

    final pagination = result['pagination'];
    _hasMore = pagination['page'] < pagination['totalPages'];
    ref.read(stockTotalCountProvider.notifier).update(pagination['total'] ?? 0);

    return result['stocks'] as List<Stock>;
  }

  void setSearch(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(stockSearchQueryProvider.notifier).setQuery(query);
    });
  }

  void clearSearch() {
    ref.read(stockSearchQueryProvider.notifier).clear();
  }

  Future<void> fetchMore() async {
    if (state.isLoading || !_hasMore) return;
    state = const AsyncValue<List<Stock>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard<List<Stock>>(() async {
      _currentPage++;
      final moreStocks = await _fetchStocks();
      final currentStocks = state.value ?? [];
      return [...currentStocks, ...moreStocks];
    });
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue<List<Stock>>.loading();
    state = await AsyncValue.guard<List<Stock>>(() async {
      return await _fetchStocks();
    });
    ref.invalidate(stockSummaryProvider);
    ref.invalidate(stockActivitiesProvider);
  }

  // Create
  Future<void> addStock(String name, int qty, double price) async {
    final repository = ref.read(stockRepositoryProvider);
    final previousState = state.value ?? [];

    final tempStock = Stock(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      qty: qty,
      price: price,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue<List<Stock>>.data([tempStock, ...previousState]);

    try {
      await repository.createStock(name, qty, price);
      await refresh();
    } catch (e) {
      state = AsyncValue<List<Stock>>.data(previousState);
      rethrow;
    }
  }

  // Update
  Future<void> updateStock(String id,
      {String? name, int? qty, double? price}) async {
    final repository = ref.read(stockRepositoryProvider);
    final previousState = state.value ?? [];

    state = AsyncValue<List<Stock>>.data(
      [
        for (final stock in previousState)
          if (stock.id == id)
            stock.copyWith(
              name: name ?? stock.name,
              qty: qty ?? stock.qty,
              price: price ?? stock.price,
              updatedAt: DateTime.now(),
            )
          else
            stock
      ],
    );

    try {
      await repository.updateStock(id, {
        if (name != null) 'name': name,
        if (qty != null) 'qty': qty,
        if (price != null) 'price': price,
      });

      ref.invalidate(stockSummaryProvider);
      ref.invalidate(stockActivitiesProvider);
    } catch (e) {
      state = AsyncValue<List<Stock>>.data(previousState);
      rethrow;
    }
  }

  Future<void> updateStockQty(String id, int newQty) async {
    final previousState = state.value ?? [];

    state = AsyncValue<List<Stock>>.data(
      [
        for (final stock in previousState)
          if (stock.id == id) stock.copyWith(qty: newQty) else stock
      ],
    );

    try {
      await ref.read(stockRepositoryProvider).updateStock(id, {'qty': newQty});
      ref.invalidate(stockSummaryProvider);
      ref.invalidate(stockActivitiesProvider);
    } catch (e) {
      state = AsyncValue<List<Stock>>.data(previousState);
      rethrow;
    }
  }

  Future<void> deleteStock(String id) async {
    final previousState = state.value ?? [];

    state = AsyncValue<List<Stock>>.data(
      [for (final stock in previousState) if (stock.id != id) stock],
    );

    try {
      await ref.read(stockRepositoryProvider).deleteStock(id);
      ref.read(stockTotalCountProvider.notifier).update(ref.read(stockTotalCountProvider) - 1);
      ref.invalidate(stockSummaryProvider);
      ref.invalidate(stockActivitiesProvider);
    } catch (e) {
      state = AsyncValue<List<Stock>>.data(previousState);
      rethrow;
    }
  }
}
