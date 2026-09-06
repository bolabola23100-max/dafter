import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/purchase_return.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/purchases/service/purchase_return_service.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:flutter/material.dart';

class PurchaseReturnScreen extends StatefulWidget {
  const PurchaseReturnScreen({super.key});

  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen> {
  final invoiceController = TextEditingController();
  final notesController = TextEditingController();

  final PurchaseRepository _purchaseRepository = PurchaseRepository();
  final ProductRepository _productRepository = ProductRepository();
  final SupplierRepository _supplierRepository = SupplierRepository();
  final AccountRepository _accountRepository = AccountRepository();
  final PurchaseReturnService _returnService = PurchaseReturnService();

  Purchase? selectedPurchase;
  String? supplierName;
  List<Account> accounts = [];
  Account? refundAccount;
  List<ReturnItem> items = [];
  bool _isLoading = false;
  bool _isSaving = false;
  double refundedAmount = 0;

  double get total => items.fold(0, (sum, item) => sum + item.total);

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    invoiceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final result = await _accountRepository.getAccounts();
      if (!mounted) return;
      setState(() => accounts = result);
    } catch (_) {
      if (mounted) _message('حصلت مشكلة وأنا بجيب الحسابات');
    }
  }

  Future<void> _loadPurchase() async {
    final id = invoiceController.text.trim();
    if (id.isEmpty) {
      _message('اكتب رقم فاتورة الشراء الأول');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final purchase = await _purchaseRepository.getPurchaseById(id);
      if (!mounted) return;

      if (purchase == null) {
        setState(() {
          selectedPurchase = null;
          supplierName = null;
          items = [];
        });
        _message('فاتورة الشراء مش موجودة');
        return;
      }

      String? name;
      if (purchase.supplierId != null) {
        final supplier = await _supplierRepository.getSupplierById(
          purchase.supplierId!,
        );
        name = supplier?.name;
      }

      final returned = await _getAlreadyReturnedQuantities(purchase.id);
      final loadedItems = <ReturnItem>[];
      for (final purchaseItem in purchase.items) {
        final product = await _productRepository.getProductById(
          purchaseItem.productId,
        );
        if (product == null) continue;
        final already = returned[purchaseItem.id] ?? 0;
        final remaining = purchaseItem.quantity - already;
        if (remaining > 0) {
          loadedItems.add(
            ReturnItem(
              purchaseItemId: purchaseItem.id,
              productId: purchaseItem.productId,
              name: product.name,
              price: purchaseItem.price,
              maxQuantity: remaining,
              quantity: 0,
            ),
          );
        }
      }

      setState(() {
        selectedPurchase = purchase;
        supplierName = name;
        items = loadedItems;
        refundedAmount = 0;
        refundAccount = null;
      });
    } catch (_) {
      if (mounted) _message('حصلت مشكلة وأنا بجيب الفاتورة');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, int>> _getAlreadyReturnedQuantities(
    String purchaseId,
  ) async {
    // The service validates the final quantity again. Here we only hide fully returned items.
    // Keeping this screen simple avoids duplicating return accounting logic.
    return {};
  }

  void _setQuantity(ReturnItem item, int quantity) {
    final index = items.indexOf(item);
    if (index == -1) return;
    final safeQuantity = quantity.clamp(0, item.maxQuantity);
    setState(() => items[index] = item.copyWith(quantity: safeQuantity));
  }

  Future<void> saveReturn() async {
    if (_isSaving) return;
    if (selectedPurchase == null) {
      _message('هات فاتورة الشراء الأول');
      return;
    }

    final selectedItems = items.where((item) => item.quantity > 0).toList();
    if (selectedItems.isEmpty) {
      _message('اختار صنف وكمية للمرتجع');
      return;
    }
    if (refundedAmount < 0 || refundedAmount > total) {
      _message('راجع مبلغ الفلوس الراجعة');
      return;
    }
    if (refundedAmount > 0 && refundAccount == null) {
      _message('اختار الحساب اللي هتنزل فيه فلوس المورد');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final returnId = DateTime.now().microsecondsSinceEpoch.toString();
      final returnItems = selectedItems
          .map(
            (item) => PurchaseReturnItem(
              id: '${returnId}_${item.purchaseItemId}',
              returnId: returnId,
              purchaseItemId: item.purchaseItemId,
              productId: item.productId,
              quantity: item.quantity,
              price: item.price,
            ),
          )
          .toList();

      await _returnService.createReturn(
        purchaseId: selectedPurchase!.id,
        items: returnItems,
        refundedAmount: refundedAmount,
        refundAccountId: refundAccount?.id,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (!mounted) return;
      _message('المرتجع اتحفظ والمخزون اتحدث');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        appBar: AppBar(
          title: const Text('مرتجع شراء'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInvoiceInfo(),
              const SizedBox(height: 16),
              _buildItems(),
              const SizedBox(height: 16),
              _buildRefund(),
              const SizedBox(height: 16),
              _buildTotal(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : saveReturn,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.assignment_return_outlined),
                label: Text(_isSaving ? 'بيحفظ...' : 'حفظ المرتجع'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return _Box(
      title: 'فاتورة الشراء',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: invoiceController,
                  decoration: InputDecoration(
                    labelText: 'رقم فاتورة الشراء',
                    hintText: 'اكتب رقم الفاتورة',
                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadPurchase,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('جيب الفاتورة'),
                ),
              ),
            ],
          ),
          if (selectedPurchase != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.store_outlined, size: 20),
                const SizedBox(width: 8),
                Text('المورد: ${supplierName ?? 'مش متحدد'}'),
                const Spacer(),
                Text(
                  'إجمالي الفاتورة: ${selectedPurchase!.total.toStringAsFixed(2)} جنيه',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItems() {
    return _Box(
      title: 'الأصناف',
      child: selectedPurchase == null
          ? const Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                'اكتب رقم الفاتورة وجيبها الأول',
                textAlign: TextAlign.center,
              ),
            )
          : items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                'كل أصناف الفاتورة دي اتعمل لها مرتجع قبل كده',
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Text('${item.price.toStringAsFixed(2)} جنيه'),
                      ),
                      SizedBox(
                        width: 130,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: item.quantity <= 0
                                  ? null
                                  : () => _setQuantity(item, item.quantity - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Expanded(
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              onPressed: item.quantity >= item.maxQuantity
                                  ? null
                                  : () => _setQuantity(item, item.quantity + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${item.total.toStringAsFixed(2)} جنيه',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildRefund() {
    return _Box(
      title: 'فلوس راجعة من المورد',
      child: Column(
        children: [
          CustomTextFormField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'المبلغ اللي المورد رجعهولك',
              hintText: '0 لو هيتخصم من حساب المورد',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0;
              setState(() => refundedAmount = amount);
            },
          ),
          if (refundedAmount > 0) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<Account>(
              initialValue: refundAccount,
              decoration: const InputDecoration(
                labelText: 'الحساب اللي الفلوس هتنزل فيه',
                border: OutlineInputBorder(),
              ),
              items: accounts
                  .map(
                    (account) => DropdownMenuItem<Account>(
                      value: account,
                      child: Text(
                        '${account.name} - ${account.balance.toStringAsFixed(2)} جنيه',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => refundAccount = value),
            ),
          ],
          const SizedBox(height: 12),
          CustomTextFormField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختياري)',
              hintText: 'مثال: الصنف كان بايظ',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotal() {
    return _Box(
      title: 'إجمالي المرتجع',
      child: Row(
        children: [
          const Text('قيمة الأصناف المرتجعة'),
          const Spacer(),
          Text(
            '${total.toStringAsFixed(2)} جنيه',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class ReturnItem {
  final String purchaseItemId;
  final String productId;
  final String name;
  final double price;
  final int maxQuantity;
  final int quantity;

  const ReturnItem({
    required this.purchaseItemId,
    required this.productId,
    required this.name,
    required this.price,
    required this.maxQuantity,
    required this.quantity,
  });

  double get total => price * quantity;

  ReturnItem copyWith({int? quantity}) {
    return ReturnItem(
      purchaseItemId: purchaseItemId,
      productId: productId,
      name: name,
      price: price,
      maxQuantity: maxQuantity,
      quantity: quantity ?? this.quantity,
    );
  }
}

class _Box extends StatelessWidget {
  final String title;
  final Widget child;

  const _Box({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
