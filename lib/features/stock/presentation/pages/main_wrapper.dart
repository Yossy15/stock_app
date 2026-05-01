import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
import '../../providers/stock_provider.dart';
import 'stock_list_page.dart';
import 'stock_dashboard_page.dart';
import 'stock_withdraw_page.dart';

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const StockListPage(),
    const StockWithdrawPage(),
    const StockDashboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (_selectedIndex != index) {
              // Reset search when leaving Stock List or switching tabs
              ref.read(stockListProvider.notifier).clearSearch();
              
              // If going to Dashboard or Withdraw page, refresh data to be real-time
              if (index == 1 || index == 2) {
                ref.read(stockListProvider.notifier).refresh();
              }
              
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: kPrimary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.package()),
              activeIcon: Icon(PhosphorIcons.package(PhosphorIconsStyle.fill))
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 200.ms),
              label: 'คลังสินค้า',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.export()),
              activeIcon: Icon(PhosphorIcons.export(PhosphorIconsStyle.fill))
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 200.ms),
              label: 'เบิกสินค้า',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.squaresFour()),
              activeIcon: Icon(PhosphorIcons.squaresFour(PhosphorIconsStyle.fill))
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 200.ms),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }
}
