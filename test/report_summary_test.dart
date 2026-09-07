import 'package:dafter/features/reports/model/report_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('net sales and gross profit include sales returns and COGS', () {
    const summary = ReportSummary(
      salesTotal: 1000,
      salesReturnsTotal: 150,
      costOfGoodsSold: 500,
      expensesTotal: 100,
    );

    expect(summary.netSales, 850);
    expect(summary.grossProfit, 350);
    expect(summary.netProfit, 250);
    expect(summary.net, 250);
  });

  test('net purchases subtract purchase returns', () {
    const summary = ReportSummary(
      purchasesTotal: 900,
      purchaseReturnsTotal: 200,
    );

    expect(summary.netPurchases, 700);
  });
}
