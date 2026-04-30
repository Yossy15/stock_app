import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:stock_management_system/features/stock/providers/stock_provider.dart';
import 'package:intl/intl.dart';
import 'stock_daily_items_page.dart';

class StockDashboardPage extends ConsumerStatefulWidget {
  const StockDashboardPage({super.key});

  @override
  ConsumerState<StockDashboardPage> createState() => _StockDashboardPageState();
}

class _StockDashboardPageState extends ConsumerState<StockDashboardPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

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
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Premium Custom App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6C63FF),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'สรุปภาพรวมคลังสินค้า',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8A84FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
        ],
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          header: const WaterDropMaterialHeader(
            backgroundColor: Color(0xFF6C63FF),
            color: Colors.white,
            offset: 0, // Header will start right below the App Bar
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              summaryAsync.when(
                data: (stocks) => activitiesAsync.when(
                  data: (activities) {
                    if (stocks.isEmpty && totalItemsCount == 0) {
                      return const SliverFillRemaining(
                        child: Center(child: Text('ไม่มีข้อมูลสินค้าสำหรับการสรุป')),
                      );
                    }

                    final totalQty = stocks.fold<int>(0, (sum, item) => sum + item.qty);
                    final totalValue = stocks.fold<double>(0, (sum, item) => sum + (item.price * item.qty));
                    final lowStockItems = stocks.where((s) => s.qty < 5 && s.qty > 0).toList();
                    final outOfStockItems = stocks.where((s) => s.qty == 0).toList();

                    final Map<String, List<StockActivity>> dateActivities = {};
                    for (var activity in activities) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(activity.timestamp);
                      dateActivities.putIfAbsent(dateStr, () => []).add(activity);
                    }
                    final sortedDates = dateActivities.keys.toList()..sort((a, b) => b.compareTo(a));

                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Key Metrics Section
                            _buildSectionHeader('สถานะคลังสินค้า', 'ข้อมูลล่าสุด ณ วันที่ ${DateFormat('d MMMM yyyy', 'th_TH').format(DateTime.now())}'),
                            const SizedBox(height: 16),
                            _buildMetricsGrid(totalValue, totalItemsCount, totalQty, activities),
                            
                            const SizedBox(height: 32),
                            
                            // Health Monitoring
                            _buildSectionHeader('รายการที่ต้องเติมสินค้า', 'พบ ${outOfStockItems.length + lowStockItems.length} รายการที่ต้องระวัง'),
                            const SizedBox(height: 16),
                            if (outOfStockItems.isEmpty && lowStockItems.isEmpty)
                              _buildCleanState()
                            else
                              _buildRestockCarousel([...outOfStockItems, ...lowStockItems]),

                            const SizedBox(height: 32),

                            // Activity Log
                            _buildSectionHeader('ประวัติกิจกรรมรายวัน', 'บันทึกย้อนหลัง ${sortedDates.length} วัน'),
                            const SizedBox(height: 16),
                            if (sortedDates.isEmpty)
                              _buildEmptyLog()
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: sortedDates.length,
                                itemBuilder: (context, index) {
                                  final dateKey = sortedDates[index];
                                  final date = DateTime.parse(dateKey);
                                  return _buildActivityDateTile(context, date, dateActivities[dateKey]!);
                                },
                              ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                  error: (e, s) => SliverFillRemaining(child: Center(child: Text('ข้อผิดพลาด: $e'))),
                ),
                loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                error: (e, s) => SliverFillRemaining(child: Center(child: Text('ข้อผิดพลาด: $e'))),
              ),
            ],
          ),
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
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(double val, int count, int qty, List<StockActivity> activities) {
    final todayCount = activities.where((a) {
      final now = DateTime.now();
      return a.timestamp.day == now.day && a.timestamp.month == now.month && a.timestamp.year == now.year;
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('มูลค่าคลังสินค้า', '฿${NumberFormat('#,###').format(val)}', Icons.payments_rounded, const Color(0xFF6C63FF))),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('รายการสินค้า', '$count รายการ', Icons.inventory_2_rounded, Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('จำนวนชิ้นรวม', '${NumberFormat('#,###').format(qty)} ชิ้น', Icons.layers_rounded, Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('กิจกรรมวันนี้', '$todayCount รายการ', Icons.bolt_rounded, Colors.orangeAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.1), width: 1),
              boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isOut ? 'สินค้าหมด' : 'ใกล้หมด', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
                    Icon(isOut ? Icons.error_rounded : Icons.warning_rounded, color: color, size: 16),
                  ],
                ),
                const Spacer(),
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(isOut ? 'ต้องสั่งซื้อด่วน' : 'เหลือเพียง ${item.qty} ชิ้น', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityDateTile(BuildContext context, DateTime date, List<StockActivity> items) {
    final uniqueItems = items.map((a) => a.stockId).toSet().length;
    final dateDisplay = DateFormat('EEEEที่ d MMMM', 'th_TH').format(date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.history_edu_rounded, color: Color(0xFF6C63FF), size: 24),
        ),
        title: Text(dateDisplay, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('อัปเดตสินค้า $uniqueItems รายการ (${items.length} กิจกรรม)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StockDailyItemsPage(date: date))),
      ),
    );
  }

  Widget _buildCleanState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ยอดเยี่ยม!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('สินค้าทุกรายการมีจำนวนเพียงพอต่อการใช้งาน', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLog() => const Center(child: Text('ยังไม่มีกิจกรรมบันทึกไว้'));
}
