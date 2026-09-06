import 'package:dafter/features/model/supplier.dart';
import 'package:dafter/features/suppliers/widgets/supplier_row.dart';
import 'package:flutter/material.dart';

class SuppliersTable extends StatelessWidget {
  final List<Supplier> suppliers;
  final void Function(Supplier) onSupplierTap;

  const SuppliersTable({
    super.key,
    required this.suppliers,
    required this.onSupplierTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suppliers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('لا يوجد موردين', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'المورد',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              Expanded(
                child: Text(
                  'رقم الهاتف',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              Expanded(
                child: Text(
                  'المستحق',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              Expanded(
                child: Text(
                  'الحالة',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              SizedBox(width: 45, child: Text('')),
            ],
          ),
        ),

        ...suppliers.map(
          (supplier) => SupplierRow(
            supplier: supplier,
            onTap: () => onSupplierTap(supplier),
          ),
        ),
      ],
    );
  }
}
