import 'package:dafter/features/Products/widgets/stock_status_badge.dart';
import 'package:dafter/features/model/category.dart';
import 'package:dafter/features/model/product.dart';
import 'package:flutter/material.dart';

class ProductsTable extends StatelessWidget {
  final List<Product> products;
  final List<Category> categories;

  final void Function(Product) onEditProduct;
  final void Function(Product)? onDeleteProduct;

  const ProductsTable({
    super.key,
    required this.products,
    required this.categories,
    required this.onEditProduct,
    this.onDeleteProduct,
  });

  // =========================================================
  // Get Category Name
  // =========================================================

  String _getCategoryName(Product product) {
    if (product.categoryId == null) {
      return '-';
    }

    for (final category in categories) {
      if (category.id == product.categoryId) {
        return category.name;
      }
    }

    return '-';
  }

  // =========================================================
  // Stock Status
  // =========================================================

  StockStatus _getStockStatus(Product product) {
    if (product.quantity == 0) {
      return StockStatus.outOfStock;
    }

    if (product.quantity <= product.minQuantity) {
      return StockStatus.low;
    }

    return StockStatus.available;
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('المنتج')),
            DataColumn(label: Text('الباركود')),
            DataColumn(label: Text('التصنيف')),
            DataColumn(label: Text('سعر الشراء')),
            DataColumn(label: Text('سعر البيع')),
            DataColumn(label: Text('الكمية')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: products.map((product) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),

                DataCell(
                  Text(
                    product.barcode?.trim().isNotEmpty == true
                        ? product.barcode!
                        : '-',
                  ),
                ),

                DataCell(Text(_getCategoryName(product))),

                DataCell(
                  Text('${product.purchasePrice.toStringAsFixed(2)} ج.م'),
                ),

                DataCell(
                  Text('${product.sellingPrice.toStringAsFixed(2)} ج.م'),
                ),

                DataCell(Text('${product.quantity}')),

                DataCell(StockStatusBadge(status: _getStockStatus(product))),

                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'تعديل',
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () {
                          onEditProduct(product);
                        },
                      ),

                      IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: onDeleteProduct == null
                            ? null
                            : () {
                                onDeleteProduct!(product);
                              },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
