import 'package:dafter/features/model/sale_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sale item subtotal uses line discount', () {
    final item = SaleItem(
      id: '1',
      saleId: 'sale-1',
      productId: 'product-1',
      quantity: 3,
      price: 100,
      discount: 20,
      costPrice: 60,
    );

    expect(item.subtotal, 280);
    expect(item.costTotal, 180);
  });
}
