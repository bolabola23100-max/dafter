import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/customers/repo/customer_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/purchase_return.dart';
import 'package:dafter/features/model/stock_movement.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/purchases/repo/purchase_return_repository.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
    if (refundedAmount < 0) throw Exception('مبلغ الفلوس الراجعة مينفعش يكون سالب');

    final purchase = await _purchaseRepository.getPurchaseById(purchaseId);
    if (purchase == null) throw Exception('فاتورة الشراء مش موجودة');
    if (purchase.supplierId == null) throw Exception('الفاتورة دي مفيهاش مورد');

    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    if (refundedAmount > total) {
      throw Exception('الفلوس الراجعة مينفعش تكون أكتر من قيمة المرتجع');
    }

    if (refundedAmount > 0 && refundAccountId == null) {
      throw Exception('اختار الحساب اللي هتنزل فيه فلوس المورد');
    }

    final db = await _database.database;
    await db.transaction((txn) async {
      final supplier = await _supplierRepository.getSupplierByIdWithExecutor(
        txn,
        purchase.supplierId!,
      );
      if (supplier == null) throw Exception('المورد مش موجود');

      final purchaseItems = await _purchaseRepository.getPurchaseItems(purchaseId);
      final existingReturns =
          await _returnRepository.getReturnsByPurchase(purchaseId);

      for (final item in items) {
        final original = purchaseItems.cast<dynamic>().firstWhere(
          (value) => value.id == item.purchaseItemId,
          orElse: () => null,
        );
        if (original == null) {
          throw Exception('في صنف من المرتجع مش موجود في الفاتورة');
        }
        if (item.productId != original.productId) {
          throw Exception('بيانات الصنف مش متطابقة مع الفاتورة');
        }

        var alreadyReturned = 0;
        for (final oldReturn in existingReturns) {
          for (final oldItem in oldReturn.items) {
            if (oldItem.purchaseItemId == item.purchaseItemId) {
              alreadyReturned += oldItem.quantity;
            }
          }
        }

        if (item.quantity <= 0) {
          throw Exception('كمية المرتجع لازم تكون أكبر من صفر');
        }
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

        await txn.insert('stock_movements', {
          'id': _newId(),
          'product_id': item.productId,
          'type': StockMovementType.purchaseReturn.name,
          'quantity': -item.quantity,
          'date': (date ?? DateTime.now()).toIso8601String(),
          'reference_id': purchaseId,
          'notes': notes,
        });
      }

      final creditToSupplier = total - refundedAmount;
      if (creditToSupplier > supplier.balance) {
        throw Exception(
          'رصيد المورد الحالي مش مكفي لتسوية المرتجع. اختار فلوس راجعة من المورد بدل التسوية على الحساب.',
        );
      }

      final returnId = _newId();
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

      final purchaseReturn = PurchaseReturn(
        id: returnId,
        purchaseId: purchaseId,
        supplierId: supplier.id,
        date: date ?? DateTime.now(),
        items: returnItems,
        refundedAmount: refundedAmount,
        notes: notes,
      );

      await _returnRepository.addReturnWithExecutor(txn, purchaseReturn);

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
        if (account == null) throw Exception('الحساب اللي هتدخل فيه الفلوس مش موجود');

        final paymentId = _newId();
        await txn.insert('payments', {
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
