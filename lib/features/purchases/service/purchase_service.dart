import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/utils/id_generator.dart';
import 'package:dafter/features/Inventory/repositories/stock_movement_repository.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/accounts/repo/payment_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/product.dart';
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

  PurchaseService({AppDatabase? database, PurchaseRepository? purchaseRepository, ProductRepository? productRepository, SupplierRepository? supplierRepository, StockMovementRepository? stockMovementRepository, PaymentRepository? paymentRepository, AccountRepository? accountRepository, AccountTransactionRepository? accountTransactionRepository})
      : _database = database ?? AppDatabase.instance,
        _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
        _productRepository = productRepository ?? ProductRepository(),
        _supplierRepository = supplierRepository ?? SupplierRepository(),
        _stockMovementRepository = stockMovementRepository ?? StockMovementRepository(),
        _paymentRepository = paymentRepository ?? PaymentRepository(),
        _accountRepository = accountRepository ?? AccountRepository(),
        _accountTransactionRepository = accountTransactionRepository ?? AccountTransactionRepository();

  Future<void> createPurchase({required Purchase purchase, String? accountId}) async {
    if (purchase.items.isEmpty) throw Exception('ضيف صنف واحد على الأقل');
    if (!purchase.discount.isFinite || purchase.discount < 0 || purchase.discount > purchase.subtotal) throw Exception('الخصم غير صحيح');
    if (!purchase.subtotal.isFinite || purchase.subtotal < 0 || !purchase.total.isFinite || purchase.total < 0) throw Exception('إجمالي الفاتورة غير صحيح');
    if (!purchase.paidAmount.isFinite || purchase.paidAmount < 0 || purchase.paidAmount > purchase.total) throw Exception('المبلغ المدفوع غير صحيح');
    final remaining = purchase.remainingAmount < 0 ? 0 : purchase.remainingAmount;
    if (!remaining.isFinite) throw Exception('المبلغ المتبقي غير صحيح');
    if (remaining > 0 && purchase.supplierId == null) throw Exception('أي مبلغ متبقي من الفاتورة لازم يتسجل على مورد');

    final db = await _database.database;
    await db.transaction((txn) async {
      if (purchase.supplierId != null) {
        final supplier = await _supplierRepository.getSupplierByIdWithExecutor(txn, purchase.supplierId!);
        if (supplier == null) throw Exception('المورد غير موجود');
      }

      final productsById = <String, Product>{};
      for (final item in purchase.items) {
        if (item.quantity <= 0) throw Exception('كمية المنتج لازم تكون أكبر من صفر');
        if (!item.price.isFinite || !item.discount.isFinite || item.price < 0 || item.discount < 0 || item.discount > item.quantity * item.price) {
          throw Exception('سعر أو خصم الصنف غير صحيح');
        }
        if (!productsById.containsKey(item.productId)) {
          final product = await _productRepository.getProductByIdWithExecutor(txn, item.productId);
          if (product == null) throw Exception('المنتج غير موجود: ${item.productId}');
          productsById[product.id] = product;
        }
      }

      if (purchase.paidAmount > 0) {
        if (accountId == null || accountId.isEmpty) throw Exception('اختار الحساب اللي دفعت منه الفلوس');
        final account = await _accountRepository.getAccountByIdWithExecutor(txn, accountId);
        if (account == null) throw Exception('الحساب غير موجود');
        if (account.balance < purchase.paidAmount) throw Exception('رصيد الحساب مش كافي');
      }

      await _purchaseRepository.addPurchaseWithExecutor(txn, purchase);
      for (final item in purchase.items) {
        final product = productsById[item.productId];
        if (product == null) throw Exception('المنتج غير موجود: ${item.productId}');
        await _productRepository.updateStockWithExecutor(txn, product.id, product.quantity + item.quantity);
        product.quantity += item.quantity;
        await _stockMovementRepository.addMovementWithExecutor(txn, StockMovement(
          id: IdGenerator.generate(), productId: product.id, type: StockMovementType.purchase,
          quantity: item.quantity, date: purchase.date, referenceId: purchase.id, notes: 'فاتورة شراء',
        ));
      }
      if (purchase.supplierId != null && remaining > 0) {
        final supplier = await _supplierRepository.getSupplierByIdWithExecutor(txn, purchase.supplierId!);
        if (supplier == null) throw Exception('المورد غير موجود');
        await _supplierRepository.updateBalanceWithExecutor(txn, supplier.id, supplier.balance + remaining);
      }
      if (purchase.paidAmount > 0) {
        final account = await _accountRepository.getAccountByIdWithExecutor(txn, accountId!);
        if (account == null) throw Exception('الحساب غير موجود');
        await _paymentRepository.addPaymentWithExecutor(txn, Payment(
          id: IdGenerator.generate(), type: PaymentType.payment, personId: purchase.supplierId,
          accountId: account.id, amount: purchase.paidAmount, date: purchase.date, notes: 'دفع فاتورة شراء',
        ));
        await _accountTransactionRepository.addTransactionWithExecutor(txn, AccountTransaction(
          id: IdGenerator.generate(), accountId: account.id, type: TransactionType.payment,
          amount: purchase.paidAmount, isDebit: true, date: purchase.date, referenceId: purchase.id, description: 'دفع فاتورة شراء',
        ));
        await _accountRepository.updateBalanceWithExecutor(txn, account.id, account.balance - purchase.paidAmount);
      }
    });
  }
}
