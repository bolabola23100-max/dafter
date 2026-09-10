import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/core/utils/id_generator.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/purchase_item.dart';
import 'package:dafter/features/model/purchase_return.dart';
import 'package:dafter/features/model/stock_movement.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/purchases/repo/purchase_return_repository.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';

class PurchaseReturnService {
  final AppDatabase _database;
  final PurchaseRepository _purchaseRepository;
  final PurchaseReturnRepository _returnRepository;
  final ProductRepository _productRepository;
  final SupplierRepository _supplierRepository;
  final AccountRepository _accountRepository;
  final AccountTransactionRepository _transactionRepository;

  PurchaseReturnService({
    AppDatabase? database,
    PurchaseRepository? purchaseRepository,
    PurchaseReturnRepository? returnRepository,
    ProductRepository? productRepository,
    SupplierRepository? supplierRepository,
    AccountRepository? accountRepository,
    AccountTransactionRepository? accountTransactionRepository,
  }) : _database = database ?? AppDatabase.instance,
       _purchaseRepository = purchaseRepository ?? PurchaseRepository(database: database ?? AppDatabase.instance),
       _returnRepository = returnRepository ?? PurchaseReturnRepository(database: database ?? AppDatabase.instance),
       _productRepository = productRepository ?? ProductRepository(database: database ?? AppDatabase.instance),
       _supplierRepository = supplierRepository ?? SupplierRepository(database: database ?? AppDatabase.instance),
       _accountRepository = accountRepository ?? AccountRepository(database: database ?? AppDatabase.instance),
       _transactionRepository = accountTransactionRepository ?? AccountTransactionRepository(database: database ?? AppDatabase.instance);

  Future<void> createReturn({
    required String purchaseId,
    required List<PurchaseReturnItem> items,
    double refundedAmount = 0,
    String? refundAccountId,
    String? notes,
    DateTime? date,
  }) async {
    if (items.isEmpty) throw Exception('ضيف صنف واحد على الأقل');
    if (refundedAmount < 0) throw Exception('مبلغ الفلوس الراجعة مينفعش يكون سالب');
    if (refundedAmount > 0 && (refundAccountId == null || refundAccountId.isEmpty)) {
      throw Exception('اختار الحساب اللي هتنزل فيه فلوس المورد');
    }

    final purchase = await _purchaseRepository.getPurchaseById(purchaseId);
    if (purchase == null) throw Exception('فاتورة الشراء مش موجودة');
    if (purchase.supplierId == null) throw Exception('الفاتورة دي مفيهاش مورد');

    final returnDate = date ?? DateTime.now();
    final db = await _database.database;
    await db.transaction((txn) async {
      final supplier = await _supplierRepository.getSupplierByIdWithExecutor(txn, purchase.supplierId!);
      if (supplier == null) throw Exception('المورد مش موجود');

      final purchaseSubtotal = purchase.subtotal;
      final invoiceDiscountFactor = purchaseSubtotal > 0
          ? ((purchaseSubtotal - purchase.discount) / purchaseSubtotal).clamp(0.0, 1.0).toDouble()
          : 1.0;

      final refundRows = await txn.rawQuery(
        'SELECT COALESCE(SUM(refunded_amount), 0) AS refunded_amount '
        'FROM ${DatabaseTables.purchaseReturns} WHERE purchase_id = ?',
        [purchaseId],
      );
      final previouslyRefunded = refundRows.isEmpty
          ? 0.0
          : (refundRows.first['refunded_amount'] as num?)?.toDouble() ?? 0.0;
      final refundableAmount = (purchase.paidAmount - previouslyRefunded)
          .clamp(0.0, double.infinity)
          .toDouble();

      final purchaseItems = await _purchaseRepository.getPurchaseItemsWithExecutor(txn, purchaseId);
      final oldReturnRows = await txn.query(
        DatabaseTables.purchaseReturnItems,
        columns: ['purchase_item_id', 'quantity'],
        where: 'return_id IN (SELECT id FROM ${DatabaseTables.purchaseReturns} WHERE purchase_id = ?)',
        whereArgs: [purchaseId],
      );

      final returnedByPurchaseItem = <String, int>{};
      for (final row in oldReturnRows) {
        final id = row['purchase_item_id'] as String;
        returnedByPurchaseItem[id] = (returnedByPurchaseItem[id] ?? 0) + (row['quantity'] as int);
      }

      // Aggregate quantities in the current request too. Otherwise the same
      // purchase item could be submitted twice and bypass the per-row limit.
      final requestedByPurchaseItem = <String, int>{};
      for (final item in items) {
        if (item.quantity <= 0) throw Exception('كمية المرتجع لازم تكون أكبر من صفر');
        requestedByPurchaseItem.update(
          item.purchaseItemId,
          (quantity) => quantity + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }

      final purchaseItemById = <String, PurchaseItem>{
        for (final item in purchaseItems) item.id: item,
      };
      final adjustedItems = <PurchaseReturnItem>[];

      for (final item in items) {
        final original = purchaseItemById[item.purchaseItemId];
        if (original == null) throw Exception('في صنف من المرتجع مش موجود في الفاتورة');
        if (item.productId != original.productId) throw Exception('بيانات الصنف مش متطابقة مع الفاتورة');

        final alreadyReturned = returnedByPurchaseItem[item.purchaseItemId] ?? 0;
        final requestedQuantity = requestedByPurchaseItem[item.purchaseItemId] ?? 0;
        if (alreadyReturned + requestedQuantity > original.quantity) {
          throw Exception('مينفعش ترجع كمية أكبر من اللي اتشرت');
        }

        final product = await _productRepository.getProductByIdWithExecutor(txn, item.productId);
        if (product == null) throw Exception('المنتج مش موجود');
        if (product.quantity < item.quantity) throw Exception('المخزون الحالي مش مكفي للمرتجع: ${product.name}');

        final lineGross = original.quantity * original.price;
        final lineNet = (lineGross - original.discount).clamp(0.0, double.infinity).toDouble();
        final effectiveUnitPrice = original.quantity > 0
            ? (lineNet / original.quantity) * invoiceDiscountFactor
            : 0.0;

        adjustedItems.add(
          PurchaseReturnItem(
            id: item.id,
            returnId: item.returnId,
            purchaseItemId: item.purchaseItemId,
            productId: item.productId,
            quantity: item.quantity,
            price: effectiveUnitPrice,
          ),
        );
      }

      final total = adjustedItems.fold<double>(0, (sum, item) => sum + item.total);
      if (total <= 0) throw Exception('قيمة المرتجع لازم تكون أكبر من صفر');
      if (refundedAmount > total) throw Exception('الفلوس الراجعة مينفعش تكون أكتر من قيمة المرتجع');
      if (refundedAmount > refundableAmount) {
        throw Exception(
          'المبلغ اللي هيرجع من المورد أكبر من المبلغ المدفوع فعليًا في الفاتورة. '
          'المتاح للرد: ${refundableAmount.toStringAsFixed(2)}',
        );
      }

      final returnId = IdGenerator.generate();
      final finalItems = adjustedItems
          .map((item) => PurchaseReturnItem(
                id: item.id,
                returnId: returnId,
                purchaseItemId: item.purchaseItemId,
                productId: item.productId,
                quantity: item.quantity,
                price: item.price,
              ))
          .toList();

      for (final item in finalItems) {
        final product = await _productRepository.getProductByIdWithExecutor(txn, item.productId);
        if (product == null) throw Exception('المنتج مش موجود');
        await _productRepository.updateStockWithExecutor(txn, item.productId, product.quantity - item.quantity);
        await txn.insert(DatabaseTables.stockMovements, {
          'id': IdGenerator.generate(),
          'product_id': item.productId,
          'type': StockMovementType.purchaseReturn.name,
          'quantity': -item.quantity,
          'date': returnDate.toIso8601String(),
          'reference_id': returnId,
          'notes': notes,
        });
      }

      final creditToSupplier = total - refundedAmount;
      await _returnRepository.addReturnWithExecutor(
        txn,
        PurchaseReturn(
          id: returnId,
          purchaseId: purchaseId,
          supplierId: supplier.id,
          date: returnDate,
          items: finalItems,
          refundedAmount: refundedAmount,
          notes: notes,
        ),
      );

      if (creditToSupplier > 0) {
        // A negative supplier balance is valid: after a fully paid purchase,
        // a return can leave the supplier owing money to the business.
        await _supplierRepository.updateBalanceWithExecutor(
          txn,
          supplier.id,
          supplier.balance - creditToSupplier,
        );
      }

      if (refundedAmount > 0) {
        final account = await _accountRepository.getAccountByIdWithExecutor(txn, refundAccountId!);
        if (account == null) throw Exception('الحساب اللي هتدخل فيه الفلوس مش موجود');

        await txn.insert(DatabaseTables.payments, {
          'id': IdGenerator.generate(),
          'type': PaymentType.receipt.name,
          'person_type': 'supplier',
          'person_id': supplier.id,
          'account_id': account.id,
          'amount': refundedAmount,
          'date': returnDate.toIso8601String(),
          'notes': 'فلوس راجعة من مرتجع شراء${notes == null ? '' : ' - $notes'}',
        });

        await _transactionRepository.addTransactionWithExecutor(
          txn,
          AccountTransaction(
            id: IdGenerator.generate(),
            accountId: account.id,
            type: TransactionType.receipt,
            amount: refundedAmount,
            isDebit: false,
            date: returnDate,
            referenceId: returnId,
            description: 'فلوس راجعة من المورد - مرتجع شراء',
          ),
        );

        await _accountRepository.updateBalanceWithExecutor(
          txn,
          account.id,
          account.balance + refundedAmount,
        );
      }
    });
  }
}
