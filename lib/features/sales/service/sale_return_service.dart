import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/Inventory/repositories/stock_movement_repository.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/accounts/repo/payment_repository.dart';
import 'package:dafter/features/customers/repo/customer_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/sale_return.dart';
import 'package:dafter/features/model/stock_movement.dart';
import 'package:dafter/features/sales/repo/sale_return_repository.dart';
import 'package:dafter/features/sales/repo/sales_repository.dart';

class SaleReturnService {
  final AppDatabase _database;
  final SalesRepository _salesRepository;
  final SaleReturnRepository _returnRepository;
  final ProductRepository _productRepository;
  final CustomerRepository _customerRepository;
  final AccountRepository _accountRepository;
  final PaymentRepository _paymentRepository;
  final AccountTransactionRepository _transactionRepository;
  final StockMovementRepository _stockMovementRepository;

  SaleReturnService({
    AppDatabase? database,
    SalesRepository? salesRepository,
    SaleReturnRepository? returnRepository,
    ProductRepository? productRepository,
    CustomerRepository? customerRepository,
    AccountRepository? accountRepository,
    PaymentRepository? paymentRepository,
    AccountTransactionRepository? transactionRepository,
    StockMovementRepository? stockMovementRepository,
  }) : _database = database ?? AppDatabase.instance,
       _salesRepository = salesRepository ?? SalesRepository(),
       _returnRepository = returnRepository ?? SaleReturnRepository(),
       _productRepository = productRepository ?? ProductRepository(),
       _customerRepository = customerRepository ?? CustomerRepository(),
       _accountRepository = accountRepository ?? AccountRepository(),
       _paymentRepository = paymentRepository ?? PaymentRepository(),
       _transactionRepository = transactionRepository ?? AccountTransactionRepository(),
       _stockMovementRepository = stockMovementRepository ?? StockMovementRepository();

  Future<void> createReturn({
    required SaleReturn saleReturn,
    String? accountId,
  }) async {
    if (saleReturn.items.isEmpty) throw Exception('اختار صنف واحد على الأقل');
    if (saleReturn.refundedAmount < 0) {
      throw Exception('المبلغ اللي هيترد للعميل مينفعش يكون سالب');
    }
    if (saleReturn.refundedAmount > 0 && (accountId == null || accountId.isEmpty)) {
      throw Exception('اختار الحساب اللي هتطلع منه فلوس المرتجع');
    }

    final db = await _database.database;
    await db.transaction((txn) async {
      final sale = await _salesRepository.getSaleByIdWithExecutor(txn, saleReturn.saleId);
      if (sale == null) throw Exception('فاتورة البيع مش موجودة');

      final customerId = sale.customerId;
      if (saleReturn.customerId != customerId) {
        throw Exception('بيانات العميل في المرتجع مش مطابقة للفاتورة');
      }

      if (customerId != null) {
        final customer = await _customerRepository.getCustomerByIdWithExecutor(txn, customerId);
        if (customer == null) throw Exception('العميل مش موجود');
      }

      final saleSubtotal = sale.subtotal;
      final invoiceDiscountFactor = saleSubtotal > 0
          ? ((saleSubtotal - sale.discount) / saleSubtotal).clamp(0.0, 1.0).toDouble()
          : 1.0;

      final refundRows = await txn.rawQuery(
        'SELECT COALESCE(SUM(refunded_amount), 0) AS refunded_amount '
        'FROM ${DatabaseTables.saleReturns} WHERE sale_id = ?',
        [saleReturn.saleId],
      );
      final previouslyRefunded = refundRows.isEmpty
          ? 0.0
          : (refundRows.first['refunded_amount'] as num?)?.toDouble() ?? 0.0;
      final refundableAmount = (sale.paidAmount - previouslyRefunded)
          .clamp(0.0, double.infinity)
          .toDouble();

      final itemIds = saleReturn.items.map((item) => item.saleItemId).toList();
      final placeholders = List.filled(itemIds.length, '?').join(',');
      final previousRows = await txn.rawQuery(
        'SELECT sale_item_id, COALESCE(SUM(quantity), 0) AS returned_quantity '
        'FROM ${DatabaseTables.saleReturnItems} '
        'WHERE sale_item_id IN ($placeholders) '
        'GROUP BY sale_item_id',
        itemIds,
      );
      final returnedByItem = <String, int>{
        for (final row in previousRows)
          row['sale_item_id'] as String: (row['returned_quantity'] as num).toInt(),
      };

      final adjustedItems = <SaleReturnItem>[];
      for (final item in saleReturn.items) {
        if (item.quantity <= 0) throw Exception('كمية المرتجع لازم تكون أكبر من صفر');
        final saleItemRows = await txn.query(
          DatabaseTables.saleItems,
          where: 'id = ? AND sale_id = ?',
          whereArgs: [item.saleItemId, saleReturn.saleId],
          limit: 1,
        );
        if (saleItemRows.isEmpty) throw Exception('صنف المرتجع مش موجود في الفاتورة');

        final saleItem = saleItemRows.first;
        final soldQuantity = saleItem['quantity'] as int;
        final alreadyReturned = returnedByItem[item.saleItemId] ?? 0;
        if (alreadyReturned + item.quantity > soldQuantity) {
          throw Exception('الكمية المرتجعة أكبر من الكمية اللي اتباعت');
        }
        if (saleItem['product_id'] as String != item.productId) {
          throw Exception('بيانات المنتج في المرتجع مش مطابقة للفاتورة');
        }

        final lineGross = (saleItem['price'] as num).toDouble() * soldQuantity;
        final lineDiscount = (saleItem['discount'] as num).toDouble();
        final lineNet = (lineGross - lineDiscount).clamp(0.0, double.infinity).toDouble();
        final effectiveUnitPrice = soldQuantity > 0
            ? (lineNet / soldQuantity) * invoiceDiscountFactor
            : 0.0;

        adjustedItems.add(
          SaleReturnItem(
            id: item.id,
            returnId: saleReturn.id,
            saleItemId: item.saleItemId,
            productId: item.productId,
            quantity: item.quantity,
            price: effectiveUnitPrice,
          ),
        );
      }

      final adjustedTotal = adjustedItems.fold<double>(
        0,
        (sum, item) => sum + item.total,
      );
      if (adjustedTotal <= 0) throw Exception('قيمة المرتجع لازم تكون أكبر من صفر');
      if (saleReturn.refundedAmount > adjustedTotal) {
        throw Exception('المبلغ اللي هيترد للعميل أكبر من قيمة المرتجع');
      }
      if (saleReturn.refundedAmount > refundableAmount) {
        throw Exception(
          'المبلغ اللي هيترد للعميل أكبر من المبلغ المدفوع فعليًا في الفاتورة. '
          'المتاح للرد: ${refundableAmount.toStringAsFixed(2)}',
        );
      }

      if (saleReturn.refundedAmount > 0) {
        final account = await _accountRepository.getAccountByIdWithExecutor(txn, accountId!);
        if (account == null) throw Exception('الحساب مش موجود');
        if (account.balance < saleReturn.refundedAmount) {
          throw Exception('رصيد الحساب مش مكفي عشان ترجع الفلوس');
        }
      }

      final adjustedReturn = SaleReturn(
        id: saleReturn.id,
        saleId: saleReturn.saleId,
        customerId: customerId,
        date: saleReturn.date,
        items: adjustedItems,
        refundedAmount: saleReturn.refundedAmount,
        notes: saleReturn.notes,
      );

      await _returnRepository.addReturnWithExecutor(txn, adjustedReturn);

      for (final item in adjustedItems) {
        final product = await _productRepository.getProductByIdWithExecutor(txn, item.productId);
        if (product == null) throw Exception('المنتج مش موجود');
        await _productRepository.updateStockWithExecutor(txn, product.id, product.quantity + item.quantity);
        await _stockMovementRepository.addMovementWithExecutor(
          txn,
          StockMovement(
            id: _generateId(),
            productId: product.id,
            type: StockMovementType.saleReturn,
            quantity: item.quantity,
            date: adjustedReturn.date,
            referenceId: adjustedReturn.id,
            notes: 'مرتجع فاتورة بيع',
          ),
        );
      }

      final creditAmount = adjustedTotal - adjustedReturn.refundedAmount;
      if (customerId != null && creditAmount > 0) {
        final customer = await _customerRepository.getCustomerByIdWithExecutor(txn, customerId);
        if (customer == null) throw Exception('العميل مش موجود');
        final newBalance = customer.balance - creditAmount;
        if (newBalance < 0) {
          throw Exception('قيمة المرتجع أكبر من المبلغ المستحق على العميل');
        }
        await _customerRepository.updateBalanceWithExecutor(txn, customer.id, newBalance);
      }

      if (adjustedReturn.refundedAmount > 0) {
        final account = await _accountRepository.getAccountByIdWithExecutor(txn, accountId!);
        if (account == null) throw Exception('الحساب مش موجود');

        await _paymentRepository.addPaymentWithExecutor(
          txn,
          Payment(
            id: _generateId(),
            type: PaymentType.payment,
            personId: customerId,
            accountId: account.id,
            amount: adjustedReturn.refundedAmount,
            date: adjustedReturn.date,
            notes: 'رد فلوس مرتجع بيع',
          ),
        );

        await _transactionRepository.addTransactionWithExecutor(
          txn,
          AccountTransaction(
            id: _generateId(),
            accountId: account.id,
            type: TransactionType.payment,
            amount: adjustedReturn.refundedAmount,
            isDebit: true,
            date: adjustedReturn.date,
            referenceId: adjustedReturn.id,
            description: 'رد فلوس مرتجع بيع',
          ),
        );

        await _accountRepository.updateBalanceWithExecutor(
          txn,
          account.id,
          account.balance - adjustedReturn.refundedAmount,
        );
      }
    });
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
