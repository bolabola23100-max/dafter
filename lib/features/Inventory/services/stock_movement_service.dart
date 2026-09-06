import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/Inventory/repositories/stock_movement_repository.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/model/stock_movement.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class StockMovementService {
  final StockMovementRepository _repository;
  final ProductRepository _productRepository;
  final AppDatabase _database;

  StockMovementService({
    StockMovementRepository? repository,
    ProductRepository? productRepository,
    AppDatabase? database,
  }) : _repository = repository ?? StockMovementRepository(),
       _productRepository = productRepository ?? ProductRepository(),
       _database = database ?? AppDatabase.instance;

  // =========================================================
  // Add Movement
  // =========================================================

  Future<void> addMovement({
    required String productId,
    required StockMovementType type,
    required int quantity,
    String? referenceId,
    String? notes,
  }) async {
    if (productId.trim().isEmpty) {
      throw Exception('المنتج مطلوب');
    }

    if (quantity == 0) {
      throw Exception('كمية الحركة لا يمكن أن تكون صفر');
    }

    final db = await _database.database;

    await db.transaction((txn) async {
      final product = await _productRepository.getProductByIdWithExecutor(
        txn,
        productId,
      );

      if (product == null) {
        throw Exception('المنتج غير موجود');
      }

      final newQuantity = product.quantity + quantity;

      if (newQuantity < 0) {
        throw Exception('الكمية لا يمكن أن تكون سالبة');
      }

      final movement = StockMovement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productId: productId,
        type: type,
        quantity: quantity,
        date: DateTime.now(),
        referenceId: referenceId,
        notes: notes,
      );

      await _repository.addMovementWithExecutor(txn, movement);

      await _productRepository.updateStockWithExecutor(
        txn,
        productId,
        newQuantity,
      );
    });
  }

  // =========================================================
  // Adjust Single Product
  // =========================================================

  Future<void> adjustStock({
    required Product product,
    required int actualQuantity,
    String? notes,
  }) async {
    if (actualQuantity < 0) {
      throw Exception('الكمية الفعلية لا يمكن أن تكون سالبة');
    }

    final db = await _database.database;

    await db.transaction((txn) async {
      final currentProduct = await _productRepository
          .getProductByIdWithExecutor(txn, product.id);

      if (currentProduct == null) {
        throw Exception('المنتج غير موجود');
      }

      final difference = actualQuantity - currentProduct.quantity;

      if (difference == 0) {
        return;
      }

      final movement = StockMovement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productId: currentProduct.id,
        type: StockMovementType.adjustment,
        quantity: difference,
        date: DateTime.now(),
        notes: notes,
      );

      await _repository.addMovementWithExecutor(txn, movement);

      await _productRepository.updateStockWithExecutor(
        txn,
        currentProduct.id,
        actualQuantity,
      );
    });
  }

  // =========================================================
  // Adjust Full Inventory
  // =========================================================

  Future<void> adjustInventory({
    required Map<String, int> actualQuantities,
    String? notes,
  }) async {
    if (actualQuantities.isEmpty) {
      return;
    }

    final db = await _database.database;

    await db.transaction((txn) async {
      for (final entry in actualQuantities.entries) {
        final productId = entry.key;
        final actualQuantity = entry.value;

        if (actualQuantity < 0) {
          throw Exception('الكمية الفعلية لا يمكن أن تكون سالبة');
        }

        final product = await _productRepository.getProductByIdWithExecutor(
          txn,
          productId,
        );

        if (product == null) {
          throw Exception('أحد المنتجات غير موجود');
        }

        final difference = actualQuantity - product.quantity;

        if (difference == 0) {
          continue;
        }

        final movement = StockMovement(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          productId: product.id,
          type: StockMovementType.adjustment,
          quantity: difference,
          date: DateTime.now(),
          notes: notes,
        );

        await _repository.addMovementWithExecutor(txn, movement);

        await _productRepository.updateStockWithExecutor(
          txn,
          product.id,
          actualQuantity,
        );
      }
    });
  }

  // =========================================================
  // Get Product Movements
  // =========================================================

  Future<List<StockMovement>> getProductMovements(String productId) {
    return _repository.getProductMovements(productId);
  }

  // =========================================================
  // Get All Movements
  // =========================================================

  Future<List<StockMovement>> getAllMovements() {
    return _repository.getAllMovements();
  }

  // =========================================================
  // Get Movement By ID
  // =========================================================

  Future<StockMovement?> getMovementById(String id) {
    return _repository.getMovementById(id);
  }
}
