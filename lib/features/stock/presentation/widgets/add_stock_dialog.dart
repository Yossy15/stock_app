import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
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
      validators: [Validators.required, DuplicateNameValidator(existingNames)],
    ),
    'qty': FormControl<int>(
      validators: [Validators.required, Validators.min(0)],
    ),
    'price': FormControl<double>(
      validators: [Validators.required, Validators.min(0)],
    ),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existingNames = ref
        .watch(stockListProvider)
        .maybeWhen(
          data: (stocks) => stocks.map((s) => s.name.trim()).toList(),
          orElse: () => <String>[],
        );

    final form = buildForm(existingNames);

    return ReactiveForm(
      formGroup: form,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('เพิ่มสินค้าใหม่'),
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            ReactiveFormConsumer(
              builder: (context, form, child) {
                return TextButton(
                  onPressed: form.valid
                      ? () => _submit(context, ref, form)
                      : null,
                  child: const Text(
                    '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'รายละเอียดสินค้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(height: 24),
              ReactiveTextField<String>(
                formControlName: 'name',
                validationMessages: {
                  ValidationMessage.required: (error) => 'กรุณากรอกชื่อสินค้า',
                  'duplicate': (error) => 'มีสินค้านี้อยู่ในระบบแล้ว',
                },
                decoration: InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  // hintText: 'เช่น มาม่า, น้ำดื่ม ฯลฯ',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
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
                      decoration: InputDecoration(
                        labelText: 'จำนวนคงเหลือ',
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReactiveTextField<double>(
                      formControlName: 'price',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validationMessages: {
                        ValidationMessage.required: (error) => 'กรุณากรอกราคา',
                        ValidationMessage.min: (error) =>
                            'ราคาต้องไม่ต่ำกว่า 0',
                      },
                      decoration: InputDecoration(
                        labelText: 'ราคาขาย (บาท)',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ReactiveFormConsumer(
                  builder: (context, form, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: form.valid
                          ? () => _submit(context, ref, form)
                          : null,
                      child: const Text(
                        'เพิ่มสินค้าเข้าระบบ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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

    try {
      await ref.read(stockListProvider.notifier).addStock(name, qty, price);
      ToastUtils.showSuccess('เพิ่มสินค้า "$name" สำเร็จ');
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      ToastUtils.showError('เกิดข้อผิดพลาด: $e');
    }
  }
}
