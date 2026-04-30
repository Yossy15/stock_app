import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
import 'package:stock_management_system/features/stock/presentation/widgets/quick_adjust_dialog.dart';
import '../../domain/stock.dart';
import '../../providers/stock_provider.dart';
import 'edit_stock_dialog.dart';

class StockItemTile extends ConsumerWidget {
  final Stock stock;

  const StockItemTile({super.key, required this.stock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '฿');
    final isLowStock = stock.qty < 5 && stock.qty > 0;
    final isOutOfStock = stock.qty == 0;
    final themeColor = isOutOfStock
        ? Colors.redAccent
        : (isLowStock ? Colors.orange : const Color(0xFF6C63FF));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isOutOfStock
            ? Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1)
            : Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => QuickAdjustDialog(stock: stock),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Side Accent
                Container(
                  width: 8,
                  color: themeColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: isOutOfStock ? Colors.redAccent : const Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.sell_rounded, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              currencyFormat.format(stock.price),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isOutOfStock ? 'หมดสต็อก' : 'คงเหลือ: ${stock.qty}',
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          _ActionPill(
                            icon: Icons.remove_rounded,
                            onPressed: stock.qty > 0 ? () => _decreaseQty(context, ref) : null,
                            color: Colors.grey[400]!,
                          ),
                          const SizedBox(width: 8),
                          _ActionPill(
                            icon: Icons.add_rounded,
                            onPressed: () => _increaseQty(context, ref),
                            color: const Color(0xFF6C63FF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _ActionPill(
                            icon: Icons.edit_rounded,
                            onPressed: () => _showEditDialog(context),
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                          _ActionPill(
                            icon: Icons.delete_rounded,
                            onPressed: () => _showDeleteConfirmation(context, ref),
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _increaseQty(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(stockListProvider.notifier).updateStockQty(stock.id, stock.qty + 1);
      ToastUtils.showSuccess('เพิ่มจำนวน "${stock.name}"');
    } catch (e) {
      ToastUtils.showError('ไม่สามารถอัปเดตได้: $e');
    }
  }

  Future<void> _decreaseQty(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(stockListProvider.notifier).updateStockQty(stock.id, stock.qty - 1);
      ToastUtils.showSuccess('ลดจำนวน "${stock.name}"');
    } catch (e) {
      ToastUtils.showError('ไม่สามารถอัปเดตได้: $e');
    }
  }

  void _showEditDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStockDialog(stock: stock),
        fullscreenDialog: true,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ยืนยันการลบ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบ "${stock.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                await ref.read(stockListProvider.notifier).deleteStock(stock.id);
                ToastUtils.showSuccess('ลบ "${stock.name}" สำเร็จ');
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                ToastUtils.showError('ลบไม่สำเร็จ: $e');
              }
            },
            child: const Text('ลบสินค้า'),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _ActionPill({required this.icon, this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey[50] : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDisabled ? Colors.grey[300] : color,
          ),
        ),
      ),
    );
  }
}
