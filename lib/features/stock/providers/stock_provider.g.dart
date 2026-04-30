// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stockActivitiesHash() => r'0a54b27207741748863984749047b2d5a0e4eeca';

/// See also [stockActivities].
@ProviderFor(stockActivities)
final stockActivitiesProvider =
    AutoDisposeFutureProvider<List<StockActivity>>.internal(
      stockActivities,
      name: r'stockActivitiesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockActivitiesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StockActivitiesRef = AutoDisposeFutureProviderRef<List<StockActivity>>;
String _$stockSummaryHash() => r'92bbad04eeeef20d01e8def2bcaf0c9e8358509f';

/// See also [stockSummary].
@ProviderFor(stockSummary)
final stockSummaryProvider = AutoDisposeFutureProvider<List<Stock>>.internal(
  stockSummary,
  name: r'stockSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stockSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StockSummaryRef = AutoDisposeFutureProviderRef<List<Stock>>;
String _$stockSortHash() => r'b617838a4e8517e98e88a69b91f7d6a25054648a';

/// See also [StockSort].
@ProviderFor(StockSort)
final stockSortProvider =
    AutoDisposeNotifierProvider<StockSort, StockSortMode>.internal(
      StockSort.new,
      name: r'stockSortProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockSortHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StockSort = AutoDisposeNotifier<StockSortMode>;
String _$stockViewModeHash() => r'13bb4d57865f0893a5f543c029f32908bbd78422';

/// See also [StockViewMode].
@ProviderFor(StockViewMode)
final stockViewModeProvider =
    AutoDisposeNotifierProvider<StockViewMode, bool>.internal(
      StockViewMode.new,
      name: r'stockViewModeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockViewModeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StockViewMode = AutoDisposeNotifier<bool>;
String _$stockSearchQueryHash() => r'6a3c674d52879d89b67b65668916dbb20171935f';

/// See also [StockSearchQuery].
@ProviderFor(StockSearchQuery)
final stockSearchQueryProvider =
    AutoDisposeNotifierProvider<StockSearchQuery, String>.internal(
      StockSearchQuery.new,
      name: r'stockSearchQueryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockSearchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StockSearchQuery = AutoDisposeNotifier<String>;
String _$stockTotalCountHash() => r'861af76751c68313fd7546b7f2c3d11db7aa8e24';

/// See also [StockTotalCount].
@ProviderFor(StockTotalCount)
final stockTotalCountProvider =
    AutoDisposeNotifierProvider<StockTotalCount, int>.internal(
      StockTotalCount.new,
      name: r'stockTotalCountProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockTotalCountHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StockTotalCount = AutoDisposeNotifier<int>;
String _$stockListHash() => r'5eac0a32632a96daa3a223f1e107c21c0fb3321d';

/// See also [StockList].
@ProviderFor(StockList)
final stockListProvider =
    AutoDisposeAsyncNotifierProvider<StockList, List<Stock>>.internal(
      StockList.new,
      name: r'stockListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StockList = AutoDisposeAsyncNotifier<List<Stock>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
