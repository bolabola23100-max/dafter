import 'package:dafter/features/Products/screens/products_screen.dart';
import 'package:dafter/features/accounts/screens/accounts_screen.dart';
import 'package:dafter/features/customers/screens/customers_screen.dart';
import 'package:dafter/features/dashboard/screens/dashboard_screen.dart';
import 'package:dafter/features/purchases/screens/purchases_screen.dart';
import 'package:dafter/features/reports/screens/reports_screen.dart';
import 'package:dafter/features/sales/screens/sales_screen.dart';
import 'package:dafter/features/sidebar/widgets/nav_item.dart';
import 'package:dafter/features/sidebar/widgets/top_bar.dart';
import 'package:dafter/features/suppliers/screens/suppliers_screen.dart';
import 'package:flutter/material.dart';

// كل شاشة في التطبيق ليها قيمة هنا، وترتيبها لازم يطابق
// ترتيب الشاشات في الـ IndexedStack تحت بالظبط.
enum AppScreen {
  home,
  sales,
  products,
  purchases,
  customers,
  suppliers,
  accounts,
  reports,
}

class SidebarScreen extends StatefulWidget {
  const SidebarScreen({super.key});

  @override
  State<SidebarScreen> createState() => _SidebarScreenState();
}

class _SidebarScreenState extends State<SidebarScreen> {
  // الشاشة الحالية المختارة، افتراضيًا الرئيسية
  AppScreen _currentScreen = AppScreen.home;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F9),
        body: Row(
          children: [
            // 1. المحتوى الرئيسي (شمال)
            Expanded(
              child: Column(
                children: [
                  const TopBar(), // التوب بار ثابت فوق
                  const Divider(height: 1, color: Color(0xFFE5E9EB)),
                  Expanded(
                    // المحتوى بيتغير حسب الشاشة المختارة
                    child: IndexedStack(
                      index: _currentScreen.index,
                      children: const [
                        DashboardScreen(), // index 0 → home
                        SalesScreen(), // index 1 → sales
                        ProductsScreen(), // index 2 → products
                        PurchasesScreen(), // index 3 → purchases
                        CustomersScreen(), // index 4 → customers
                        SuppliersScreen(), // index 5 → suppliers
                        AccountsScreen(), // index 6 → accounts
                        ReportsScreen(), // index 7 → reports
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. الخط الفاصل بين المحتوى والسايدبار
            const VerticalDivider(width: 1, color: Color(0xFFE5E9EB)),

            // 3. السايدبار (يمين - ثابت)
            SizedBox(
              width: 260,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // الشعار
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E4C4C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // اسم المتجر
                    const Text(
                      'dafter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'نظام إدارة المخزون',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // عناصر التنقل
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          NavItem(
                            icon: Icons.home_outlined,
                            label: 'الرئيسية',
                            selected: _currentScreen == AppScreen.home,
                            onTap: () =>
                                setState(() => _currentScreen = AppScreen.home),
                          ),
                          NavItem(
                            icon: Icons.shopping_cart_outlined,
                            label: 'المبيعات',
                            selected: _currentScreen == AppScreen.sales,
                            onTap: () => setState(
                              () => _currentScreen = AppScreen.sales,
                            ),
                          ),
                          NavItem(
                            icon: Icons.inventory_2_outlined,
                            label: 'المنتجات والمخزون',
                            selected: _currentScreen == AppScreen.products,
                            onTap: () => setState(
                              () => _currentScreen = AppScreen.products,
                            ),
                          ),
                          NavItem(
                            icon: Icons.receipt_long_outlined,
                            label: 'المشتريات',
                            selected: _currentScreen == AppScreen.purchases,
                            onTap: () => setState(
                              () => _currentScreen = AppScreen.purchases,
                            ),
                          ),
                          NavItem(
                            icon: Icons.people_outline,
                            label: 'العملاء',
                            selected: _currentScreen == AppScreen.customers,
                            onTap: () => setState(
                              () => _currentScreen = AppScreen.customers,
                            ),
                          ),
                          NavItem(
                            icon: Icons.local_shipping_outlined,
                            label: 'الموردين',
                            selected: _currentScreen == AppScreen.suppliers,
                            onTap: () => setState(
                              () => _currentScreen = AppScreen.suppliers,
                            ),
                          ),
                          NavItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'الحسابات',
                            selected: _currentScreen == AppScreen.accounts,
                            onTap: () => setState(
                              () => _currentScreen = AppScreen.accounts,
                            ),
                          ),
                          NavItem(
                            icon: Icons.bar_chart_outlined,
                            label: 'التقارير',
                            selected: _currentScreen == AppScreen.reports,
                            onTap: () => setState(
                              () => _currentScreen = AppScreen.reports,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
