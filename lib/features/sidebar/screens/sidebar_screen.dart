import 'package:dafter/core/database/app_database_watcher.dart';
import 'package:dafter/features/Products/screens/products_screen.dart';
import 'package:dafter/features/accounts/screens/accounts_screen.dart';
import 'package:dafter/features/customers/screens/customers_screen.dart';
import 'package:dafter/features/dashboard/screens/dashboard_screen.dart';
import 'package:dafter/features/expenses/screens/expenses_screen.dart';
import 'package:dafter/features/purchases/screens/purchases_screen.dart';
import 'package:dafter/features/reports/screens/reports_screen.dart';
import 'package:dafter/features/sales/screens/sales_screen.dart';
import 'package:dafter/features/settings/screens/settings_screen.dart';
import 'package:dafter/features/sidebar/widgets/nav_item.dart';
import 'package:dafter/features/sidebar/widgets/top_bar.dart';
import 'package:dafter/features/suppliers/screens/suppliers_screen.dart';
import 'package:flutter/material.dart';

enum AppScreen {
  home,
  sales,
  products,
  purchases,
  customers,
  suppliers,
  accounts,
  expenses,
  reports,
  settings,
}

class SidebarScreen extends StatefulWidget {
  const SidebarScreen({super.key});

  @override
  State<SidebarScreen> createState() => _SidebarScreenState();
}

class _SidebarScreenState extends State<SidebarScreen> {
  final AppDatabaseWatcher _databaseWatcher = AppDatabaseWatcher.instance;
  final Map<AppScreen, int> _screenVersions = {
    for (final screen in AppScreen.values) screen: 0,
  };

  AppScreen _currentScreen = AppScreen.home;

  @override
  void initState() {
    super.initState();
    _databaseWatcher.addListener(_onDatabaseChanged);
    _databaseWatcher.start();
  }

  @override
  void dispose() {
    _databaseWatcher.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  void _onDatabaseChanged() {
    if (!mounted) return;
    setState(() {
      _screenVersions[_currentScreen] =
          (_screenVersions[_currentScreen] ?? 0) + 1;
    });
  }

  void _openScreen(AppScreen screen) {
    setState(() {
      _currentScreen = screen;
      _screenVersions[screen] = (_screenVersions[screen] ?? 0) + 1;
    });
  }

  Widget _screen(AppScreen screen, Widget child) {
    return KeyedSubtree(
      key: ValueKey('${screen.name}-${_screenVersions[screen]}'),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F9),
        body: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const TopBar(),
                  const Divider(height: 1, color: Color(0xFFE5E9EB)),
                  Expanded(
                    child: IndexedStack(
                      index: _currentScreen.index,
                      children: [
                        _screen(AppScreen.home, const DashboardScreen()),
                        _screen(AppScreen.sales, const SalesScreen()),
                        _screen(AppScreen.products, const ProductsScreen()),
                        _screen(AppScreen.purchases, const PurchasesScreen()),
                        _screen(AppScreen.customers, const CustomersScreen()),
                        _screen(AppScreen.suppliers, const SuppliersScreen()),
                        _screen(AppScreen.accounts, const AccountsScreen()),
                        _screen(AppScreen.expenses, const ExpensesScreen()),
                        _screen(AppScreen.reports, const ReportsScreen()),
                        _screen(AppScreen.settings, const SettingsScreen()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, color: Color(0xFFE5E9EB)),
            SizedBox(
              width: 260,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
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
                    const Text(
                      'dafter',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'نظام إدارة المخزون',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          NavItem(
                            icon: Icons.home_outlined,
                            label: 'الرئيسية',
                            selected: _currentScreen == AppScreen.home,
                            onTap: () => _openScreen(AppScreen.home),
                          ),
                          NavItem(
                            icon: Icons.shopping_cart_outlined,
                            label: 'المبيعات',
                            selected: _currentScreen == AppScreen.sales,
                            onTap: () => _openScreen(AppScreen.sales),
                          ),
                          NavItem(
                            icon: Icons.inventory_2_outlined,
                            label: 'المنتجات والمخزون',
                            selected: _currentScreen == AppScreen.products,
                            onTap: () => _openScreen(AppScreen.products),
                          ),
                          NavItem(
                            icon: Icons.receipt_long_outlined,
                            label: 'المشتريات',
                            selected: _currentScreen == AppScreen.purchases,
                            onTap: () => _openScreen(AppScreen.purchases),
                          ),
                          NavItem(
                            icon: Icons.people_outline,
                            label: 'العملاء',
                            selected: _currentScreen == AppScreen.customers,
                            onTap: () => _openScreen(AppScreen.customers),
                          ),
                          NavItem(
                            icon: Icons.local_shipping_outlined,
                            label: 'الموردين',
                            selected: _currentScreen == AppScreen.suppliers,
                            onTap: () => _openScreen(AppScreen.suppliers),
                          ),
                          NavItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'الحسابات',
                            selected: _currentScreen == AppScreen.accounts,
                            onTap: () => _openScreen(AppScreen.accounts),
                          ),
                          NavItem(
                            icon: Icons.money_off_outlined,
                            label: 'المصروفات',
                            selected: _currentScreen == AppScreen.expenses,
                            onTap: () => _openScreen(AppScreen.expenses),
                          ),
                          NavItem(
                            icon: Icons.bar_chart_outlined,
                            label: 'التقارير',
                            selected: _currentScreen == AppScreen.reports,
                            onTap: () => _openScreen(AppScreen.reports),
                          ),
                          const Divider(height: 24),
                          NavItem(
                            icon: Icons.settings_outlined,
                            label: 'الإعدادات والنسخ الاحتياطي',
                            selected: _currentScreen == AppScreen.settings,
                            onTap: () => _openScreen(AppScreen.settings),
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
