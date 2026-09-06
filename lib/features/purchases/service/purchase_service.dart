import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/Inventory/repositories/stock_movement_repository.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/accounts/repo/payment_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/stock_movement.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';

class PurchaseService {
  final AppDatabase _database;
  final PurchaseRepository _purchaseRepository;
  final ProductRepository _productRepository;
  final SupplierRepository _supplierRepository;
  final StockMovementRepository _stockMovementRepository;
  final PaymentRepository _paymentRepository;
  final AccountRepository _accountRepository;
  final AccountTransactionRepository _accountTransactionRepository;

  PurchaseService({
    AppDatabase? database,
    PurchaseRepository? purchaseRepository,
    ProductRepository? productRepository,
    SupplierRepository? supplierRepository,
    StockMovementRepository? stockMovementRepository,
    PaymentRepository? paymentRepository,
    AccountRepository? accountRepository,
    AccountTransactionRepository? accountTransactionRepository,
  }) : _database = database ?? AppDatabase.instance,
       _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
       _productRepository = productRepository ?? ProductRepository(),
       _supplierRepository = supplierRepository ?? SupplierRepository(),
       _stockMovementRepository = stockMovementRepository ?? StockMovementRepository(),
       _paymentRepository = paymentRepository ?? PaymentRepository(),
       _accountRepository = accountRepository ?? AccountRepository(),
       _accountTransactionRepository = accountTransactionRepository ?? AccountTransactionRepository();

  Future<void> createPurchase({
    required Purchase purchase,
    String? accountId,
  }) async {
    final db = await _database.database;

    await db.transaction((txn) async {
      await _purchaseRepository.addPurchaseWithExecutor(txn, purchase);

      for (final item in purchase.items) {
        final product = await _productRepository.getProductByIdWithExecutor(
          txn,
          item.productId,
        );

        if (product == null) {
          throw Exception('المنتج غير موجود: ${item.productId}');
        }

        final newQuantity = product.quantity + item.quantity;

        await _productRepository.updateStockWithExecutor(
          txn,
          product.id,
          newQuantity,
        );

        await _stockMovementRepository.addMovementWithExecutor(
          txn,
          StockMovement(
            id: _generateId(),
            productId: product.id,
            type: StockMovementType.purchase,
            quantity: item.quantity,
            date: purchase.date,
            referenceId: purchase.id,
            notes: 'فاتورة شراء',
          ),
        );
      }

      if (purchase.supplierId != null) {
        final supplier = await _supplierRepository.getSupplierByIdWithExecutor(
          txn,
          purchase.supplierId!,
        );

        if (supplier == null) {
          throw Exception('المورد غير موجود');
        }

        await _supplierRepository.updateBalanceWithExecutor(
          txn,
          supplier.id,
          supplier.balance + purchase.remainingAmount,
        );
      }

      if (purchase.paidAmount > 0) {
        if (accountId == null || accountId.isEmpty) {
          throw Exception('يجب اختيار الحساب الذي تم الدفع منه');
        }

        final account = await _accountRepository.getAccountByIdWithExecutor(
          txn,
          accountId,
        );

        if (account == null) {
          throw Exception('الحساب غير موجود');
        }

        if (account.balance < purchase.paidAmount) {
          throw Exception('رصيد الحساب غير كافٍ');
        }

        await _paymentRepository.addPaymentWithExecutor(
          txn,
          Payment(
            id: _generateId(),
            type: PaymentType.payment,
            personId: purchase.supplierId,
            accountId: account.id,
            amount: purchase.paidAmount,
            date: purchase.date,
            notes: 'دفع فاتورة شراء',
          ),
        );

        await _accountTransactionRepository.addTransactionWithExecutor(
          txn,
          AccountTransaction(
            id: _generateId(),
            accountId: account.id,
            type: TransactionType.payment,
            amount: purchase.paidAmount,
            isDebit: true,
            date: purchase.date,
            referenceId: purchase.id,
            description: 'دفع فاتورة شراء',
          ),
        );

        await _accountRepository.updateBalanceWithExecutor(
          txn,
          account.id,
          account.balance - purchase.paidAmount,
        );
      }
    });
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
