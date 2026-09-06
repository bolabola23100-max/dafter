import 'package:dafter/features/Products/services/category_service.dart';
import 'package:dafter/features/model/category.dart';
import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();

  List<Category> _categories = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // =========================================================
  // Load Categories
  // =========================================================

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final categories = await _categoryService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('حدث خطأ أثناء تحميل التصنيفات: $e');
    }
  }

  // =========================================================
  // Add Category
  // =========================================================

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة تصنيف'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'اسم التصنيف',
              hintText: 'مثال: سلاسل',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();

                if (name.isEmpty) {
                  return;
                }

                try {
                  final category = Category(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                  );

                  await _categoryService.addCategory(category);

                  if (!context.mounted) return;

                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == true) {
      await _loadCategories();
    }
  }

  // =========================================================
  // Edit Category
  // =========================================================

  Future<void> _showEditCategoryDialog(Category category) async {
    final controller = TextEditingController(text: category.name);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل التصنيف'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'اسم التصنيف'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();

                if (name.isEmpty) {
                  return;
                }

                try {
                  final updatedCategory = Category(id: category.id, name: name);

                  await _categoryService.updateCategory(updatedCategory);

                  if (!context.mounted) return;

                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('حفظ التعديل'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == true) {
      await _loadCategories();
    }
  }

  // =========================================================
  // Delete Category
  // =========================================================

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف التصنيف'),
          content: Text('هل أنت متأكد من حذف "${category.name}"؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _categoryService.deleteCategory(category.id);

      await _loadCategories();

      if (!mounted) return;

      _showMessage('تم حذف التصنيف بنجاح');
    } catch (e) {
      if (!mounted) return;

      _showMessage('حدث خطأ أثناء حذف التصنيف: $e');
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
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text('التصنيفات'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add),
              label: const Text('إضافة تصنيف'),
            ),
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(20), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد تصنيفات حتى الآن',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف أول تصنيف للبدء',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add),
              label: const Text('إضافة تصنيف'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final category = _categories[index];

          return ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.category_outlined,
                color: Color(0xFF0E4C4C),
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'تعديل',
                  onPressed: () {
                    _showEditCategoryDialog(category);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () {
                    _deleteCategory(category);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 19,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
