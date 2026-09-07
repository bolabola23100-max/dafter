import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/purchase_item.dart';
import 'package:dafter/features/model/supplier.dart';
import 'package:dafter/features/purchases/service/purchase_service.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';

import 'package:flutter/material.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  State<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen> {
  final SupplierRepository _supplierRepository = SupplierRepository();
  final ProductRepository _productRepository = ProductRepository();
  final AccountRepository _accountRepository = AccountRepository();
  final PurchaseService _purchaseService = PurchaseService();

  final paidController = TextEditingController();

  Supplier? selectedSupplier;
  Account? selectedAccount;

  final List<_PurchaseLine> items = [];

  String paymentType = 'نقدي';

  bool _isSaving = false;

  double get total {
    return items.fold(0, (sum, item) => sum + item.total);
  }

  double get paid {
    return double.tryParse(paidController.text.trim()) ?? 0;
  }

  double get remaining {
    final value = total - paid;
    return value < 0 ? 0 : value;
  }

  @override
  void dispose() {
    paidController.dispose();
    super.dispose();
  }

  // ============================================================
  // Supplier
  // ============================================================

  Future<void> selectSupplier() async {
    final suppliers = await _supplierRepository.getSuppliers();

    if (!mounted) return;

    if (suppliers.isEmpty) {
      _message('لا يوجد موردين. أضف مورد أولاً.');
      return;
    }

    final supplier = await showDialog<Supplier>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختيار المورد'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: ListView.separated(
              itemCount: suppliers.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final supplier = suppliers[index];

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.store_outlined),
                  ),
                  title: Text(
                    supplier.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(supplier.phone ?? 'بدون رقم هاتف'),
                  trailing: Text(
                    '${supplier.balance.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      color: supplier.balance > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context, supplier);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );

    if (supplier == null) return;

    setState(() {
      selectedSupplier = supplier;
    });
  }

  // ============================================================
  // Account
  // ============================================================

  Future<void> selectAccount() async {
    final accounts = await _accountRepository.getAccounts();

    if (!mounted) return;

    if (accounts.isEmpty) {
      _message('لا يوجد حسابات. أضف حساب أولاً.');
      return;
    }

    final account = await showDialog<Account>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختيار الحساب'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final account = accounts[index];

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  title: Text(
                    account.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_accountTypeName(account.type)),
                  trailing: Text(
                    '${account.balance.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context, account);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );

    if (account == null) return;

    setState(() {
      selectedAccount = account;
    });
  }

  String _accountTypeName(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'خزنة';
      case AccountType.bank:
        return 'بنك';
      case AccountType.expense:
        return 'مصروفات';
      case AccountType.income:
        return 'إيرادات';
      case AccountType.other:
        return 'أخرى';
    }
  }

  // ============================================================
  // Product
  // ============================================================

  Future<void> addItem() async {
    final products = await _productRepository.getProducts();

    if (!mounted) return;

    if (products.isEmpty) {
      _message('لا يوجد منتجات. أضف منتج أولاً.');
      return;
    }

    final product = await showDialog<Product>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختيار المنتج'),
          content: SizedBox(
            width: 550,
            height: 450,
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = products[index];

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.inventory_2_outlined),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    product.barcode == null
                        ? 'بدون باركود'
                        : 'باركود: ${product.barcode}',
                  ),
                  trailing: Text(
                    '${product.purchasePrice.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context, product);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );

    if (product == null) return;

    if (!mounted) return;

    final line = await showDialog<_PurchaseLine>(
      context: context,
      builder: (_) => _AddProductDialog(product: product),
    );

    if (line == null) return;

    setState(() {
      final existingIndex = items.indexWhere(
        (item) => item.product.id == line.product.id,
      );

      if (existingIndex != -1) {
        items[existingIndex].quantity += line.quantity;
        items[existingIndex].price = line.price;
      } else {
        items.add(line);
      }

      _updatePaidForPaymentType();
    });
  }

  // ============================================================
  // Payment
  // ============================================================

  void _updatePaidForPaymentType() {
    if (paymentType == 'نقدي') {
      paidController.text = total.toStringAsFixed(2);
    } else if (paymentType == 'آجل') {
      paidController.text = '0';
    }
  }

  void onPaymentTypeChanged(String? value) {
    if (value == null) return;

    setState(() {
      paymentType = value;

      if (value == 'نقدي') {
        paidController.text = total.toStringAsFixed(2);
      } else if (value == 'آجل') {
        paidController.text = '0';
      } else {
        paidController.clear();
      }
    });
  }

  // ============================================================
  // Delete item
  // ============================================================

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);

      if (paymentType == 'نقدي') {
        paidController.text = total.toStringAsFixed(2);
      }
    });
  }

  // ============================================================
  // Save
  // ============================================================

  Future<void> saveInvoice() async {
    if (_isSaving) return;

    if (selectedSupplier == null) {
      _message('من فضلك اختر المورد');
      return;
    }

    if (items.isEmpty) {
      _message('أضف صنف واحد على الأقل');
      return;
    }

    if (paid < 0) {
      _message('المبلغ المدفوع غير صحيح');
      return;
    }

    if (paid > total) {
      _message('المبلغ المدفوع أكبر من إجمالي الفاتورة');
      return;
    }

    if (paid > 0 && selectedAccount == null) {
      _message('من فضلك اختر الحساب الذي تم الدفع منه');
      return;
    }

    if (paid > 0 &&
        selectedAccount != null &&
        selectedAccount!.balance < paid) {
      _message('رصيد الحساب غير كافٍ');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final purchaseId = DateTime.now().microsecondsSinceEpoch.toString();

      final purchaseItems = <PurchaseItem>[];

      for (int i = 0; i < items.length; i++) {
        final item = items[i];

        purchaseItems.add(
          PurchaseItem(
            id: '${purchaseId}_$i',
            purchaseId: purchaseId,
            productId: item.product.id,
            quantity: item.quantity,
            price: item.price,
            discount: item.discount,
          ),
        );
      }

      final purchase = Purchase(
        id: purchaseId,
        supplierId: selectedSupplier!.id,
        date: DateTime.now(),
        items: purchaseItems,
        discount: 0,
        paidAmount: paid,
      );

      await _purchaseService.createPurchase(
        purchase: purchase,
        accountId: selectedAccount?.id,
      );

      if (!mounted) return;

      _message('تم حفظ فاتورة الشراء بنجاح');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // Message
  // ============================================================

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text('فاتورة شراء جديدة'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSupplier(),

            const SizedBox(height: 16),

            _buildItems(),

            const SizedBox(height: 16),

            _buildPayment(),

            const SizedBox(height: 20),

            _buildSummary(),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _isSaving ? null : saveInvoice,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الفاتورة'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Supplier UI
  // ============================================================

  Widget _buildSupplier() {
    return _Card(
      title: 'بيانات المورد',
      child: InkWell(
        onTap: selectSupplier,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'المورد',
            prefixIcon: const Icon(Icons.store_outlined),
            suffixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            selectedSupplier?.name ?? 'اختر المورد',
            style: TextStyle(
              color: selectedSupplier == null ? Colors.grey : Colors.black,
              fontWeight: selectedSupplier == null
                  ? FontWeight.normal
                  : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Items UI
  // ============================================================

  Widget _buildItems() {
    return _Card(
      title: 'أصناف الفاتورة',
      action: ElevatedButton.icon(
        onPressed: addItem,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('إضافة صنف'),
      ),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(35),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 45,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'لم تتم إضافة أصناف',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'اضغط على إضافة صنف لإضافة المنتجات',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.quantity} × '
                    '${item.price.toStringAsFixed(2)} ج.م',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.total.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          removeItem(index);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ============================================================
  // Payment UI
  // ============================================================

  Widget _buildPayment() {
    return _Card(
      title: 'طريقة الدفع',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: paymentType,
            decoration: InputDecoration(
              labelText: 'طريقة الدفع',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'نقدي', child: Text('نقدي')),
              DropdownMenuItem(value: 'آجل', child: Text('آجل')),
              DropdownMenuItem(value: 'جزئي', child: Text('جزئي')),
            ],
            onChanged: onPaymentTypeChanged,
          ),

          const SizedBox(height: 14),

          if (paid > 0 || paymentType != 'آجل') ...[
            InkWell(
              onTap: selectAccount,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'الحساب',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  selectedAccount?.name ?? 'اختر الحساب',
                  style: TextStyle(
                    color: selectedAccount == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),
          ],

          CustomTextFormField(
            controller: paidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'المبلغ المدفوع',
              suffixText: 'ج.م',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Summary
  // ============================================================

  Widget _buildSummary() {
    return _Card(
      title: 'ملخص الفاتورة',
      child: Column(
        children: [
          _SummaryRow(
            title: 'الإجمالي',
            value: '${total.toStringAsFixed(2)} ج.م',
          ),
          _SummaryRow(
            title: 'المدفوع',
            value: '${paid.toStringAsFixed(2)} ج.م',
          ),
          const Divider(),
          _SummaryRow(
            title: 'المتبقي',
            value: '${remaining.toStringAsFixed(2)} ج.م',
            bold: true,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// Purchase Line
// ================================================================

class _PurchaseLine {
  final Product product;

  int quantity;
  double price;
  double discount;

  _PurchaseLine({
    required this.product,
    required this.quantity,
    required this.price,
    this.discount = 0,
  });

  double get total {
    return (quantity * price) - discount;
  }
}

// ================================================================
// Add Product Dialog
// ================================================================

class _AddProductDialog extends StatefulWidget {
  final Product product;

  const _AddProductDialog({required this.product});

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  late final TextEditingController priceController;
  final quantityController = TextEditingController(text: '1');
  final discountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();

    priceController = TextEditingController(
      text: widget.product.purchasePrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    priceController.dispose();
    quantityController.dispose();
    discountController.dispose();

    super.dispose();
  }

  void add() {
    final price = double.tryParse(priceController.text.trim());

    final quantity = int.tryParse(quantityController.text.trim());

    final discount = double.tryParse(discountController.text.trim()) ?? 0;

    if (price == null || price < 0) {
      _message('أدخل سعر شراء صحيح');
      return;
    }

    if (quantity == null || quantity <= 0) {
      _message('أدخل كمية صحيحة');
      return;
    }

    if (discount < 0) {
      _message('الخصم غير صحيح');
      return;
    }

    final subtotal = price * quantity;

    if (discount > subtotal) {
      _message('الخصم أكبر من قيمة الصنف');
      return;
    }

    Navigator.pop(
      context,
      _PurchaseLine(
        product: widget.product,
        quantity: quantity,
        price: price,
        discount: discount,
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة ${widget.product.name}'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'سعر الشراء',
                suffixText: 'ج.م',
              ),
            ),

            const SizedBox(height: 12),

            CustomTextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية'),
            ),

            const SizedBox(height: 12),

            CustomTextFormField(
              controller: discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'الخصم',
                suffixText: 'ج.م',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(onPressed: add, child: const Text('إضافة')),
      ],
    );
  }
}

// ================================================================
// Card
// ================================================================

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _Card({required this.title, required this.child, this.action});

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
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (action != null) action!,
            ],
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }
}

// ================================================================
// Summary Row
// ================================================================

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(title),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
