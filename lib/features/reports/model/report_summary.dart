class ReportSummary {
  final int salesCount;
  final double salesTotal;
  final int purchasesCount;
  final double purchasesTotal;
  final int expensesCount;
  final double expensesTotal;
  final int salesReturnsCount;
  final double salesReturnsTotal;
  final int purchaseReturnsCount;
  final double purchaseReturnsTotal;
  final int productsCount;
  final double stockValue;
  final int suppliersCount;
  final int customersCount;
  final double costOfGoodsSold;

  const ReportSummary({
    this.salesCount = 0,
    this.salesTotal = 0,
    this.purchasesCount = 0,
    this.purchasesTotal = 0,
    this.expensesCount = 0,
    this.expensesTotal = 0,
    this.salesReturnsCount = 0,
    this.salesReturnsTotal = 0,
    this.purchaseReturnsCount = 0,
    this.purchaseReturnsTotal = 0,
    this.productsCount = 0,
    this.stockValue = 0,
    this.suppliersCount = 0,
    this.customersCount = 0,
    this.costOfGoodsSold = 0,
  });

  double get netSales => salesTotal - salesReturnsTotal;
  double get grossProfit => netSales - costOfGoodsSold;
  double get netProfit => grossProfit - expensesTotal;
  // Kept for compatibility with existing screens.
  double get net => netProfit;
}
