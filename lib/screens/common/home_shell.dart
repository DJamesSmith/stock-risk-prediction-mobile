import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../state/session.dart';
import '../admin/admin_home_screen.dart';
import '../admin/users_screen.dart';
import '../analyst/analyst_home_screen.dart';
import '../investor/investor_home_screen.dart';
import '../investor/stock_lookup_screen.dart';
import '../shared/portfolio_list_screen.dart';
import 'profile_screen.dart';

class HomeTab {
  const HomeTab({required this.label, required this.icon, required this.selectedIcon, required this.page});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  List<HomeTab> _tabsFor(AppUser user) {
    const HomeTab profile = HomeTab(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      page: ProfileScreen(),
    );

    if (user.isAdmin) {
      return const [
        HomeTab(label: 'Home', icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard, page: AdminHomeScreen()),
        HomeTab(label: 'Users', icon: Icons.group_outlined, selectedIcon: Icons.group, page: UsersScreen()),
        HomeTab(
          label: 'Portfolios',
          icon: Icons.folder_outlined,
          selectedIcon: Icons.folder,
          page: PortfolioListScreen(title: 'All portfolios'),
        ),
        profile,
      ];
    }

    if (user.isAnalyst) {
      return const [
        HomeTab(label: 'Home', icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard, page: AnalystHomeScreen()),
        HomeTab(
          label: 'Clients',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          page: PortfolioListScreen(title: 'Client portfolios'),
        ),
        profile,
      ];
    }

    return const [
      HomeTab(label: 'Home', icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard, page: InvestorHomeScreen()),
      HomeTab(
        label: 'Portfolios',
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder,
        page: PortfolioListScreen(title: 'My portfolios', canCreate: true),
      ),
      HomeTab(label: 'Stocks', icon: Icons.candlestick_chart_outlined, selectedIcon: Icons.candlestick_chart, page: StockLookupScreen()),
      profile,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.select<Session, AppUser?>((session) => session.user);

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final List<HomeTab> tabs = _tabsFor(user);
    final int index = _index < tabs.length ? _index : 0;

    return Scaffold(
      body: IndexedStack(
        key: ValueKey(user.role),
        index: index,
        children: tabs.map((tab) => tab.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (final HomeTab tab in tabs)
            NavigationDestination(icon: Icon(tab.icon), selectedIcon: Icon(tab.selectedIcon), label: tab.label),
        ],
      ),
    );
  }
}
