import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Info
                Column(
                  children: [
                    Text(
                      'สินค้า: ${stock.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextSub,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: kText, fontSize: 16),
                        children: [
                          const TextSpan(text: 'คงเหลือปัจจุบัน: '),
                          TextSpan(
                            text: '${stock.qty}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: kPrimary,
                              fontSize: 22,
                            ),
                          ),
                          const TextSpan(text: ' ชิ้น'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Amount Input with Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepperButton(
                      icon: PhosphorIcons.minus(),
                      onPressed: () {
                        final current = form.control('amount').value as int;
                        if (current > 1) {
                          form.control('amount').value = current - 1;
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ReactiveTextField<int>(
                        formControlName: 'amount',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: kText,
                          letterSpacing: -2,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          suffixText: 'ชิ้น',
                          suffixStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    _buildStepperButton(
                      icon: PhosphorIcons.plus(),
                      onPressed: () {
                        final current = form.control('amount').value as int;
                        form.control('amount').value = current + 1;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Real-time Preview Inline
                ReactiveValueListenableBuilder<int>(
                  formControlName: 'amount',
                  builder: (context, control, child) {
                    final amount = control.value ?? 0;
                    final reducedResult = stock.qty - amount;
                    final addedResult = stock.qty + amount;

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInlinePreview(
                              'ถ้าลดจะเหลือ: ',
                              reducedResult < 0 ? 'ยอดติดลบ!' : '$reducedResult',
                              reducedResult < 0 ? kBorderError : Colors.grey[500]!,
                            ),
                            const SizedBox(width: 16),
                            _buildInlinePreview(
                              'ถ้าเพิ่มจะเป็น: ',
                              '$addedResult',
                              Colors.grey[500]!,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Performer Input (Minimal)
                ReactiveTextField<String>(
                  formControlName: 'performer',
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้ทำรายการ',
                    prefixIcon: Icon(PhosphorIcons.user(), size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Primary Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _AdjustButton(
                        label: 'ลดสต็อก (OUT)',
                        icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
                        color: kBorderError,
                        onPressed: () =>
                            _handleAdjust(context, ref, form, isAdd: false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AdjustButton(
                        label: 'เพิ่มสต็อก (IN)',
                        icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                        color: kPrimary,
                        onPressed: () =>
                            _handleAdjust(context, ref, form, isAdd: true),
                      ),
                    ),
                  ],
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
        ).animate().scale(begin: const Offset(0.9, 0.9), duration: 300.ms, curve: Curves.easeOutBack).fadeIn();
      },
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onPressed}) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: Colors.grey[100],
        foregroundColor: kText,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInlinePreview(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
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
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.02, 1.02), duration: 1000.ms),
    );
  }
}
