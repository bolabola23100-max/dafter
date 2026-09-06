import 'package:dafter/features/customers/model/customer.dart';
import 'package:flutter/material.dart';

class CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final void Function(Customer)? onViewCustomer;
  final void Function(Customer)? onRecordPayment;

  const CustomersTable({
    super.key,
    required this.customers,
    this.onViewCustomer,
    this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('العميل')),
            DataColumn(label: Text('الهاتف')),
            DataColumn(label: Text('إجمالي المشتريات')),
            DataColumn(label: Text('المدفوع')),
            DataColumn(label: Text('المتبقي (عليه)')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: customers.map((c) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(Text(c.phone)),
                DataCell(
                  Text('${c.totalPurchases.toStringAsFixed(2)} ر.س'),
                ),
                DataCell(Text('${c.paid.toStringAsFixed(2)} ر.س')),
                DataCell(
                  Text(
                    '${c.remaining.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      color: c.remaining > 0 ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () => onViewCustomer?.call(c),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.payments_outlined,
                          size: 18,
                        ),
                        onPressed: () => onRecordPayment?.call(c),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
