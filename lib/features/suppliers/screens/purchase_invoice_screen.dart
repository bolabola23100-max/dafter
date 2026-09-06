import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  State<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen> {
  String? selectedSupplier;
  String paymentMethod = 'آجل';

  final List<PurchaseItem> items = [
    PurchaseItem(product: 'سلسلة ستانلس', quantity: 10, price: 80),
    PurchaseItem(product: 'أسورة إكسسوار', quantity: 5, price: 60),
  ];

  double get subtotal {
    return items.fold(0, (sum, item) => sum + item.total);
  }

  double discount = 0;

  double get total => subtotal - discount;

  double paid = 0;

  double get remaining => total - paid;

  void addItem() {
    setState(() {
      items.add(PurchaseItem(product: 'منتج جديد', quantity: 1, price: 0));
    });
  }

  void saveInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ فاتورة الشراء بنجاح'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'فاتورة شراء جديدة',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInvoiceInfo(),

            const SizedBox(height: 16),

            _buildProducts(),

            const SizedBox(height: 16),

            _buildPayment(),

            const SizedBox(height: 20),

            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return _Card(
      child: Row(
        children: [
          Expanded(
            child: _Dropdown(
              label: 'المورد',
              value: selectedSupplier,
              hint: 'اختر المورد',
              items: const ['شركة النور', 'أحمد للإكسسوارات', 'مؤسسة الأمل'],
              onChanged: (value) {
                setState(() {
                  selectedSupplier = value;
                });
              },
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: CustomTextFormField(
              decoration: _decoration(label: 'رقم الفاتورة', hint: '#1026'),
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: CustomTextFormField(
              decoration: _decoration(
                label: 'التاريخ',
                hint: '30/08/2026',
                suffix: Icons.calendar_today_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducts() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'المنتجات',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة منتج'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF7F8F9),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('المنتج')),
                Expanded(child: Text('الكمية')),
                Expanded(child: Text('السعر')),
                Expanded(child: Text('الإجمالي')),
                SizedBox(width: 45),
              ],
            ),
          ),

          ...List.generate(
            items.length,
            (index) => _ProductRow(
              item: items[index],
              onDelete: () {
                setState(() {
                  items.removeAt(index);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayment() {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'طريقة الدفع',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PaymentButton(
                      title: 'نقدي',
                      selected: paymentMethod == 'نقدي',
                      onTap: () {
                        setState(() {
                          paymentMethod = 'نقدي';
                        });
                      },
                    ),
                    _PaymentButton(
                      title: 'آجل',
                      selected: paymentMethod == 'آجل',
                      onTap: () {
                        setState(() {
                          paymentMethod = 'آجل';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(
            width: 320,
            child: Column(
              children: [
                _TotalRow(
                  title: 'الإجمالي',
                  value: '${subtotal.toStringAsFixed(2)} ج.م',
                ),
                _TotalRow(
                  title: 'الخصم',
                  value: '${discount.toStringAsFixed(2)} ج.م',
                ),
                const Divider(),
                _TotalRow(
                  title: 'الإجمالي النهائي',
                  value: '${total.toStringAsFixed(2)} ج.م',
                  bold: true,
                ),
                _TotalRow(
                  title: 'المدفوع',
                  value: '${paid.toStringAsFixed(2)} ج.م',
                ),
                _TotalRow(
                  title: 'المتبقي',
                  value: '${remaining.toStringAsFixed(2)} ج.م',
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: saveInvoice,
          icon: const Icon(Icons.check),
          label: const Text('حفظ الفاتورة'),
        ),
      ],
    );
  }

  InputDecoration _decoration({String? label, String? hint, IconData? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix == null ? null : Icon(suffix, size: 18),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: child,
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ProductRow extends StatelessWidget {
  final PurchaseItem item;
  final VoidCallback onDelete;

  const _ProductRow({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F1F2))),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item.product)),
          Expanded(child: Text('${item.quantity}')),
          Expanded(child: Text('${item.price.toStringAsFixed(2)} ج.م')),
          Expanded(
            child: Text(
              '${item.total.toStringAsFixed(2)} ج.م',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 45,
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFDDEDEC) : Colors.white,
          side: BorderSide(
            color: selected ? const Color(0xFF0E4C4C) : const Color(0xFFE5E9EB),
          ),
        ),
        child: Text(title),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String title;
  final String value;
  final bool bold;

  const _TotalRow({
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class PurchaseItem {
  String product;
  int quantity;
  double price;

  PurchaseItem({
    required this.product,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}
