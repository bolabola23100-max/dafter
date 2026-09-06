import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/features/Products/screens/add_product_screen.dart';
import 'package:dafter/features/dashboard/widgets/inventory_status_card.dart';
import 'package:dafter/features/dashboard/widgets/receivables_card.dart';
import 'package:dafter/features/dashboard/widgets/recent_invoices.dart';
import 'package:dafter/features/dashboard/widgets/sales_chart.dart';
import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:dafter/features/purchases/screens/purchase_invoice_screen.dart';
import 'package:dafter/features/sales/screens/sales_invoice_screen.dart';
import 'package:dafter/features/sales/screens/sales_return_screen.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      icon: Icons.assignment_return_outlined,
                      label: 'مرتجع',
                      primary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SalesReturnScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.add_box_outlined,
                      label: 'إضافة منتج',
                      primary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddProductScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'فاتورة شراء',
                      primary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PurchaseInvoiceScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.shopping_cart_outlined,
                      label: 'فاتورة بيع',
                      primary: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SalesInvoiceScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconBg: const Color(0xFFF3E9DD),
                      iconColor: const Color(0xFF9C6B30),
                      value: '3,120.50 ريال',
                      label: 'صافي الربح التقريبي',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.description_outlined,
                      iconBg: const Color(0xFFF1F3F4),
                      iconColor: Colors.grey[700]!,
                      value: '84 فاتورة',
                      label: 'عدد فواتير اليوم',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.trending_up,
                      iconBg: const Color(0xFFDDEDEC),
                      iconColor: const Color(0xFF0E4C4C),
                      value: '12,450.00 ريال',
                      label: 'مبيعات اليوم',
                      trailingText: '+5.2% عن الأمس',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const InventoryStatusCard(
                totalProducts: 428,
                lowStock: 12,
                outOfStock: 4,
              ),
              const SizedBox(height: 20),

              const ReceivablesCard(
                customerDue: '8,450 ج.م',
                supplierDue: '5,200 ج.م',
              ),
              const SizedBox(height: 20),

              const SalesChart(),
              const SizedBox(height: 20),

              const RecentInvoices(),
            ],
          ),
        ),
      ),
    );
  }
}
