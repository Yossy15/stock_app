import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
import '../../domain/stock.dart';
import '../../providers/stock_provider.dart';

class QuickAdjustDialog extends ConsumerWidget {
  final Stock stock;

  const QuickAdjustDialog({super.key, required this.stock});

  FormGroup get form => fb.group({
        'amount': FormControl<int>(
          value: 1,
          validators: [Validators.required, Validators.min(1)],
        ),
        'performer': FormControl<String>(
          value: '',
          validators: [Validators.required],
        ),
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveFormBuilder(
      form: () => form,
      builder: (context, form, child) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Color(0xFF6C63FF),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  stock.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'คลังปัจจุบัน: ${stock.qty} ชิ้น',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),

                ReactiveTextField<String>(
                  formControlName: 'performer',
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้ทำรายการ',
                    hintText: 'ระบุชื่อของคุณ',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Input Field with Focus
                ReactiveTextField<int>(
                  formControlName: 'amount',
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.edit_outlined, color: Colors.grey),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Center(
                        widthFactor: 1,
                        child: Text('ชิ้น',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    hintText: '0',
                  ),
                  onTap: (control) {
                    // select all text on tap to make editing easier
                  },
                ),

                const SizedBox(height: 16),

                // Live Preview Indicator
                ReactiveValueListenableBuilder<int>(
                  formControlName: 'amount',
                  builder: (context, control, child) {
                    final amount = control.value ?? 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPreviewChip(
                            'หากลดเหลือ: ',
                            '${stock.qty - amount}',
                            Colors.redAccent,
                            (stock.qty - amount) >= 0),
                        const SizedBox(width: 8),
                        _buildPreviewChip('หากเพิ่มเป็น: ',
                            '${stock.qty + amount}', Colors.green, true),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: _AdjustButton(
                        label: 'ลดสต็อก',
                        icon: Icons.remove_rounded,
                        color: Colors.redAccent,
                        onPressed: () =>
                            _handleAdjust(context, ref, form, isAdd: false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AdjustButton(
                        label: 'เพิ่มสต็อก',
                        icon: Icons.add_rounded,
                        color: const Color(0xFF6C63FF),
                        onPressed: () =>
                            _handleAdjust(context, ref, form, isAdd: true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[400],
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('ยกเลิกรายการ',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewChip(
      String label, String value, Color color, bool isValid) {
    if (!isValid && color == Colors.redAccent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('ยอดติดลบ!',
            style: TextStyle(
                color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
          children: [
            TextSpan(text: label),
            TextSpan(
                text: value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _handleAdjust(BuildContext context, WidgetRef ref, FormGroup form,
      {required bool isAdd}) async {
    if (form.valid) {
      final amount = form.control('amount').value as int;
      final newQty = isAdd ? (stock.qty + amount) : (stock.qty - amount);

      if (newQty < 0) {
        ToastUtils.showError('จำนวนคงเหลือติดลบไม่ได้');
        return;
      }

      try {
        final performer = form.control('performer').value as String;
        await ref
            .read(stockListProvider.notifier)
            .updateStockQty(stock.id, newQty, performer: performer);
        final actionText = isAdd ? 'เพิ่ม' : 'ลด';
        ToastUtils.showSuccess('$actionTextจำนวน "${stock.name}" สำเร็จ');
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        ToastUtils.showError('ปรับจำนวนไม่สำเร็จ: $e');
      }
    } else {
      form.markAllAsTouched();
    }
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _AdjustButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
