import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:stock_management_system/features/stock/presentation/pages/stock_history_page.dart';
import 'package:stock_management_system/features/stock/providers/stock_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:stock_management_system/core/services/export_service.dart';
import 'package:stock_management_system/features/stock/presentation/pages/pdf_viewer_page.dart';
import 'package:printing/printing.dart';
import 'stock_daily_items_page.dart';
import 'dart:typed_data';

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
  bool _isAllExpanded = false;
  int _listKey = 0;

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
        actions: [
          activitiesAsync.when(
            data: (activities) {
              final monthActivities = activities.where((a) {
                return a.timestamp.year == widget.month.year &&
                    a.timestamp.month == widget.month.month;
              }).toList();

              if (monthActivities.isEmpty) return const SizedBox.shrink();

              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    onPressed: () =>
                        _viewPdf(context, monthActivities, monthDisplay),
                    tooltip: 'ดู PDF',
                  ),
                  _buildExportDropdown(context, monthActivities, monthDisplay),
                  IconButton(
                    icon: Icon(_isAllExpanded
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded),
                    onPressed: () {
                      setState(() {
                        _isAllExpanded = !_isAllExpanded;
                        _listKey++; // Force rebuild list with new expansion state
                      });
                    },
                    tooltip: _isAllExpanded ? 'ย่อทั้งหมด' : 'ขยายทั้งหมด',
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
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
                    key: ValueKey('list_$_listKey'),
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

  Future<void> _viewPdf(BuildContext context, List<StockActivity> activities,
      String monthDisplay) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 16),
              Text('กำลังสร้างไฟล์ PDF...',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('กรุณารอสักครู่', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      )),
    );

    try {
      final pdfData =
          await ExportService.generateMonthlyPdf(widget.month, activities);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerPage(
              pdfData: pdfData,
              title: 'ประวัติ_$monthDisplay',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ไม่สามารถสร้าง PDF ได้: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Widget _buildExportDropdown(BuildContext context,
      List<StockActivity> activities, String monthDisplay) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        customButton: const Icon(
          Icons.download_rounded,
          color: Colors.white,
          size: 24,
        ),
        items: [
          DropdownItem<String>(
            value: 'pdf',
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red[400], size: 20),
                const SizedBox(width: 8),
                const Text('Download PDF', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          DropdownItem<String>(
            value: 'excel',
            child: Row(
              children: [
                Icon(Icons.table_view_rounded,
                    color: Colors.green[400], size: 20),
                const SizedBox(width: 8),
                const Text('Download Excel', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
        onChanged: (value) async {
          if (value == 'pdf') {
            final pdfData = await ExportService.generateMonthlyPdf(
                widget.month, activities);
            await Printing.sharePdf(
                bytes: pdfData, filename: 'Stock_History_$monthDisplay.pdf');
          } else if (value == 'excel') {
            final excelData = await ExportService.generateMonthlyExcel(
                widget.month, activities);
            await Printing.sharePdf(
                bytes: excelData, filename: 'Stock_History_$monthDisplay.xlsx');
          }
        },
        dropdownStyleData: DropdownStyleData(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          elevation: 8,
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.only(left: 14, right: 14),
        ),
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

    // Group items for summary in expanded view
    final Map<String, List<StockActivity>> itemGroups = {};
    for (var a in items) {
      itemGroups.putIfAbsent(a.stockId, () => []).add(a);
    }

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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('${date.millisecondsSinceEpoch}_$_listKey'),
          initiallyExpanded: _isAllExpanded,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.history_edu_rounded,
                color: Color(0xFF6C63FF), size: 24),
          ),
          title: Text(dateDisplay,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(
              'อัปเดตสินค้า $uniqueItems รายการ (${items.length} กิจกรรม)',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          children: [
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: itemGroups.entries.map((entry) {
                  final stockName = entry.value.first.stockName;
                  final acts = entry.value;
                  final netDiff = acts.fold(0, (sum, a) => sum + a.diff);
                  final color = netDiff > 0
                      ? Colors.green
                      : (netDiff < 0 ? Colors.red : Colors.blue);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StockHistoryPage(
                            stockId: entry.key,
                            stockName: stockName,
                            dateFilter: date,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(stockName,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                          Text(
                            netDiff > 0 ? '+$netDiff' : '$netDiff',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.grey[300], size: 10),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StockDailyItemsPage(date: date)));
              },
              child: const Text('ดูรายละเอียดทั้งหมดของวันนี้',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF))),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
