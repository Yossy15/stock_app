import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../providers/stock_provider.dart';

class StockHistoryPage extends ConsumerStatefulWidget {
  final String stockId;
  final String stockName;
  final DateTime? dateFilter; // Optional: show history only for this date

  const StockHistoryPage({
    super.key,
    required this.stockId,
    required this.stockName,
    this.dateFilter,
  });

  @override
  ConsumerState<StockHistoryPage> createState() => _StockHistoryPageState();
}

class _StockHistoryPageState extends ConsumerState<StockHistoryPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.stockName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.dateFilter != null)
              Text(
                'ประวัติเมื่อ ${DateFormat('d MMMM yyyy', 'th_TH').format(widget.dateFilter!)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        header: const WaterDropMaterialHeader(
          backgroundColor: Color(0xFF6C63FF),
          color: Colors.white,
        ),
        child: activitiesAsync.when(
          data: (activities) {
            final itemActivities = activities.where((a) {
              bool matchItem = a.stockId == widget.stockId;
              if (widget.dateFilter != null) {
                bool matchDate =
                    a.timestamp.year == widget.dateFilter!.year &&
                    a.timestamp.month == widget.dateFilter!.month &&
                    a.timestamp.day == widget.dateFilter!.day;
                return matchItem && matchDate;
              }
              return matchItem;
            }).toList();

            int totalAdded = 0;
            int totalReduced = 0;
            double totalPriceAdded = 0;
            double totalPriceReduced = 0;

            for (var a in itemActivities) {
              if (a.diff > 0) {
                totalAdded += a.diff;
                totalPriceAdded += (a.diff * a.price);
              } else if (a.diff < 0) {
                totalReduced += a.diff.abs();
                totalPriceReduced += (a.diff.abs() * a.price);
              }
            }

            final totalNetPrice = totalPriceAdded - totalPriceReduced;

            if (itemActivities.isEmpty) {
              return _buildEmptyState();
            }

            return Stack(
              children: [
                _buildTimelineList(itemActivities),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildBottomSummary(
                    totalAdded,
                    totalReduced,
                    totalPriceAdded,
                    totalPriceReduced,
                    totalNetPrice,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
          error: (e, s) => Center(child: Text('ข้อผิดพลาด: $e')),
        ),
      ),
    );
  }

  Widget _buildTimelineList(List<StockActivity> itemActivities) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 200),
      physics: const BouncingScrollPhysics(),
      itemCount: itemActivities.length,
      itemBuilder: (context, index) {
        final activity = itemActivities[index];
        final isLast = index == itemActivities.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getActivityColor(activity.type),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _getActivityColor(activity.type).withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey[300],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildActivityCard(activity),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(StockActivity activity) {
    final color = _getActivityColor(activity.type);
    final isIncrease = activity.diff > 0;
    final timeStr = DateFormat('HH:mm').format(activity.timestamp);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStatusTitle(activity.type),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
              ),
              Text('$timeStr น.', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                activity.diff > 0 ? '+${activity.diff}' : '${activity.diff}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isIncrease ? Colors.green : (activity.diff < 0 ? Colors.red : Colors.blue),
                ),
              ),
              const SizedBox(width: 4),
              Text('ชิ้น', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('คงเหลือ', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                  Text('${activity.finalQty}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
          if (activity.price > 0) ...[
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                Icon(Icons.sell_outlined, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('ราคาขณะทำรายการ: ฿${activity.price}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSummary(int added, int reduced, double pAdd, double pRed, double net) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildSummaryPill('เพิ่มรวม +$added', Colors.green),
              const SizedBox(width: 8),
              _buildSummaryPill('ลดรวม -$reduced', Colors.redAccent),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สรุปมูลค่ารวม', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text('ผลกระทบทางการเงิน', style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
              Text(
                '฿${NumberFormat('#,###.##').format(net)}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: net >= 0 ? Colors.green : Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('ไม่พบข้อมูลความเคลื่อนไหว', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.create: return Colors.blue;
      case ActivityType.update: return Colors.orange;
      case ActivityType.delete: return Colors.red;
      case ActivityType.qtyChange: return const Color(0xFF6C63FF);
    }
  }

  String _getStatusTitle(ActivityType type) {
    switch (type) {
      case ActivityType.create: return 'เริ่มรายการ';
      case ActivityType.update: return 'แก้ไขข้อมูล';
      case ActivityType.delete: return 'ลบรายการ';
      case ActivityType.qtyChange: return 'ปรับปรุงสต็อก';
    }
  }
}
