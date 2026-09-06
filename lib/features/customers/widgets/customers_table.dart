import 'package:dafter/features/customers/model/customer.dart';
import 'package:flutter/material.dart';

class CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final void Function(Customer)? onViewCustomer;
  final void Function(Customer)? onRecordPayment;

  const CustomersTable({super.key, required this.customers, this.onViewCustomer, this.onRecordPayment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))),
      child: customers.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('لسه مفيش عملاء')))
          : SingleChildScrollView(
              child: DataTable(
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('العميل')),
                  DataColumn(label: Text('التليفون')),
                  DataColumn(label: Text('الرصيد')),
                  DataColumn(label: Text('إجراءات')),
                ],
                rows: customers.map((c) => DataRow(cells: [
                  DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(c.phone ?? '-')),
                  DataCell(Text('${c.balance.toStringAsFixed(2)} جنيه', style: TextStyle(color: c.balance > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w600))),
                  DataCell(Row(children: [
                    IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), tooltip: 'كشف الحساب', onPressed: () => onViewCustomer?.call(c)),
                    IconButton(icon: const Icon(Icons.payments_outlined, size: 18), tooltip: 'تحصيل دفعة', onPressed: () => onRecordPayment?.call(c)),
                  ])),
                ])).toList(),
              ),
            ),
    );
  }
}
