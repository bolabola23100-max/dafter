import 'package:dafter/features/Products/services/category_service.dart';
import 'package:dafter/features/Products/services/product_service.dart';
import 'package:dafter/features/model/category.dart';
import 'package:dafter/features/model/product.dart';
import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const AddProductScreen({super.key, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();

  String? selectedCategory;
  String? selectedSupplier;

  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  bool enableWholesalePrices = false;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();

    final product = widget.productToEdit;

    if (product != null) {
      _nameController.text = product.name;
      _codeController.text = product.barcode ?? '';
      _purchasePriceController.text = product.purchasePrice.toString();
      _salePriceController.text = product.sellingPrice.toString();
      _quantityController.text = product.quantity.toString();
      _minStockController.text = product.minQuantity.toString();

      selectedCategory = product.categoryId;
    }

    _loadCategories();
  }

  // =========================================================
  // Load Categories
  // =========================================================

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
      });

      final categories = await _categoryService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;

        // لو المنتج اللي بنعدله كان مرتبط بتصنيف اتحذف
        if (selectedCategory != null &&
            !_categories.any((category) => category.id == selectedCategory)) {
          selectedCategory = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
      });

      _showMessage(
        'حدث خطأ أثناء تحميل التصنيفات: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  // =========================================================
  // Save Product
  // =========================================================

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final purchasePrice = double.tryParse(_purchasePriceController.text.trim());

    final sellingPrice = double.tryParse(_salePriceController.text.trim());

    final quantity = int.tryParse(_quantityController.text.trim());

    final minQuantity = int.tryParse(_minStockController.text.trim());

    if (purchasePrice == null || purchasePrice < 0) {
      _showMessage('سعر الشراء غير صحيح');
      return;
    }

    if (sellingPrice == null || sellingPrice < 0) {
      _showMessage('سعر البيع غير صحيح');
      return;
    }

    if (quantity == null || quantity < 0) {
      _showMessage('الكمية غير صحيحة');
      return;
    }

    if (minQuantity == null || minQuantity < 0) {
      _showMessage('الحد الأدنى للمخزون غير صحيح');
      return;
    }

    final product = Product(
      id:
          widget.productToEdit?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      barcode: _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim(),
      categoryId: selectedCategory,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      quantity: quantity,
      minQuantity: minQuantity,
    );

    try {
      if (_isEditing) {
        await _productService.updateProduct(product);
      } else {
        await _productService.addProduct(product);
      }

      if (!mounted) return;

      _showMessage(
        _isEditing ? 'تم تعديل المنتج بنجاح' : 'تم إضافة المنتج بنجاح',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        body: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBasicInfoCard(),

                          const SizedBox(height: 16),

                          _buildPricingCard(),

                          const SizedBox(height: 16),

                          _buildStockCard(),

                          const SizedBox(height: 16),

                          _buildBottomActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Header
  // =========================================================

  Widget _buildHeader() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E9EB))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 21),
          ),

          const SizedBox(width: 10),

          Text(
            _isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const Spacer(),

          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Basic Information
  // =========================================================

  Widget _buildBasicInfoCard() {
    return _SectionCard(
      title: 'بيانات المنتج',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildCustomTextFormField(
                  controller: _nameController,
                  label: 'اسم المنتج',
                  hint: 'مثال: سلسلة ستانلس',
                  required: true,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildCustomTextFormField(
                  controller: _codeController,
                  label: 'الباركود / كود المنتج',
                  hint: 'مثال: 10254',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildCategoryDropdown()),

              const SizedBox(width: 16),

              Expanded(
                child: _buildDropdown(
                  label: 'المورد',
                  value: selectedSupplier,
                  hint: 'اختر المورد',
                  items: const [],
                  onChanged: (value) {
                    setState(() {
                      selectedSupplier = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Category Dropdown
  // =========================================================

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedCategory,
      decoration: InputDecoration(
        labelText: 'التصنيف',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF0E4C4C), width: 1.5),
        ),
      ),
      hint: _isLoadingCategories
          ? const Text('جاري تحميل التصنيفات...')
          : const Text('اختر التصنيف'),
      items: _categories
          .map(
            (category) => DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            ),
          )
          .toList(),
      onChanged: _isLoadingCategories
          ? null
          : (value) {
              setState(() {
                selectedCategory = value;
              });
            },
    );
  }

  // =========================================================
  // Pricing
  // =========================================================

  Widget _buildPricingCard() {
    return _SectionCard(
      title: 'الأسعار',
      icon: Icons.sell_outlined,
      child: Row(
        children: [
          Expanded(
            child: _buildCustomTextFormField(
              controller: _purchasePriceController,
              label: 'سعر الشراء',
              hint: '0.00',
              suffix: 'ج.م',
              keyboardType: TextInputType.number,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: _buildCustomTextFormField(
              controller: _salePriceController,
              label: 'سعر البيع',
              hint: '0.00',
              suffix: 'ج.م',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Stock
  // =========================================================

  Widget _buildStockCard() {
    return _SectionCard(
      title: 'المخزون',
      icon: Icons.inventory_outlined,
      child: Row(
        children: [
          Expanded(
            child: _buildCustomTextFormField(
              controller: _quantityController,
              label: 'الكمية الحالية',
              hint: '0',
              suffix: 'قطعة',
              keyboardType: TextInputType.number,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: _buildCustomTextFormField(
              controller: _minStockController,
              label: 'الحد الأدنى للمخزون',
              hint: '5',
              suffix: 'قطعة',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Bottom Actions
  // =========================================================

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          child: const Text('إلغاء'),
        ),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: _saveProduct,
          icon: const Icon(Icons.check, size: 19),
          label: Text(_isEditing ? 'حفظ التعديلات' : 'حفظ المنتج'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Text Form Field
  // =========================================================

  Widget _buildCustomTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    String? suffix,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF0E4C4C), width: 1.5),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'هذا الحقل مطلوب';
              }

              return null;
            }
          : null,
    );
  }

  // =========================================================
  // Generic Dropdown
  // =========================================================

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
      ),
      hint: Text(hint),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// =========================================================
// Section Card
// =========================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: const Color(0xFF0E4C4C)),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }
}
