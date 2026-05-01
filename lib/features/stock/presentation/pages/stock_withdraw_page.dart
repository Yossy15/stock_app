import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_management_system/features/stock/domain/stock.dart';
import 'package:stock_management_system/core/utils/toast_utils.dart';
import '../../providers/stock_provider.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
import 'package:stock_management_system/core/widgets/common_widgets.dart';

// ─── Page ────────────────────────────────────────────────────────────────────

class StockWithdrawPage extends ConsumerStatefulWidget {
  const StockWithdrawPage({super.key});

  @override
  ConsumerState<StockWithdrawPage> createState() => _StockWithdrawPageState();
}

class _StockWithdrawPageState extends ConsumerState<StockWithdrawPage> {
  late FormGroup form;
  final _selectedStockIdNotifier = ValueNotifier<String?>(null);
  final _searchController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    form = fb.group({
      'product': FormControl<Stock>(validators: [Validators.required]),
      'quantity': FormControl<int>(
        validators: [Validators.required, Validators.min(1)],
      ),
      'performer': FormControl<String>(validators: [Validators.required]),
    }, [
      Validators.delegate(_insufficientStockValidator),
    ]);
  }

  @override
  void dispose() {
    _selectedStockIdNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _insufficientStockValidator(
      AbstractControl<dynamic> control) {
    final fg = control as FormGroup;
    final productCtrl = fg.control('product');
    final qtyCtrl = fg.control('quantity');

    if (productCtrl.value != null && qtyCtrl.value != null) {
      final product = productCtrl.value as Stock;
      final qty = qtyCtrl.value as int;
      if (qty > product.qty) {
        qtyCtrl.setErrors({'insufficientStock': product.qty});
      } else {
        qtyCtrl.removeError('insufficientStock');
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (form.invalid) {
      form.markAllAsTouched();
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final product = form.control('product').value as Stock;
      final qty = form.control('quantity').value as int;
      final performer = form.control('performer').value as String;

      await ref
          .read(stockListProvider.notifier)
          .withdrawStock(product.id, qty, performer);

      if (mounted) {
        ToastUtils.showSuccess('เบิกสินค้าสำเร็จ');
        form.reset();
        _selectedStockIdNotifier.value = null;
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('เกิดข้อผิดพลาด: ${e.toString()}');
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastUtils.init(context);
    final stocksAsync = ref.watch(stockListProvider);
    final activitiesAsync = ref.watch(stockActivitiesProvider);

    return Scaffold(
      backgroundColor: kSurface,
      appBar: const AppAppBar(title: 'เบิกสินค้า'),
      body: ReactiveForm(
        formGroup: form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCard(stocksAsync)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),
              const SizedBox(height: 36),
              _buildSectionHeader(
                icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.bold),
                title: 'ประวัติการเบิกสินค้า',
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              _buildHistorySection(activitiesAsync),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────────────

  // ─── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: kPrimaryLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: kPrimary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kText,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ─── Form Card ────────────────────────────────────────────────────────────

  Widget _buildFormCard(AsyncValue<List<Stock>> stocksAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kShadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.shoppingCartSimple(),
                    size: 18, color: kPrimary),
              ),
              const SizedBox(width: 12),
              const Text(
                'ฟอร์มเบิกสินค้า',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              'กรอกข้อมูลการเบิกสินค้าให้ครบถ้วน',
              style: TextStyle(
                fontSize: 12,
                color: kTextSub,
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildFieldLabel('สินค้า', PhosphorIcons.package(),
              required: true),
          const SizedBox(height: 8),
          stocksAsync.when(
            data: _buildStockDropdown,
            loading: () => const AppShimmer(height: kFieldHeight),
            error: (e, _) => const AppErrorState(
                message: 'ไม่สามารถโหลดรายการสินค้า', onRetry: null),
          ),

          const SizedBox(height: 20),
          _buildFieldLabel('จำนวนที่เบิก', PhosphorIcons.hash(), required: true),
          const SizedBox(height: 8),
          _buildReactiveTextField(
            formControlName: 'quantity',
            hint: 'ระบุจำนวน',
            icon: PhosphorIcons.hash(),
            keyboardType: TextInputType.number,
            validationMessages: {
              'required': (_) => 'กรุณาระบุจำนวน',
              'min': (_) => 'จำนวนต้องมากกว่า 0',
              'number': (_) => 'กรุณาระบุเป็นตัวเลข',
              'insufficientStock': (e) => 'สินค้าไม่พอ (มีเพียง $e ชิ้น)',
            },
            valueAccessor: IntValueAccessor(),
          ),

          const SizedBox(height: 20),
          _buildFieldLabel('ผู้ทำรายการ', PhosphorIcons.user(),
              required: true),
          const SizedBox(height: 8),
          _buildReactiveTextField(
            formControlName: 'performer',
            hint: 'ชื่อ-นามสกุล',
            icon: PhosphorIcons.user(),
            validationMessages: {
              'required': (_) => 'กรุณาระบุชื่อผู้ทำรายการ',
            },
          ),

          const SizedBox(height: 28),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ─── Field Label ──────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String label, IconData icon,
      {bool required = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: kPrimary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kText,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text('*',
              style: TextStyle(
                  color: kBorderError,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }

  // ─── Dropdown ─────────────────────────────────────────────────────────────

  Widget _buildStockDropdown(List<Stock> stocks) {
    return ReactiveFormField<Stock, Stock>(
      formControlName: 'product',
      builder: (field) {
        final hasError = field.errorText != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                isExpanded: true,
                hint: Text(
                  'เลือกสินค้า...',
                  style: TextStyle(fontSize: 14, color: kTextHint),
                ),
                valueListenable: _selectedStockIdNotifier,
                items: stocks
                    .map(
                      (item) => DropdownItem<String>(
                        value: item.id,
                        height: 40,
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: item.qty > 0
                                    ? const Color(0xFF2E7D32)
                                    : kBorderError,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kText,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item.qty > 0
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'คงเหลือ ${item.qty}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: item.qty > 0
                                      ? const Color(0xFF2E7D32)
                                      : kBorderError,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id != null) {
                    final selected = stocks.firstWhere((s) => s.id == id);
                    field.didChange(selected);
                    _selectedStockIdNotifier.value = id;
                    form.control('quantity').updateValueAndValidity();
                  }
                },
                buttonStyleData: ButtonStyleData(
                  height: kFieldHeight, // ← same as text fields
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(
                      color: hasError ? kBorderError : kBorder,
                      width: hasError ? 1.5 : 1.0,
                    ),
                    color: kSurface,
                  ),
                ),
                iconStyleData: IconStyleData(
                  icon: Icon(
                    PhosphorIcons.caretDown(),
                    color: hasError ? kBorderError : kTextSub,
                    size: 22,
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 320,
                  offset: const Offset(0, -4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
                dropdownSearchData: DropdownSearchData(
                  searchController: _searchController,
                  searchBarWidgetHeight: 56,
                  searchBarWidget: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextFormField(
                      controller: _searchController,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 14, color: kText),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        hintText: 'ค้นหาสินค้า...',
                        hintStyle: TextStyle(fontSize: 13, color: kTextHint),
                        prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                            size: 18, color: kTextSub),
                        filled: true,
                        fillColor: kSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: kPrimary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  searchMatchFn: (item, search) {
                    final stock = stocks.firstWhere((s) => s.id == item.value);
                    return stock.name
                        .toLowerCase()
                        .contains(search.toLowerCase());
                  },
                ),
              ),
            ),
            if (hasError) _buildErrorText('กรุณาเลือกสินค้า'),
          ],
        );
      },
    );
  }

  // ─── Reactive Text Field ──────────────────────────────────────────────────

  Widget _buildReactiveTextField({
    required String formControlName,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    Map<String, String Function(Object)>? validationMessages,
    ControlValueAccessor<dynamic, String>? valueAccessor,
  }) {
    return ReactiveTextField<dynamic>(
      formControlName: formControlName,
      keyboardType: keyboardType,
      validationMessages: validationMessages,
      valueAccessor: valueAccessor,
      style: const TextStyle(fontSize: 14, color: kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: kTextHint),
        // Remove label — using external label widget instead for consistency
        prefixIcon: Icon(icon, size: 18, color: kTextSub),
        filled: true,
        fillColor: kSurface,
        isDense: false,
        // Vertical padding tuned so field renders at exactly kFieldHeight
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17, // (56 - 22 icon) / 2 ≈ 17
        ),
        constraints: const BoxConstraints(minHeight: kFieldHeight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: const BorderSide(color: kBorderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: const BorderSide(color: kBorderError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: const BorderSide(color: kBorderError, width: 1.5),
        ),
        errorStyle: const TextStyle(
          fontSize: 11.5,
          color: kBorderError,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Submit Button ────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kPrimary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.bold), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'ยืนยันการเบิกสินค้า',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.01, 1.01), duration: 1000.ms),
    );
  }

  // ─── History ──────────────────────────────────────────────────────────────

  Widget _buildHistorySection(AsyncValue<List<StockActivity>> activitiesAsync) {
    return activitiesAsync.when(
      data: (activities) {
        final now = DateTime.now();
        final withdraws = activities.where((a) {
          final localTimestamp = a.timestamp.toLocal();
          final isWithdraw = a.diff < 0;
          final isToday = localTimestamp.year == now.year &&
              localTimestamp.month == now.month &&
              localTimestamp.day == now.day;
          return isWithdraw && isToday;
        }).toList();

        if (withdraws.isEmpty) return _buildEmptyHistory();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: withdraws.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildActivityTile(withdraws[i])
              .animate(delay: (300 + (i * 50)).ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.05, end: 0),
        );
      },
      loading: () => Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: AppShimmer(height: 72),
          ),
        ),
      ),
      error: (e, _) =>
          const AppErrorState(message: 'ไม่สามารถโหลดประวัติ', onRetry: null),
    );
  }

  Widget _buildActivityTile(StockActivity activity) {
    final dateStr = DateFormat('d MMM yyyy, HH:mm', 'th_TH')
        .format(activity.timestamp.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(PhosphorIcons.shoppingCartSimple(PhosphorIconsStyle.bold),
                color: kBorderError, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activity.stockName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: kText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'เบิกสินค้า',
                        style: TextStyle(
                          color: kBorderError,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'โดย: ${activity.performer}',
                  style: const TextStyle(color: kTextSub, fontSize: 12),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(color: kTextHint, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${activity.diff.abs()}',
                  style: const TextStyle(
                    color: kBorderError,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'เหลือ ${activity.finalQty}',
                style: const TextStyle(color: kTextSub, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.light),
                size: 36, color: kPrimary),
          ),
          const SizedBox(height: 16),
          const Text(
            'ยังไม่มีประวัติการเบิกสินค้า',
            style: TextStyle(
              color: kTextSub,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'รายการที่เบิกจะปรากฏที่นี่',
            style: TextStyle(color: kTextHint, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: kBorderError,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
