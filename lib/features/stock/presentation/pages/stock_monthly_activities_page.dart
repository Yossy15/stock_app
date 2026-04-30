import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:stock_management_system/features/stock/providers/stock_provider.dart';
import 'stock_daily_items_page.dart';

class StockMonthlyActivitiesPage extends ConsumerStatefulWidget {
  final DateTime month;

  const StockMonthlyActivitiesPage({super.key, required this.month});

  @override
  ConsumerState<StockMonthlyActivitiesPage> createState() =>
      _StockMonthlyActivitiesPageState();
}

class _StockMonthlyActivitiesPageState
    extends ConsumerState<StockMonthlyActivitiesPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _onRefresh() async {
    ref.invalidate(stockActivitiesProvider);
    await ref.read(stockActivitiesProvider.future);
    _refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(stockActivitiesProvider);
    final monthDisplay = DateFormat('MMMM yyyy', 'th_TH').format(widget.month);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('ประวัติของเดือน $monthDisplay',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              header: const WaterDropMaterialHeader(
                backgroundColor: Color(0xFF6C63FF),
                color: Colors.white,
              ),
              child: activitiesAsync.when(
                data: (activities) {
                  final monthActivities = activities.where((a) {
                    return a.timestamp.year == widget.month.year &&
                        a.timestamp.month == widget.month.month;
                  }).toList();

                  final filteredActivities = monthActivities.where((a) {
                    if (_searchQuery.isEmpty) return true;
                    return a.stockName
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();

                  final Map<String, List<StockActivity>> dateActivities = {};
                  for (var activity in filteredActivities) {
                    final dateStr =
                        DateFormat('yyyy-MM-dd').format(activity.timestamp);
                    dateActivities.putIfAbsent(dateStr, () => []).add(activity);
                  }
                  final sortedDates = dateActivities.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  if (sortedDates.isEmpty) {
                    return Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 80, color: Colors.grey[200]),
                        const SizedBox(height: 16),
                        Text(
                            _searchQuery.isEmpty
                                ? 'ไม่มีประวัติกิจกรรมในเดือนนี้'
                                : 'ไม่พบรายการที่ตรงกับ "$_searchQuery"',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedDates[index];
                      final date = DateTime.parse(dateKey);
                      return _buildActivityDateTile(
                          context, date, dateActivities[dateKey]!);
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
                error: (e, s) => Center(child: Text('ข้อผิดพลาด: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'ค้นหาชื่อสินค้าในเดือนนี้...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
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

  Widget _buildActivityDateTile(
      BuildContext context, DateTime date, List<StockActivity> items) {
    final uniqueItems = items.map((a) => a.stockId).toSet().length;
    final dateDisplay = DateFormat('EEEEที่ d MMMM', 'th_TH').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.history_edu_rounded,
              color: Color(0xFF6C63FF), size: 24),
        ),
        title: Text(dateDisplay,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
            'อัปเดตสินค้า $uniqueItems รายการ (${items.length} กิจกรรม)',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.grey[300], size: 16),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => StockDailyItemsPage(date: date))),
      ),
    );
  }
}
