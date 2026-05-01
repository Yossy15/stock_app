import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
import 'package:stock_management_system/features/stock/presentation/widgets/quick_adjust_dialog.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
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
        ? kBorderError
        : (isLowStock ? Colors.orange : kPrimary);

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
                          color: isOutOfStock ? kBorderError : kText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(PhosphorIcons.tag(), color: Colors.grey[400], size: 14),
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
                            icon: PhosphorIcons.minus(),
                            onPressed: stock.qty > 0 ? () => _decreaseQty(context, ref) : null,
                            color: Colors.grey[400]!,
                          ),
                          _ActionPill(
                            icon: PhosphorIcons.plus(),
                            onPressed: () => _increaseQty(context, ref),
                            color: kPrimary,
                          ),
                          _ActionPill(
                            icon: PhosphorIcons.pencilSimple(),
                            onPressed: () => _showEditDialog(context),
                            color: Colors.blueGrey,
                          ),
                          _ActionPill(
                            icon: PhosphorIcons.trash(),
                            onPressed: () => _showDeleteConfirmation(context, ref),
                            color: kBorderError,
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
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                  color: kPrimary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                action,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'กรุณาระบุชื่อผู้ทำรายการ',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 28),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'ระบุชื่อของคุณ...',
                    hintStyle: TextStyle(color: Colors.grey[300], fontSize: 16),
                    prefixIcon: Icon(PhosphorIcons.user(), size: 20),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: kPrimary, width: 2),
                    ),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'กรุณากรอกชื่อ'
                      : null,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, controller.text.trim());
                    }
                  },
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ยกเลิก',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(begin: const Offset(0.9, 0.9), duration: 300.ms, curve: Curves.easeOutBack).fadeIn(),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBorderError.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIcons.trash(PhosphorIconsStyle.fill), color: kBorderError, size: 24),
            ),
            const SizedBox(width: 16),
            const Text(
              'ยืนยันการลบ',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ],
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบ "${stock.name}"? การดำเนินการนี้ไม่สามารถย้อนกลับได้',
          style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBorderError,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    try {
                      await ref.read(stockListProvider.notifier).deleteStock(stock.id);
                      if (context.mounted) Navigator.pop(context);
                      ToastUtils.showSuccess('ลบสินค้าสำเร็จ');
                    } catch (e) {
                      ToastUtils.showError('ไม่สามารถลบได้: $e');
                    }
                  },
                  child: const Text('ยืนยันการลบ', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ).animate().scale(begin: const Offset(0.9, 0.9), duration: 300.ms, curve: Curves.easeOutBack).fadeIn(),
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
      ).animate(target: isDisabled ? 0 : 1).scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(0.92, 0.92),
          ),
    );
  }
}
