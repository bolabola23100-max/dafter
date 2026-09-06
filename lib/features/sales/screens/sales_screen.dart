import 'package:dafter/features/sales/model/cart_item.dart';
import 'package:dafter/features/sales/widgets/quick_products_selector.dart';
import 'package:dafter/features/sales/widgets/sales_cart_table.dart';
import 'package:dafter/features/sales/widgets/sales_summary_panel.dart';
import 'package:flutter/material.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _discountController = TextEditingController(text: '0');
  final _paidController = TextEditingController();

  String? selectedCustomer;
  String selectedPaymentMethod = 'نقدي';

  final List<CartItem> _cartItems = [
    CartItem(
      productName: 'شاحن جداري أنكر 20 واط',
      sku: 'ANK-20W-WHT',
      price: 45,
      quantity: 2,
    ),
    CartItem(
      productName: 'كيبل ايفون قماش 1.5 متر',
      sku: 'CBL-IP-PD-15',
      price: 25.5,
      quantity: 5,
    ),
  ];

  // منتجات وهمية تظهر كأزرار سريعة للإضافة - هتتربط بقاعدة البيانات بعدين
  final List<CartItem> _availableProducts = [
    CartItem(
      productName: 'شاحن جداري أنكر 20 واط',
      sku: 'ANK-20W-WHT',
      price: 45,
    ),
    CartItem(
      productName: 'كيبل ايفون قماش 1.5 متر',
      sku: 'CBL-IP-PD-15',
      price: 25.5,
    ),
    CartItem(
      productName: 'سماعة ايربودز برو الجيل الثاني',
      sku: 'APP-AP-PRO2',
      price: 899,
    ),
  ];

  @override
  void dispose() {
    _discountController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _tax => (_subtotal - _discount) * 0.15;
  double get _grandTotal => (_subtotal - _discount) + _tax;
  double get _paid => double.tryParse(_paidController.text) ?? 0;
  double get _change => _paid - _grandTotal;

  void _addProduct(CartItem product) {
    setState(() {
      final existing = _cartItems.where((item) => item.sku == product.sku);
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cartItems.add(
          CartItem(
            productName: product.productName,
            sku: product.sku,
            price: product.price,
          ),
        );
      }
    });
  }

  void _removeItem(int index) {
    setState(() => _cartItems.removeAt(index));
  }

  void _saveInvoice() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================================================
          // Summary & Payment Panel
          // =========================================================
          SizedBox(
            width: 280,
            child: SingleChildScrollView(
              child: SalesSummaryPanel(
                itemsCount: _cartItems.length,
                subtotal: _subtotal,
                discount: _discount,
                tax: _tax,
                grandTotal: _grandTotal,
                paid: _paid,
                change: _change,
                discountController: _discountController,
                paidController: _paidController,
                selectedPaymentMethod: selectedPaymentMethod,
                onPaymentMethodChanged: (method) =>
                    setState(() => selectedPaymentMethod = method),
                onSaveAndPrint: _saveInvoice,
                onSaveOnly: _saveInvoice,
                onValuesChanged: () => setState(() {}),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // =========================================================
          // Cart & Items Selection Section
          // =========================================================
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E9EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: 'العميل',
                      isDense: true,
                    ),
                    hint: const Text('عميل نقدي (افتراضي)'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('عميل نقدي')),
                      DropdownMenuItem(
                        value: 'c1',
                        child: Text('مؤسسة الأفق للتجارة'),
                      ),
                    ],
                    onChanged: (value) => setState(() => selectedCustomer = value),
                  ),

                  const SizedBox(height: 16),

                  QuickProductsSelector(
                    availableProducts: _availableProducts,
                    onProductSelected: _addProduct,
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: SalesCartTable(
                        cartItems: _cartItems,
                        onIncreaseQuantity: (index) =>
                            setState(() => _cartItems[index].quantity++),
                        onDecreaseQuantity: (index) => setState(() {
                          if (_cartItems[index].quantity > 1) {
                            _cartItems[index].quantity--;
                          }
                        }),
                        onRemoveItem: _removeItem,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
