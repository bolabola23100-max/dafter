import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
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
    AccountTransactionRepository? transactionRepository,
  })  : _database = database ?? AppDatabase.instance,
        _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
        _returnRepository = returnRepository ?? PurchaseReturnRepository(),
        _productRepository = productRepository ?? ProductRepository(),
        _supplierRepository = supplierRepository ?? SupplierRepository(),
        _accountRepository = accountRepository ?? AccountRepository(),
        _transactionRepository =
            transactionRepository ?? AccountTransactionRepository();

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> createReturn({
    required String purchaseId,
    required List<PurchaseReturnItem> items,
    double refundedAmount = 0,
    String? refundAccountId,
    String? notes,
    DateTime? date,
  }) async {
    if (items.isEmpty) throw Exception('ضيف صنف واحد على الأقل');
    if (refundedAmount < 0) {
      throw Exception('مبلغ الفلوس الراجعة مينفعش يكون سالب');
    }

    final purchase = await _purchaseRepository.getPurchaseById(purchaseId);
    if (purchase == null) throw Exception('فاتورة الشراء مش موجودة');
    if (purchase.supplierId == null) throw Exception('الفاتورة دي مفيهاش مورد');

    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    if (refundedAmount > total) {
      throw Exception('الفلوس الراجعة مينفعش تكون أكتر من قيمة المرتجع');
    }
    if (refundedAmount > 0 && (refundAccountId == null || refundAccountId.isEmpty)) {
      throw Exception('اختار الحساب اللي هتنزل فيه فلوس المورد');
    }

    final returnId = _newId();
    final db = await _database.database;
    await db.transaction((txn) async {
      final supplier = await _supplierRepository.getSupplierByIdWithExecutor(
        txn,
        purchase.supplierId!,
      );
      if (supplier == null) throw Exception('المورد مش موجود');

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
      if (refundedAmount > refundableAmount) {
        throw Exception(
          'المبلغ اللي هيرجع من المورد أكبر من المبلغ المدفوع فعليًا في الفاتورة. '
          'المتاح للرد: ${refundableAmount.toStringAsFixed(2)}',
        );
      }

      final purchaseItems = await _purchaseRepository.getPurchaseItems(purchaseId);
      final oldReturnRows = await txn.query(
        DatabaseTables.purchaseReturnItems,
        columns: ['purchase_item_id', 'quantity'],
        where: 'return_id IN (SELECT id FROM ${DatabaseTables.purchaseReturns} WHERE purchase_id = ?)',
        whereArgs: [purchaseId],
      );

      final returnedByPurchaseItem = <String, int>{};
      for (final row in oldReturnRows) {
        final id = row['purchase_item_id'] as String;
        returnedByPurchaseItem[id] =
            (returnedByPurchaseItem[id] ?? 0) + (row['quantity'] as int);
      }

      final purchaseItemById = <String, PurchaseItem>{
        for (final item in purchaseItems) item.id: item,
      };

      for (final item in items) {
        final original = purchaseItemById[item.purchaseItemId];
        if (original == null) {
          throw Exception('في صنف من المرتجع مش موجود في الفاتورة');
        }
        if (item.productId != original.productId) {
          throw Exception('بيانات الصنف مش متطابقة مع الفاتورة');
        }
        if (item.quantity <= 0) {
          throw Exception('كمية المرتجع لازم تكون أكبر من صفر');
        }

        final alreadyReturned = returnedByPurchaseItem[item.purchaseItemId] ?? 0;
        if (alreadyReturned + item.quantity > original.quantity) {
          throw Exception('مينفعش ترجع كمية أكبر من اللي اتشرت');
        }

        final product = await _productRepository.getProductByIdWithExecutor(
          txn,
          item.productId,
        );
        if (product == null) throw Exception('المنتج مش موجود');
        if (product.quantity < item.quantity) {
          throw Exception('المخزون الحالي مش مكفي للمرتجع: ${product.name}');
        }

        await _productRepository.updateStockWithExecutor(
          txn,
          item.productId,
          product.quantity - item.quantity,
        );

        await txn.insert(DatabaseTables.stockMovements, {
          'id': _newId(),
          'product_id': item.productId,
          'type': StockMovementType.purchaseReturn.name,
          'quantity': -item.quantity,
          'date': (date ?? DateTime.now()).toIso8601String(),
          'reference_id': returnId,
          'notes': notes,
        });
      }

      final creditToSupplier = total - refundedAmount;
      if (creditToSupplier > supplier.balance) {
        throw Exception(
          'رصيد المورد الحالي مش مكفي لتسوية المرتجع. زوّد مبلغ الفلوس الراجعة من المورد.',
        );
      }

      final returnItems = items
          .map(
            (item) => PurchaseReturnItem(
              id: _newId(),
              returnId: returnId,
              purchaseItemId: item.purchaseItemId,
              productId: item.productId,
              quantity: item.quantity,
              price: item.price,
            ),
          )
          .toList();

      await _returnRepository.addReturnWithExecutor(
        txn,
        PurchaseReturn(
          id: returnId,
          purchaseId: purchaseId,
          supplierId: supplier.id,
          date: date ?? DateTime.now(),
          items: returnItems,
          refundedAmount: refundedAmount,
          notes: notes,
        ),
      );

      if (creditToSupplier > 0) {
        await _supplierRepository.updateBalanceWithExecutor(
          txn,
          supplier.id,
          supplier.balance - creditToSupplier,
        );
      }

      if (refundedAmount > 0) {
        final account = await _accountRepository.getAccountByIdWithExecutor(
          txn,
          refundAccountId!,
        );
        if (account == null) {
          throw Exception('الحساب اللي هتدخل فيه الفلوس مش موجود');
        }

        final paymentId = _newId();
        await txn.insert(DatabaseTables.payments, {
          'id': paymentId,
          'type': PaymentType.receipt.name,
          'person_type': 'supplier',
          'person_id': supplier.id,
          'account_id': account.id,
          'amount': refundedAmount,
          'date': (date ?? DateTime.now()).toIso8601String(),
          'notes': 'فلوس راجعة من مرتجع شراء${notes == null ? '' : ' - $notes'}',
        });

        await _transactionRepository.addTransactionWithExecutor(
          txn,
          AccountTransaction(
            id: _newId(),
            accountId: account.id,
            type: TransactionType.receipt,
            amount: refundedAmount,
            isDebit: false,
            date: date ?? DateTime.now(),
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
