import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
import 'package:stock_management_system/core/widgets/common_widgets.dart';
import '../../providers/stock_provider.dart';
import 'stock_history_page.dart';

class StockDailyItemsPage extends ConsumerStatefulWidget {
  final DateTime date;

  const StockDailyItemsPage({super.key, required this.date});

  @override
  ConsumerState<StockDailyItemsPage> createState() =>
      _StockDailyItemsPageState();
}

class _StockDailyItemsPageState extends ConsumerState<StockDailyItemsPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    ref.invalidate(stockActivitiesProvider);
    await ref.read(stockActivitiesProvider.future);
    _refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(stockActivitiesProvider);
    final dateDisplay =
        DateFormat('EEEEที่ d MMMM yyyy', 'th_TH').format(widget.date);

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppAppBar(
        title: dateDisplay,
      ),
      body: AppRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: activitiesAsync.when(
          data: (activities) {
            final dailyActivities = activities.where((a) {
              return a.timestamp.year == widget.date.year &&
                  a.timestamp.month == widget.date.month &&
                  a.timestamp.day == widget.date.day;
            }).toList();

            final Map<String, List<StockActivity>> itemGroups = {};
            for (var a in dailyActivities) {
              itemGroups.putIfAbsent(a.stockId, () => []).add(a);
            }

            final itemIds = itemGroups.keys.toList();

            if (itemIds.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              physics: const BouncingScrollPhysics(),
              itemCount: itemIds.length,
              itemBuilder: (context, index) {
                final stockId = itemIds[index];
                final itemActs = itemGroups[stockId]!;
                return _buildItemSummaryTile(context, stockId, itemActs)
                    .animate(delay: (index * 50).ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.05, end: 0);
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                AppShimmer(height: 100, borderRadius: kCardRadius),
                SizedBox(height: 12),
                AppShimmer(height: 100, borderRadius: kCardRadius),
                SizedBox(height: 12),
                AppShimmer(height: 100, borderRadius: kCardRadius),
              ],
            ),
          ),
          error: (e, s) => AppErrorState(onRetry: _onRefresh),
        ),
      ),
    );
  }

  Widget _buildItemSummaryTile(
      BuildContext context, String stockId, List<StockActivity> items) {
    final first = items.first;
    int netDiff = items.fold(0, (sum, a) => sum + a.diff);
    final color =
        netDiff > 0 ? Colors.green : (netDiff < 0 ? Colors.red : Colors.blue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kShadowSmall,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(PhosphorIcons.package(PhosphorIconsStyle.bold), color: color, size: 24),
        ),
        title: Text(first.stockName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('มีการเคลื่อนไหว ${items.length} ครั้งในวันนี้',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  netDiff > 0 ? '+$netDiff' : '$netDiff',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w900, fontSize: 20),
                ),
                Text('รวมสุทธิ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 10)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(PhosphorIcons.caretRight(),
                color: Colors.grey[200], size: 16),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockHistoryPage(
                stockId: stockId,
                stockName: first.stockName,
                dateFilter: widget.date,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.calendarX(PhosphorIconsStyle.light), size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('ไม่พบรายการที่เคลื่อนไหวในวันนี้',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ).animate().fade().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
