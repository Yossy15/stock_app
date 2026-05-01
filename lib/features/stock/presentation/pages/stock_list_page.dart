import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
import 'package:stock_management_system/features/stock/providers/stock_provider.dart';
import '../widgets/stock_item_tile.dart';
import '../widgets/stock_grid_item.dart';
import '../widgets/add_stock_dialog.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
import 'package:stock_management_system/core/widgets/common_widgets.dart';

class StockListPage extends ConsumerStatefulWidget {
  const StockListPage({super.key});

  @override
  ConsumerState<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends ConsumerState<StockListPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();

  void _onRefresh() async {
    await ref.read(stockListProvider.notifier).refresh();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await ref.read(stockListProvider.notifier).fetchMore();
    _refreshController.loadComplete();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ToastUtils.init(context);
    final stockListAsync = ref.watch(stockListProvider);
    final userViewMode = ref.watch(stockViewModeProvider);

    ref.listen(stockSearchQueryProvider, (prev, next) {
      if (next.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTabletOrDesktop = constraints.maxWidth > 600;
        final bool showGridView = isTabletOrDesktop || userViewMode;

        return Scaffold(
          backgroundColor: kSurface,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [_buildAppBar(context, ref, showGridView)];
            },
            body: AppRefresher(
              controller: _refreshController,
              enablePullUp: true,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  stockListAsync.when(
                    data: (stocks) {
                      if (stocks.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(PhosphorIcons.package(PhosphorIconsStyle.light),
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'ไม่มีสินค้าในระบบ',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 18),
                                ),
                              ],
                            ),
                          ).animate().fade().scale(begin: const Offset(0.9, 0.9)),
                        );
                      }

                      if (showGridView) {
                        return SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            delegate:
                                SliverChildBuilderDelegate((context, index) {
                              return StockGridItem(stock: stocks[index])
                                  .animate(delay: (index * 50).ms)
                                  .fadeIn(duration: 400.ms)
                                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
                            }, childCount: stocks.length),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                        sliver: SliverList(
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                            return RepaintBoundary(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 4),
                                child:
                                    StockItemTile(stock: stocks[index]),
                              ),
                            ).animate(delay: (index * 50).ms)
                             .fadeIn(duration: 400.ms)
                             .slideY(begin: 0.1, end: 0);
                          }, childCount: stocks.length),
                        ),
                      );
                    },
                    loading: () => _buildShimmerLoading(),
                    error: (err, stack) => SliverFillRemaining(
                      child: AppErrorState(onRetry: _onRefresh),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDialog(context),
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
            label: const Text('เพิ่มสินค้า',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.02, 1.02), duration: 1000.ms),
        );
      },
    );
  }

  Widget _buildAppBar(
      BuildContext context, WidgetRef ref, bool isCurrentlyGrid) {
    final sortMode = ref.watch(stockSortProvider);
    final isSortedByQty = sortMode == StockSortMode.qtyAsc;

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: kPrimary,
      title: const Text('จัดการสต็อก',
          style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            isSortedByQty ? PhosphorIcons.sortAscending(PhosphorIconsStyle.bold) : PhosphorIcons.sortAscending(),
            color: isSortedByQty ? Colors.orangeAccent : Colors.white,
          ),
          onPressed: () {
            final newMode =
                isSortedByQty ? StockSortMode.none : StockSortMode.qtyAsc;
            ref.read(stockSortProvider.notifier).setSortMode(newMode);
            ref.read(stockListProvider.notifier).refresh();
          },
          tooltip: isSortedByQty ? 'เรียงแบบปกติ' : 'เรียงตามจำนวนน้อยก่อน',
        ),
        IconButton(
          icon: Icon(isCurrentlyGrid ? PhosphorIcons.list() : PhosphorIcons.squaresFour()),
          onPressed: () => ref.read(stockViewModeProvider.notifier).toggle(),
          tooltip: isCurrentlyGrid ? 'ดูแบบรายการ' : 'ดูแบบตาราง',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, Color(0xFF8E88FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildSearchBar(ref),
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(kRadius),
          boxShadow: kShadowSmall,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) =>
              ref.read(stockListProvider.notifier).setSearch(value),
          decoration: InputDecoration(
            hintText: 'ค้นหาสินค้า...',
            prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), color: kPrimary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(PhosphorIcons.x(), size: 20),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(stockListProvider.notifier).clearSearch();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppShimmer(height: 100, borderRadius: kCardRadius),
          );
        }, childCount: 5),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddStockDialog(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _BeautifulLoadingFooter extends StatefulWidget {
  const _BeautifulLoadingFooter();
  @override
  State<_BeautifulLoadingFooter> createState() =>
      _BeautifulLoadingFooterState();
}

class _BeautifulLoadingFooterState extends State<_BeautifulLoadingFooter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final value =
                    (sin((_controller.value * 2 * pi) + (index * 0.8)) + 1) / 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8 + (8 * value),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF)
                        .withOpacity(0.3 + (0.7 * value)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        const Text("กำลังโหลด...",
            style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
                fontSize: 10)),
      ],
    );
  }
}
