import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
import 'package:stock_management_system/core/widgets/common_widgets.dart';
import '../../providers/stock_provider.dart';

class DuplicateNameValidator extends Validator<dynamic> {
  final List<String> existingNames;

  DuplicateNameValidator(this.existingNames);

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    if (control.value != null) {
      final name = control.value.toString().trim().toLowerCase();
      if (existingNames
          .any((existing) => existing.trim().toLowerCase() == name)) {
        return {'duplicate': true};
      }
    }
    return null;
  }
}

class AddStockDialog extends ConsumerWidget {
  const AddStockDialog({super.key});

  FormGroup buildForm(List<String> existingNames) => fb.group({
        'name': FormControl<String>(
          validators: [
            Validators.required,
            DuplicateNameValidator(existingNames)
          ],
        ),
        'qty': FormControl<int>(
          validators: [Validators.required, Validators.min(0)],
        ),
        'price': FormControl<double>(
          validators: [Validators.required, Validators.min(0)],
        ),
        'performer': FormControl<String>(
          validators: [Validators.required],
        ),
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existingNames = ref.watch(stockListProvider).maybeWhen(
          data: (stocks) => stocks.map((s) => s.name.trim()).toList(),
          orElse: () => <String>[],
        );

    final form = buildForm(existingNames);

    return ReactiveForm(
      formGroup: form,
      child: Scaffold(
        backgroundColor: kSurface,
        appBar: AppAppBar(
          title: 'เพิ่มสินค้าใหม่',
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowLeft()),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Decoration
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.package(PhosphorIconsStyle.fill),
                    color: kPrimary,
                    size: 48,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('รายละเอียดสินค้า')
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideX(begin: -0.1, end: 0),
              const SizedBox(height: 20),

              ReactiveTextField<String>(
                formControlName: 'name',
                validationMessages: {
                  ValidationMessage.required: (error) => 'กรุณากรอกชื่อสินค้า',
                  'duplicate': (error) => 'มีสินค้านี้อยู่ในระบบแล้ว',
                },
                decoration: _buildInputDecoration(
                  label: 'ชื่อสินค้า',
                  icon: PhosphorIcons.package(),
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ReactiveTextField<int>(
                      formControlName: 'qty',
                      keyboardType: TextInputType.number,
                      validationMessages: {
                        ValidationMessage.required: (error) => 'กรุณากรอกจำนวน',
                        ValidationMessage.min: (error) =>
                            'จำนวนต้องไม่ต่ำกว่า 0',
                      },
                      decoration: _buildInputDecoration(
                        label: 'จำนวนคงเหลือ',
                        icon: PhosphorIcons.hash(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReactiveTextField<double>(
                      formControlName: 'price',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validationMessages: {
                        ValidationMessage.required: (error) => 'กรุณากรอกราคา',
                        ValidationMessage.min: (error) =>
                            'ราคาต้องไม่ต่ำกว่า 0',
                      },
                      decoration: _buildInputDecoration(
                        label: 'ราคาขาย (บาท)',
                        icon: PhosphorIcons.coins(),
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              ReactiveTextField<String>(
                formControlName: 'performer',
                validationMessages: {
                  ValidationMessage.required: (error) =>
                      'กรุณากรอกชื่อผู้ทำรายการ',
                },
                decoration: _buildInputDecoration(
                  label: 'ชื่อผู้ทำรายการ',
                  icon: PhosphorIcons.user(),
                  hint: 'ระบุชื่อของคุณ',
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ReactiveFormConsumer(
                  builder: (context, form, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        shadowColor: kPrimary.withOpacity(0.4),
                      ),
                      onPressed:
                          form.valid ? () => _submit(context, ref, form) : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                              size: 18),
                          const SizedBox(width: 12),
                          const Text(
                            'เพิ่มสินค้าเข้าระบบ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    )
                        .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true))
                        .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.01, 1.01),
                            duration: 1500.ms);
                  },
                ),
              ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: kTextSub,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String label, required IconData icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      floatingLabelStyle:
          const TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    FormGroup form,
  ) async {
    final name = form.control('name').value as String;
    final qty = form.control('qty').value as int;
    final price = (form.control('price').value as num).toDouble();
    final performer = form.control('performer').value as String;

    try {
      await ref
          .read(stockListProvider.notifier)
          .addStock(name, qty, price, performer: performer);
      ToastUtils.showSuccess('เพิ่มสินค้า "$name" สำเร็จ');
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      ToastUtils.showError('เกิดข้อผิดพลาด: $e');
    }
  }
}
