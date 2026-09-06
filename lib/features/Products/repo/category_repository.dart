import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/category.dart';

class CategoryRepository {
  final AppDatabase _database;

  CategoryRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  // =========================================================
  // Add Category
  // =========================================================

  Future<void> addCategory(Category category) async {
    final db = await _database.database;

    final now = DateTime.now().toIso8601String();

    await db.insert(DatabaseTables.categories, {
      'id': category.id,
      'name': category.name,
      'created_at': now,
      'updated_at': now,
    });
  }

  // =========================================================
  // Get All Categories
  // =========================================================

  Future<List<Category>> getCategories() async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.categories,
      orderBy: 'name ASC',
    );

    return result.map(_fromMap).toList();
  }

  // =========================================================
  // Get Category By ID
  // =========================================================

  Future<Category?> getCategoryById(String id) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.categories,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  // =========================================================
  // Get Category By Name
  // =========================================================

  Future<Category?> getCategoryByName(String name) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.categories,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  // =========================================================
  // Search Categories
  // =========================================================

  Future<List<Category>> searchCategories(String query) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.categories,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );

    return result.map(_fromMap).toList();
  }

  // =========================================================
  // Update Category
  // =========================================================

  Future<void> updateCategory(Category category) async {
    final db = await _database.database;

    await db.update(
      DatabaseTables.categories,
      {'name': category.name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // =========================================================
  // Delete Category
  // =========================================================

  Future<void> deleteCategory(String id) async {
    final db = await _database.database;

    await db.delete(
      DatabaseTables.categories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================
  // Convert Database Map → Category
  // =========================================================

  Category _fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'] as String, name: map['name'] as String);
  }
}
