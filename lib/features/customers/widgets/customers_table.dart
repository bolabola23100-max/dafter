import 'package:dafter/features/model/customer.dart';
import 'package:flutter/material.dart';

class CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final void Function(Customer)? onViewCustomer;
  final void Function(Customer)? onRecordPayment;
  final void Function(Customer)? onDeleteCustomer;

  const CustomersTable({
    super.key,
    required this.customers,
    this.onViewCustomer,
    this.onRecordPayment,
    this.onDeleteCustomer,
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
      child: customers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('لسه مفيش عملاء'),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('العميل')),
                  DataColumn(label: Text('التليفون')),
                  DataColumn(label: Text('الرصيد')),
                  DataColumn(label: Text('إجراءات')),
                ],
                rows: customers.map((customer) {
                  final balanceColor =
                      customer.balance > 0 ? Colors.red : Colors.green;
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(Text(customer.phone ?? '-')),
                      DataCell(
                        Text(
                          '${customer.balance.toStringAsFixed(2)} جنيه',
                          style: TextStyle(
                            color: balanceColor,
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
                              tooltip: 'كشف الحساب',
                              onPressed: () => onViewCustomer?.call(customer),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.payments_outlined,
                                size: 18,
                              ),
                              tooltip: 'تحصيل دفعة',
                              onPressed: () =>
                                  onRecordPayment?.call(customer),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              tooltip: 'حذف العميل',
                              onPressed: () =>
                                  onDeleteCustomer?.call(customer),
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
