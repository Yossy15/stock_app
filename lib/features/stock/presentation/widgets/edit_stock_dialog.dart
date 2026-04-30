import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
import '../../domain/stock.dart';
import '../../providers/stock_provider.dart';

class EditDuplicateNameValidator extends Validator<dynamic> {
  final List<String> existingNames;
  final String currentName;

  EditDuplicateNameValidator(this.existingNames, this.currentName);

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value?.toString().trim().toLowerCase();
    if (value != null && value != currentName.trim().toLowerCase()) {
      if (existingNames
          .any((existing) => existing.trim().toLowerCase() == value)) {
        return {'duplicate': true};
      }
    }
    return null;
  }
}

class EditStockDialog extends ConsumerWidget {
  final Stock stock;

  const EditStockDialog({super.key, required this.stock});

  FormGroup buildForm(List<String> existingNames) => fb.group({
    'name': FormControl<String>(
      value: stock.name,
      validators: [
        Validators.required,
        EditDuplicateNameValidator(existingNames, stock.name),
      ],
    ),
    'qty': FormControl<int>(
      value: stock.qty,
      validators: [Validators.required, Validators.min(0)],
    ),
    'price': FormControl<double>(
      value: stock.price,
      validators: [Validators.required, Validators.min(0)],
    ),
    'performer': FormControl<String>(
      validators: [Validators.required],
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
          title: const Text('แก้ไขข้อมูลสินค้า'),
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
                'ข้อมูลสินค้าเดิม',
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
              const SizedBox(height: 20),
              ReactiveTextField<String>(
                formControlName: 'performer',
                validationMessages: {
                  ValidationMessage.required: (error) => 'กรุณากรอกชื่อผู้ทำรายการ',
                },
                decoration: InputDecoration(
                  labelText: 'ชื่อผู้ทำรายการ',
                  hintText: 'ระบุชื่อของคุณที่ทำการแก้ไข',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
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
                        'บันทึกการแก้ไขข้อมูล',
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
    final performer = form.control('performer').value as String;

    try {
      await ref
          .read(stockListProvider.notifier)
          .updateStock(stock.id, name: name, qty: qty, price: price, performer: performer);
      ToastUtils.showSuccess('แก้ไขข้อมูล "${stock.name}" สำเร็จ');
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      ToastUtils.showError('เกิดข้อผิดพลาด: $e');
    }
  }
}
