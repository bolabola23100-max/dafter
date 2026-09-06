import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/model/product.dart';
import 'package:flutter/material.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final ProductRepository _productRepository = ProductRepository();
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<List<Product>> _loadLowStockProducts() async {
    final products = await _productRepository.getProducts();
    return products.where((product) => product.quantity <= product.minQuantity).toList();
  }

  Future<void> _loadNotifications() async {
    try {
      final products = await _loadLowStockProducts();
      if (mounted) setState(() => _notificationCount = products.length);
    } catch (_) {
      if (mounted) setState(() => _notificationCount = 0);
    }
  }

  Future<void> _showNotifications() async {
    final products = await _loadLowStockProducts();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (products.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(child: Text('مفيش إشعارات دلوقتي')),
          );
        }

        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: products.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.warning_amber_outlined)),
                title: Text('المخزون قليل: ${product.name}'),
                subtitle: Text('المتاح ${product.quantity} — الحد الأدنى ${product.minQuantity}'),
              );
            },
          ),
        );
      },
    );

    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text('dafter', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(width: 20),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: CustomTextFormField(
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'بحث سريع عن منتج، عميل، أو فاتورة...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF6F8F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _showNotifications,
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.grey[700],
                tooltip: 'الإشعارات',
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
