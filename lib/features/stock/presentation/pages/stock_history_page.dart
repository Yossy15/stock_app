import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/stock_provider.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
import 'package:stock_management_system/core/widgets/common_widgets.dart';

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

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppAppBar(
        title: widget.stockName,
        subtitle: widget.dateFilter != null
            ? 'ประวัติเมื่อ ${DateFormat('d MMMM yyyy', 'th_TH').format(widget.dateFilter!)}'
            : null,
      ),
      body: AppRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: activitiesAsync.when(
          data: (activities) {
            final itemActivities = activities.where((a) {
              bool matchItem = a.stockId == widget.stockId;
              if (widget.dateFilter != null) {
                bool matchDate = a.timestamp.year == widget.dateFilter!.year &&
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
                    itemActivities.first.finalQty,
                  ).animate().slideY(
                      begin: 1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOut),
                ),
              ],
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
                          color:
                              _getActivityColor(activity.type).withOpacity(0.4),
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
          )
              .animate(delay: (index * 50).ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.05, end: 0),
        );
      },
    );
  }

  Widget _buildActivityCard(StockActivity activity) {
    final color = _getActivityColor(activity.type);
    final isIncrease = activity.diff > 0;
    final timeStr = DateFormat('HH:mm').format(activity.timestamp.toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kShadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStatusTitle(activity) + " (${activity.performer})",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$timeStr น.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  Text(
                    activity.performer,
                    style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${activity.diff.abs()}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isIncrease
                      ? Colors.green
                      : (activity.diff < 0 ? Colors.red : Colors.blue),
                ),
              ),
              const SizedBox(width: 4),
              Text('ชิ้น',
                  style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('คงเหลือ',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                  Text('${activity.finalQty}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
          if (activity.price > 0) ...[
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                Icon(PhosphorIcons.tag(), size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('ราคาขณะทำรายการ: ฿${activity.price}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSummary(int added, int reduced, double pAdd, double pRed,
      double net, int latestQty) {
    final dateDisplay = widget.dateFilter != null
        ? DateFormat('d MMMM yyyy', 'th_TH').format(widget.dateFilter!)
        : 'วันนี้';

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 44),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40), topRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timeframe Label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'คงเหลือปัจจุบัน',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '$latestQty',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: kText,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ชิ้น',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ยอด$dateDisplay',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMiniMetric('เข้า', '+$added', Colors.green),
                      const SizedBox(width: 12),
                      _buildMiniMetric('ออก', '-$reduced', Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.light),
              size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('ไม่พบข้อมูลความเคลื่อนไหว',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ).animate().fade().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.create:
        return Colors.blue;
      case ActivityType.update:
        return Colors.orange;
      case ActivityType.delete:
        return Colors.red;
      case ActivityType.qtyChange:
        return kPrimary;
    }
  }

  String _getStatusTitle(StockActivity activity) {
    if (activity.type == ActivityType.create || activity.diff > 0) {
      return 'เพิ่มสินค้า';
    } else if (activity.type == ActivityType.delete || activity.diff < 0) {
      return 'เบิกสินค้า';
    }
    return 'แก้ไขข้อมูล'; // สำหรับการแก้ไขราคาโดยไม่เปลี่ยนจำนวน
  }
}
