import 'package:flutter/material.dart';

import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/Products/services/product_service.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/Inventory/services/stock_movement_service.dart';

class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen> {
  final ProductService _productService = ProductService();
  final StockMovementService _stockMovementService = StockMovementService();

  List<Product> _products = [];

  final Map<String, TextEditingController> _quantityControllers = {};

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // =========================================================
  // Load Products
  // =========================================================

  Future<void> _loadProducts() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final products = await _productService.getProducts();

      if (!mounted) return;

      for (final controller in _quantityControllers.values) {
        controller.dispose();
      }

      _quantityControllers.clear();

      for (final product in products) {
        _quantityControllers[product.id] = TextEditingController(
          text: product.quantity.toString(),
        );
      }

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'حدث خطأ أثناء تحميل المنتجات: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  // =========================================================
  // Save Inventory
  // =========================================================

  Future<void> _saveInventory() async {
    if (_products.isEmpty) {
      _showMessage('لا توجد منتجات للجرد');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final actualQuantities = <String, int>{};

      int adjustedProducts = 0;

      for (final product in _products) {
        final controller = _quantityControllers[product.id];

        if (controller == null) {
          continue;
        }

        final actualQuantity = int.tryParse(controller.text.trim());

        if (actualQuantity == null) {
          throw Exception(
            'الكمية الفعلية للمنتج '
            '"${product.name}" غير صحيحة',
          );
        }

        if (actualQuantity < 0) {
          throw Exception(
            'الكمية الفعلية للمنتج '
            '"${product.name}" لا يمكن أن تكون سالبة',
          );
        }

        actualQuantities[product.id] = actualQuantity;

        if (actualQuantity != product.quantity) {
          adjustedProducts++;
        }
      }

      // =====================================================
      // Save everything in ONE transaction
      // =====================================================

      await _stockMovementService.adjustInventory(
        actualQuantities: actualQuantities,
        notes: 'جرد المخزون',
      );

      if (!mounted) return;

      await _loadProducts();

      if (!mounted) return;

      _showMessage(
        adjustedProducts == 0
            ? 'لم يتم تعديل أي كمية'
            : 'تم حفظ الجرد بنجاح '
                  'لـ $adjustedProducts منتج',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'حدث خطأ أثناء حفظ الجرد: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =========================================================
  // Message
  // =========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // =========================================================
  // Difference
  // =========================================================

  int _getDifference(Product product) {
    final controller = _quantityControllers[product.id];

    if (controller == null) {
      return 0;
    }

    final actual = int.tryParse(controller.text.trim());

    if (actual == null) {
      return 0;
    }

    return actual - product.quantity;
  }

  // =========================================================
  // Difference Text
  // =========================================================

  Widget _buildDifference(Product product) {
    final difference = _getDifference(product);

    if (difference == 0) {
      return const Text('لا يوجد فرق', style: TextStyle(color: Colors.grey));
    }

    if (difference > 0) {
      return Text(
        '+$difference',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Text(
      '$difference',
      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    );
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جرد المخزون'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Nav.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد منتجات للجرد',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : Column(
                children: [
                  // =================================================
                  // Header
                  // =================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E9EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 28),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'جرد المخزون',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 4),

                              Text(
                                'راجع الكميات الفعلية '
                                'وعدّل أي فروق',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          '${_products.length} منتج',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // Table
                  // =================================================
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E9EB)),
                      ),
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 35,
                          headingRowHeight: 52,
                          columns: const [
                            DataColumn(label: Text('المنتج')),
                            DataColumn(label: Text('الكمية المسجلة')),
                            DataColumn(label: Text('الكمية الفعلية')),
                            DataColumn(label: Text('الفرق')),
                          ],
                          rows: _products.map((product) {
                            final controller =
                                _quantityControllers[product.id]!;

                            return DataRow(
                              cells: [
                                DataCell(Text(product.name)),

                                DataCell(Text(product.quantity.toString())),

                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (_) {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ),

                                DataCell(_buildDifference(product)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // Save Button
                  // =================================================
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveInventory,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الجرد'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
