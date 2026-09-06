import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/Inventory/screens/inventory_count_screen.dart';

import 'package:dafter/features/Products/screens/add_product_screen.dart';
import 'package:dafter/features/Products/screens/categories_screen.dart';
import 'package:dafter/features/Products/services/category_service.dart';
import 'package:dafter/features/Products/services/product_service.dart';
import 'package:dafter/features/Products/widgets/products_filter_bar.dart';
import 'package:dafter/features/Products/widgets/products_summary_row.dart';
import 'package:dafter/features/Products/widgets/products_table.dart';
import 'package:dafter/features/Products/widgets/stock_status_badge.dart';
import 'package:dafter/features/model/category.dart';
import 'package:dafter/features/model/product.dart';
import 'package:flutter/material.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  List<Product> _products = [];
  List<Category> _categories = [];

  String? selectedCategoryFilter;
  String? selectedStatusFilter;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =========================================================
  // Load Data
  // =========================================================

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final results = await Future.wait([
        _productService.getProducts(),
        _categoryService.getCategories(),
      ]);

      if (!mounted) return;

      final products = results[0] as List<Product>;
      final categories = results[1] as List<Category>;

      // لو التصنيف اللي كان متحدد اتحذف،
      // نلغي الفلتر بدل ما يفضل متعلق بـ ID مش موجود.
      if (selectedCategoryFilter != null &&
          !categories.any(
            (category) => category.id == selectedCategoryFilter,
          )) {
        selectedCategoryFilter = null;
      }

      setState(() {
        _products = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء تحميل البيانات: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // =========================================================
  // Stock Status
  // =========================================================

  StockStatus _getStockStatus(Product product) {
    if (product.quantity <= 0) {
      return StockStatus.outOfStock;
    }

    if (product.quantity <= product.minQuantity) {
      return StockStatus.low;
    }

    return StockStatus.available;
  }

  // =========================================================
  // Summary
  // =========================================================

  int get _totalProducts {
    return _products.length;
  }

  int get _lowStockCount {
    return _products.where((product) {
      return _getStockStatus(product) == StockStatus.low;
    }).length;
  }

  int get _outOfStockCount {
    return _products.where((product) {
      return _getStockStatus(product) == StockStatus.outOfStock;
    }).length;
  }

  // =========================================================
  // Filtered Products
  // =========================================================

  List<Product> get _filteredProducts {
    return _products.where((product) {
      // -----------------------------------------
      // Category Filter
      // -----------------------------------------

      final matchesCategory =
          selectedCategoryFilter == null ||
          product.categoryId == selectedCategoryFilter;

      // -----------------------------------------
      // Stock Status Filter
      // -----------------------------------------

      final matchesStatus =
          selectedStatusFilter == null ||
          _getStockStatus(product).name == selectedStatusFilter;

      return matchesCategory && matchesStatus;
    }).toList();
  }

  // =========================================================
  // Delete Product
  // =========================================================

  Future<void> _deleteProduct(Product product) async {
    try {
      await _productService.deleteProduct(product.id);

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم حذف ${product.name}')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء حذف المنتج: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // =========================================================
  // Add Product
  // =========================================================

  Future<void> _addProduct() async {
    final result = await Nav.push(context, const AddProductScreen());

    if (!mounted) return;

    if (result == true) {
      await _loadData();
    }
  }

  // =========================================================
  // Edit Product
  // =========================================================

  Future<void> _editProduct(Product product) async {
    final result = await Nav.push(
      context,
      AddProductScreen(productToEdit: product),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadData();
    }
  }

  // =========================================================
  // Open Categories
  // =========================================================

  Future<void> _openCategories() async {
    await Nav.push(context, const CategoriesScreen());

    if (!mounted) return;

    // بعد ما نرجع من التصنيفات،
    // نعيد تحميل المنتجات والتصنيفات.
    await _loadData();
  }

  // =========================================================
  // Reset Filters
  // =========================================================

  void _resetFilters() {
    setState(() {
      selectedCategoryFilter = null;
      selectedStatusFilter = null;
    });
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================================================
          // Action Buttons
          // =========================================================
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.inventory_outlined,
                  label: 'جرد المخزون',
                  primary: false,
                  onTap: () async {
                    await Nav.push(context, const InventoryCountScreen());

                    if (!mounted) return;

                    await _loadData();
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ActionButton(
                  icon: Icons.category_outlined,
                  label: 'التصنيفات',
                  primary: false,
                  onTap: _openCategories,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ActionButton(
                  icon: Icons.download_outlined,
                  label: 'تصدير',
                  primary: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تصدير المنتجات — قريبًا')),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ActionButton(
                  icon: Icons.add_box_outlined,
                  label: 'إضافة منتج',
                  primary: true,
                  onTap: _addProduct,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // =========================================================
          // Summary Cards
          // =========================================================
          ProductsSummaryRow(
            totalProducts: _totalProducts,
            lowStockCount: _lowStockCount,
            outOfStockCount: _outOfStockCount,
          ),

          const SizedBox(height: 20),

          // =========================================================
          // Filters Bar
          // =========================================================
          ProductsFilterBar(
            categories: _categories,
            selectedCategory: selectedCategoryFilter,
            selectedStatus: selectedStatusFilter,
            onCategoryChanged: (value) {
              setState(() {
                selectedCategoryFilter = value;
              });
            },
            onStatusChanged: (value) {
              setState(() {
                selectedStatusFilter = value;
              });
            },
            onReset: _resetFilters,
          ),

          const SizedBox(height: 16),

          // =========================================================
          // Products Table
          // =========================================================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ProductsTable(
                    products: _filteredProducts,
                    categories: _categories,
                    onEditProduct: _editProduct,
                    onDeleteProduct: _deleteProduct,
                  ),
          ),
        ],
      ),
    );
  }
}
