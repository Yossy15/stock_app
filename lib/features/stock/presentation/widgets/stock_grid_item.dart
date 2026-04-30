import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
import 'package:stock_management_system/features/stock/presentation/widgets/quick_adjust_dialog.dart';
import '../../domain/stock.dart';
import '../../providers/stock_provider.dart';
import 'edit_stock_dialog.dart';

class StockGridItem extends ConsumerWidget {
  final Stock stock;

  const StockGridItem({super.key, required this.stock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLowStock = stock.qty < 5 && stock.qty > 0;
    final isOutOfStock = stock.qty == 0;
    final themeColor = isOutOfStock
        ? Colors.redAccent
        : (isLowStock ? Colors.orange : const Color(0xFF6C63FF));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isOutOfStock
            ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Accent Line
              Container(
                height: 6,
                width: double.infinity,
                color: themeColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.sell_rounded, color: Colors.grey[400], size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '฿${stock.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
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
                      
                      const SizedBox(height: 16),
                      
                      // Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ActionPill(
                            icon: Icons.remove_rounded,
                            onPressed: stock.qty > 0 ? () => _decreaseQty(context, ref) : null,
                            color: Colors.grey[400]!,
                          ),
                          _ActionPill(
                            icon: Icons.add_rounded,
                            onPressed: () => _increaseQty(context, ref),
                            color: const Color(0xFF6C63FF),
                          ),
                          _ActionPill(
                            icon: Icons.edit_rounded,
                            onPressed: () => _showEditDialog(context),
                            color: Colors.blueGrey,
                          ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _increaseQty(BuildContext context, WidgetRef ref) async {
    final performer = await _showPerformerDialog(context, 'เพิ่มจำนวน');
    if (performer == null || performer.isEmpty) return;

    try {
      await ref.read(stockListProvider.notifier).updateStockQty(stock.id, stock.qty + 1, performer: performer);
      ToastUtils.showSuccess('เพิ่มจำนวน "${stock.name}"');
    } catch (e) {
      ToastUtils.showError('ไม่สามารถอัปเดตได้: $e');
    }
  }

  Future<void> _decreaseQty(BuildContext context, WidgetRef ref) async {
    final performer = await _showPerformerDialog(context, 'ลดจำนวน');
    if (performer == null || performer.isEmpty) return;

    try {
      await ref.read(stockListProvider.notifier).updateStockQty(stock.id, stock.qty - 1, performer: performer);
      ToastUtils.showSuccess('ลดจำนวน "${stock.name}"');
    } catch (e) {
      ToastUtils.showError('ไม่สามารถอัปเดตได้: $e');
    }
  }

  Future<String?> _showPerformerDialog(BuildContext context, String action) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(action, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'ชื่อผู้ทำรายการ',
              hintText: 'กรุณาระบุชื่อของคุณ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
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
              final performer = await _showPerformerDialog(context, 'ลบสินค้า');
              if (performer == null || performer.isEmpty) return;

              try {
                await ref.read(stockListProvider.notifier).deleteStock(stock.id, performer: performer);
                ToastUtils.showSuccess('ลบ "${stock.name}" สำเร็จ');
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                ToastUtils.showError('ไม่สามารถลบสินค้าได้: $e');
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey[100] : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDisabled ? Colors.grey[300] : color,
          ),
        ),
      ),
    );
  }
}
