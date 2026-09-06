import 'package:dafter/features/Products/repo/category_repository.dart';
import 'package:dafter/features/model/category.dart';

class CategoryService {
  final CategoryRepository _repository;

  CategoryService({CategoryRepository? repository})
    : _repository = repository ?? CategoryRepository();

  // =========================================================
  // Add Category
  // =========================================================

  Future<void> addCategory(Category category) async {
    final name = category.name.trim();

    if (name.isEmpty) {
      throw Exception('اسم التصنيف مطلوب');
    }

    final existingCategory = await _repository.getCategoryByName(name);

    if (existingCategory != null) {
      throw Exception('التصنيف موجود بالفعل');
    }

    final newCategory = Category(id: category.id, name: name);

    await _repository.addCategory(newCategory);
  }

  // =========================================================
  // Get All Categories
  // =========================================================

  Future<List<Category>> getCategories() {
    return _repository.getCategories();
  }

  // =========================================================
  // Get Category By ID
  // =========================================================

  Future<Category?> getCategoryById(String id) {
    return _repository.getCategoryById(id);
  }

  // =========================================================
  // Get Category By Name
  // =========================================================

  Future<Category?> getCategoryByName(String name) {
    return _repository.getCategoryByName(name);
  }

  // =========================================================
  // Search Categories
  // =========================================================

  Future<List<Category>> searchCategories(String query) {
    return _repository.searchCategories(query);
  }

  // =========================================================
  // Update Category
  // =========================================================

  Future<void> updateCategory(Category category) async {
    final name = category.name.trim();

    if (name.isEmpty) {
      throw Exception('اسم التصنيف مطلوب');
    }

    final existingCategory = await _repository.getCategoryByName(name);

    if (existingCategory != null && existingCategory.id != category.id) {
      throw Exception('التصنيف موجود بالفعل');
    }

    final updatedCategory = Category(id: category.id, name: name);

    await _repository.updateCategory(updatedCategory);
  }

  // =========================================================
  // Delete Category
  // =========================================================

  Future<void> deleteCategory(String id) {
    return _repository.deleteCategory(id);
  }
}
