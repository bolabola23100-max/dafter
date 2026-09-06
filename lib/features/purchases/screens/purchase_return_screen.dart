import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class PurchaseReturnScreen extends StatefulWidget {
  const PurchaseReturnScreen({super.key});

  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen> {
  final invoiceController = TextEditingController();
  final supplierController = TextEditingController();

  final List<ReturnItem> items = [];

  double get total => items.fold(0, (sum, item) => sum + item.total);

  @override
  void dispose() {
    invoiceController.dispose();
    supplierController.dispose();
    super.dispose();
  }

  void addItem() {
    showDialog(
      context: context,
      builder: (_) => _ReturnItemDialog(
        onAdd: (item) {
          setState(() => items.add(item));
        },
      ),
    );
  }

  void saveReturn() {
    if (invoiceController.text.trim().isEmpty) {
      _message('اكتب رقم فاتورة الشراء');
      return;
    }
    if (items.isEmpty) {
      _message('ضيف الأصناف المرتجعة');
      return;
    }

    _message('تم تسجيل المرتجع بنجاح');
    Navigator.pop(context, true);
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
              _buildTotal(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: saveReturn,
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('تسجيل المرتجع'),
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
      title: 'بيانات الفاتورة',
      child: Column(
        children: [
          CustomTextFormField(
            controller: invoiceController,
            decoration: InputDecoration(
              labelText: 'رقم فاتورة الشراء',
              hintText: 'مثال: 1025',
              prefixIcon: const Icon(Icons.receipt_long_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          CustomTextFormField(
            controller: supplierController,
            decoration: InputDecoration(
              labelText: 'المورد',
              prefixIcon: const Icon(Icons.store_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItems() {
    return _Box(
      title: 'الأصناف المرتجعة',
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
                  Icon(Icons.assignment_return_outlined, size: 45),
                  SizedBox(height: 10),
                  Text('لسه مفيش أصناف مرتجعة'),
                ],
              ),
            )
          : Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.quantity} × ${item.price.toStringAsFixed(2)} جنيه',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.total.toStringAsFixed(2)} جنيه',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => setState(() => items.removeAt(index)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTotal() {
    return _Box(
      title: 'إجمالي المرتجع',
      child: Row(
        children: [
          const Text('قيمة المرتجع'),
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
  final String name;
  final double price;
  final int quantity;

  const ReturnItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}

class _ReturnItemDialog extends StatefulWidget {
  final void Function(ReturnItem item) onAdd;

  const _ReturnItemDialog({required this.onAdd});

  @override
  State<_ReturnItemDialog> createState() => _ReturnItemDialogState();
}

class _ReturnItemDialogState extends State<_ReturnItemDialog> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  void add() {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    final quantity = int.tryParse(quantityController.text.trim());

    if (name.isEmpty || price == null || price < 0 || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('راجع اسم الصنف والسعر والكمية')),
      );
      return;
    }

    widget.onAdd(
      ReturnItem(name: name, price: price, quantity: quantity),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة صنف للمرتجع'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الصنف'),
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'السعر'),
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية'),
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

class _Box extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _Box({required this.title, required this.child, this.action});

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
