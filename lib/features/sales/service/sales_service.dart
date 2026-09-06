import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/Inventory/repositories/stock_movement_repository.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/accounts/repo/payment_repository.dart';
import 'package:dafter/features/customers/repo/customer_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/model/stock_movement.dart';
import 'package:dafter/features/sales/repo/sales_repository.dart';

class SalesService {
  final AppDatabase _database;
  final SalesRepository _salesRepository;
  final ProductRepository _productRepository;
  final CustomerRepository _customerRepository;
  final StockMovementRepository _stockMovementRepository;
  final PaymentRepository _paymentRepository;
  final AccountRepository _accountRepository;
  final AccountTransactionRepository _accountTransactionRepository;

  SalesService({
    AppDatabase? database,
    SalesRepository? salesRepository,
    ProductRepository? productRepository,
    CustomerRepository? customerRepository,
    StockMovementRepository? stockMovementRepository,
    PaymentRepository? paymentRepository,
    AccountRepository? accountRepository,
    AccountTransactionRepository? accountTransactionRepository,
  }) : _database = database ?? AppDatabase.instance,
       _salesRepository = salesRepository ?? SalesRepository(),
       _productRepository = productRepository ?? ProductRepository(),
       _customerRepository = customerRepository ?? CustomerRepository(),
       _stockMovementRepository = stockMovementRepository ?? StockMovementRepository(),
       _paymentRepository = paymentRepository ?? PaymentRepository(),
       _accountRepository = accountRepository ?? AccountRepository(),
       _accountTransactionRepository = accountTransactionRepository ?? AccountTransactionRepository();

  Future<void> createSale({required Sale sale, String? accountId}) async {
    if (sale.items.isEmpty) throw Exception('ضيف صنف واحد على الأقل');
    if (sale.total < 0) throw Exception('إجمالي الفاتورة مينفعش يكون بالسالب');
    if (sale.paidAmount < 0 || sale.paidAmount > sale.total) {
      throw Exception('المبلغ المدفوع غير صحيح');
    }

    final db = await _database.database;
    await db.transaction((txn) async {
      if (sale.paidAmount > 0) {
        if (accountId == null || accountId.isEmpty) {
          throw Exception('اختار الحساب اللي دخلت فيه الفلوس');
        }
        final account = await _accountRepository.getAccountByIdWithExecutor(txn, accountId);
        if (account == null) throw Exception('الحساب غير موجود');
      }

      if (sale.customerId != null) {
        final customer = await _customerRepository.getCustomerByIdWithExecutor(txn, sale.customerId!);
        if (customer == null) throw Exception('العميل غير موجود');
      }

      for (final item in sale.items) {
        if (item.quantity <= 0) throw Exception('كمية المنتج لازم تكون أكبر من صفر');
        if (item.subtotal < 0) throw Exception('سعر أو خصم الصنف غير صحيح');
        final product = await _productRepository.getProductByIdWithExecutor(txn, item.productId);
        if (product == null) throw Exception('المنتج غير موجود');
        if (product.quantity < item.quantity) {
          throw Exception('الكمية مش مكفية من: ${product.name}');
        }
      }

      await _salesRepository.addSaleWithExecutor(txn, sale);

      for (final item in sale.items) {
        final product = await _productRepository.getProductByIdWithExecutor(txn, item.productId);
        if (product == null) throw Exception('المنتج غير موجود');
        await _productRepository.updateStockWithExecutor(txn, product.id, product.quantity - item.quantity);
        await _stockMovementRepository.addMovementWithExecutor(
          txn,
          StockMovement(
            id: _generateId(),
            productId: product.id,
            type: StockMovementType.sale,
            quantity: -item.quantity,
            date: sale.date,
            referenceId: sale.id,
            notes: 'فاتورة بيع',
          ),
        );
      }

      final remaining = sale.remainingAmount < 0 ? 0 : sale.remainingAmount;
      if (sale.customerId != null && remaining > 0) {
        final customer = await _customerRepository.getCustomerByIdWithExecutor(txn, sale.customerId!);
        if (customer == null) throw Exception('العميل غير موجود');
        await _customerRepository.updateBalanceWithExecutor(txn, customer.id, customer.balance + remaining);
      }

      if (sale.paidAmount > 0) {
        final account = await _accountRepository.getAccountByIdWithExecutor(txn, accountId!);
        if (account == null) throw Exception('الحساب غير موجود');

        await _paymentRepository.addPaymentWithExecutor(
          txn,
          Payment(
            id: _generateId(),
            type: PaymentType.receipt,
            personId: sale.customerId,
            accountId: account.id,
            amount: sale.paidAmount,
            date: sale.date,
            notes: 'قبض فاتورة بيع',
          ),
        );

        await _accountTransactionRepository.addTransactionWithExecutor(
          txn,
          AccountTransaction(
            id: _generateId(),
            accountId: account.id,
            type: TransactionType.receipt,
            amount: sale.paidAmount,
            isDebit: false,
            date: sale.date,
            referenceId: sale.id,
            description: 'قبض فاتورة بيع',
          ),
        );

        await _accountRepository.updateBalanceWithExecutor(
          txn,
          account.id,
          account.balance + sale.paidAmount,
        );
      }
    });
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
