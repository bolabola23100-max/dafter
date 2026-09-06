import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/model/product.dart';

class ProductService {
  final ProductRepository _repository;

  ProductService({ProductRepository? repository})
    : _repository = repository ?? ProductRepository();

  // =========================================================
  // Add Product
  // =========================================================

  Future<void> addProduct(Product product) async {
    // اسم المنتج
    if (product.name.trim().isEmpty) {
      throw Exception('اسم المنتج مطلوب');
    }

    // سعر الشراء
    if (product.purchasePrice < 0) {
      throw Exception('سعر الشراء غير صحيح');
    }

    // سعر البيع
    if (product.sellingPrice < 0) {
      throw Exception('سعر البيع غير صحيح');
    }

    // الكمية
    if (product.quantity < 0) {
      throw Exception('الكمية لا يمكن أن تكون سالبة');
    }

    // الحد الأدنى
    if (product.minQuantity < 0) {
      throw Exception('الحد الأدنى للمخزون غير صحيح');
    }

    // التأكد أن الباركود غير مستخدم
    if (product.barcode != null && product.barcode!.trim().isNotEmpty) {
      final existingProduct = await _repository.getProductByBarcode(
        product.barcode!.trim(),
      );

      if (existingProduct != null) {
        throw Exception('الباركود مستخدم بالفعل');
      }
    }

    await _repository.addProduct(product);
  }

  // =========================================================
  // Get Products
  // =========================================================

  Future<List<Product>> getProducts() {
    return _repository.getProducts();
  }

  // =========================================================
  // Get Product By ID
  // =========================================================

  Future<Product?> getProductById(String id) {
    return _repository.getProductById(id);
  }

  // =========================================================
  // Get Product By Barcode
  // =========================================================

  Future<Product?> getProductByBarcode(String barcode) {
    return _repository.getProductByBarcode(barcode);
  }

  // =========================================================
  // Search Products
  // =========================================================

  Future<List<Product>> searchProducts(String query) {
    return _repository.searchProducts(query);
  }

  // =========================================================
  // Update Product
  // =========================================================

  Future<void> updateProduct(Product product) async {
    if (product.name.trim().isEmpty) {
      throw Exception('اسم المنتج مطلوب');
    }

    if (product.purchasePrice < 0) {
      throw Exception('سعر الشراء غير صحيح');
    }

    if (product.sellingPrice < 0) {
      throw Exception('سعر البيع غير صحيح');
    }

    if (product.quantity < 0) {
      throw Exception('الكمية لا يمكن أن تكون سالبة');
    }

    if (product.minQuantity < 0) {
      throw Exception('الحد الأدنى للمخزون غير صحيح');
    }

    // لو الباركود موجود، نتأكد إنه مش مستخدم لمنتج تاني
    if (product.barcode != null && product.barcode!.trim().isNotEmpty) {
      final existingProduct = await _repository.getProductByBarcode(
        product.barcode!.trim(),
      );

      if (existingProduct != null && existingProduct.id != product.id) {
        throw Exception('الباركود مستخدم بالفعل');
      }
    }

    await _repository.updateProduct(product);
  }

  // =========================================================
  // Delete Product
  // =========================================================

  Future<void> deleteProduct(String id) {
    return _repository.deleteProduct(id);
  }

  // =========================================================
  // Update Stock
  // =========================================================

  Future<void> updateStock(String productId, int newQuantity) async {
    if (newQuantity < 0) {
      throw Exception('الكمية لا يمكن أن تكون سالبة');
    }

    await _repository.updateStock(productId, newQuantity);
  }
}
