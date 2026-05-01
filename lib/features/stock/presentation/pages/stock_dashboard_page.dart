import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:stock_management_system/features/stock/providers/stock_provider.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'stock_daily_items_page.dart';
import 'stock_monthly_activities_page.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
import 'package:stock_management_system/core/widgets/common_widgets.dart';

class StockDashboardPage extends ConsumerStatefulWidget {
  const StockDashboardPage({super.key});

  @override
  ConsumerState<StockDashboardPage> createState() => _StockDashboardPageState();
}

class _StockDashboardPageState extends ConsumerState<StockDashboardPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    ref.invalidate(stockSummaryProvider);
    ref.invalidate(stockActivitiesProvider);
    ref.invalidate(stockTotalCountProvider);

    await Future.wait([
      ref.read(stockSummaryProvider.future),
      ref.read(stockActivitiesProvider.future),
    ]);

    _refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(stockSummaryProvider);
    final totalItemsCount = ref.watch(stockTotalCountProvider);
    final activitiesAsync = ref.watch(stockActivitiesProvider);

    return Scaffold(
      backgroundColor: kSurface,
      appBar: const AppAppBar(
        title: 'สรุปภาพรวมคลังสินค้า',
      ),
      body: AppRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            summaryAsync.when(
              data: (stocks) => activitiesAsync.when(
                data: (activities) {
                  final totalQty =
                      stocks.fold<int>(0, (sum, item) => sum + item.qty);
                  final totalValue = stocks.fold<double>(
                      0, (sum, item) => sum + (item.price * item.qty));
                  final lowStockItems =
                      stocks.where((s) => s.qty < 5 && s.qty > 0).toList();
                  final outOfStockItems = stocks.where((s) => s.qty == 0).toList();

                  final Map<String, List<StockActivity>> monthlyActivities = {};
                  for (var activity in activities) {
                    final monthStr =
                        DateFormat('yyyy-MM').format(activity.timestamp);
                    monthlyActivities
                        .putIfAbsent(monthStr, () => [])
                        .add(activity);
                  }
                  final sortedMonths = monthlyActivities.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Key Metrics Section
                          _buildSectionHeader('สถานะคลังสินค้า',
                                  'ข้อมูลล่าสุด ณ วันที่ ${DateFormat('d MMMM yyyy', 'th_TH').format(DateTime.now())}')
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.1, end: 0),
                          const SizedBox(height: 16),
                          _buildMetricsGrid(
                                  totalValue, totalItemsCount, totalQty, activities)
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 500.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 32),

                          // Health Monitoring
                          _buildSectionHeader('รายการที่ต้องเติมสินค้า',
                                  'พบ ${outOfStockItems.length + lowStockItems.length} รายการที่ต้องระวัง')
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 400.ms),
                          const SizedBox(height: 16),
                          if (outOfStockItems.isEmpty && lowStockItems.isEmpty)
                            _buildCleanState()
                          else
                            _buildRestockCarousel(
                                    [...outOfStockItems, ...lowStockItems])
                                .animate()
                                .fadeIn(delay: 300.ms, duration: 500.ms)
                                .scale(
                                    begin: const Offset(0.95, 0.95),
                                    end: const Offset(1.0, 1.0)),

                          const SizedBox(height: 32),

                          // Activity Log
                          _buildSectionHeader('ประวัติกิจกรรมรายเดือน',
                                  'บันทึกย้อนหลัง ${sortedMonths.length} เดือน')
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms),
                          const SizedBox(height: 16),
                          if (sortedMonths.isEmpty)
                            _buildEmptyLog()
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: sortedMonths.length,
                              itemBuilder: (context, index) {
                                final monthKey = sortedMonths[index];
                                return _buildActivityMonthTile(context, monthKey,
                                        monthlyActivities[monthKey]!)
                                    .animate()
                                    .fadeIn(
                                        delay: (500 + (index * 50)).ms,
                                        duration: 400.ms)
                                    .slideX(begin: 0.05, end: 0);
                              },
                            ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        AppShimmer(height: 120, borderRadius: kCardRadius),
                        SizedBox(height: 16),
                        AppShimmer(height: 120, borderRadius: kCardRadius),
                        SizedBox(height: 16),
                        AppShimmer(height: 200, borderRadius: kCardRadius),
                      ],
                    ),
                  ),
                ),
                error: (e, s) => SliverFillRemaining(
                  child: AppErrorState(onRetry: _onRefresh),
                ),
              ),
              loading: () => const SliverFillRemaining(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AppShimmer(height: 120, borderRadius: kCardRadius),
                      SizedBox(height: 16),
                      AppShimmer(height: 120, borderRadius: kCardRadius),
                    ],
                  ),
                ),
              ),
              error: (e, s) => SliverFillRemaining(
                child: AppErrorState(onRetry: _onRefresh),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12,
                      color: kTextSub,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
      double val, int count, int qty, List<StockActivity> activities) {
    final todayCount = activities.where((a) {
      final now = DateTime.now();
      return a.timestamp.day == now.day &&
          a.timestamp.month == now.month &&
          a.timestamp.year == now.year;
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildMetricCard('มูลค่าคลังสินค้า',
                      '฿${NumberFormat('#,###').format(val)}', PhosphorIcons.bank(), kPrimary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMetricCard('รายการสินค้า', '$count รายการ',
                      PhosphorIcons.package(), Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildMetricCard('จำนวนชิ้นรวม',
                      '${NumberFormat('#,###').format(qty)} ชิ้น', PhosphorIcons.stack(), Colors.teal)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMetricCard('กิจกรรมวันนี้', '$todayCount รายการ',
                      PhosphorIcons.lightning(), Colors.orangeAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kShadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D))),
        ],
      ),
    );
  }

  Widget _buildRestockCarousel(List<dynamic> items) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isOut = item.qty == 0;
          final color = isOut ? Colors.redAccent : Colors.orange;
          return Container(
            width: 200,
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(kCardRadius),
              border: Border.all(color: color.withOpacity(0.1), width: 1),
              boxShadow: kShadowSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isOut ? 'สินค้าหมด' : 'ใกล้หมด',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 10)),
                    Icon(
                        isOut
                            ? PhosphorIcons.warningCircle(PhosphorIconsStyle.bold)
                            : PhosphorIcons.warning(PhosphorIconsStyle.bold),
                        color: color,
                        size: 16),
                  ],
                ),
                const Spacer(),
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(isOut ? 'ต้องสั่งซื้อด่วน' : 'เหลือเพียง ${item.qty} ชิ้น',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityMonthTile(
      BuildContext context, String monthKey, List<StockActivity> items) {
    final monthDate = DateTime.parse('$monthKey-01');
    final monthDisplay = DateFormat('MMMM yyyy', 'th_TH').format(monthDate);
    final uniqueDays = items.map((a) => a.timestamp.day).toSet().length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kShadowSmall,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration:
              BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
          child: Icon(PhosphorIcons.calendar(PhosphorIconsStyle.bold),
              color: kPrimary, size: 24),
        ),
        title: Text(monthDisplay,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('มีการเคลื่อนไหว $uniqueDays วัน (${items.length} กิจกรรม)',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Icon(PhosphorIcons.caretRight(), color: Colors.grey[300], size: 16),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    StockMonthlyActivitiesPage(month: monthDate))),
      ),
    );
  }

  Widget _buildCleanState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.green[50], borderRadius: BorderRadius.circular(kCardRadius)),
        child: Row(
          children: [
            Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                color: Colors.green, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ยอดเยี่ยม!',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('สินค้าทุกรายการมีจำนวนเพียงพอต่อการใช้งาน',
                      style: TextStyle(color: Colors.green[700], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLog() =>
      const Center(child: Text('ยังไม่มีกิจกรรมบันทึกไว้'));
}
