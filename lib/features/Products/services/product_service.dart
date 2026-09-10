import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/model/product.dart';

class ProductService {
  final ProductRepository _repository;

  ProductService({ProductRepository? repository})
    : _repository = repository ?? ProductRepository();

  void _validate(Product product) {
    if (product.name.trim().isEmpty) {
      throw Exception('اسم المنتج مطلوب');
    }
    if (!product.purchasePrice.isFinite || product.purchasePrice < 0) {
      throw Exception('سعر الشراء غير صحيح');
    }
    if (!product.sellingPrice.isFinite || product.sellingPrice < 0) {
      throw Exception('سعر البيع غير صحيح');
    }
    if (product.quantity < 0) {
      throw Exception('الكمية لا يمكن أن تكون سالبة');
    }
    if (product.minQuantity < 0) {
      throw Exception('الحد الأدنى للمخزون غير صحيح');
    }
  }

  Future<void> addProduct(Product product) async {
    _validate(product);

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

  Future<List<Product>> getProducts() => _repository.getProducts();

  Future<Product?> getProductById(String id) => _repository.getProductById(id);

  Future<Product?> getProductByBarcode(String barcode) =>
      _repository.getProductByBarcode(barcode);

  Future<List<Product>> searchProducts(String query) =>
      _repository.searchProducts(query);

  Future<void> updateProduct(Product product) async {
    _validate(product);

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

  Future<void> deleteProduct(String id) => _repository.deleteProduct(id);

  Future<void> updateStock(String productId, int newQuantity) async {
    if (newQuantity < 0) {
      throw Exception('الكمية لا يمكن أن تكون سالبة');
    }
    await _repository.updateStock(productId, newQuantity);
  }
}
