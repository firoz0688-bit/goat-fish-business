import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'database/db_helper.dart';
import 'views/dashboard_view.dart';
import 'views/investors_view.dart';
import 'views/transactions_view.dart';
import 'views/reports_view.dart';
import 'views/settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await DatabaseHelper.instance.database;
  runApp(const GoatFishFarmApp());
}

class GoatFishFarmApp extends StatelessWidget {
  const GoatFishFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goat & Fish Farming Business',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<DashboardViewState> _dashboardKey = GlobalKey<DashboardViewState>();

  void _onDataChanged() {
    _dashboardKey.currentState?.loadDashboard();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardView(key: _dashboardKey, onRefreshNeeded: _onDataChanged),
      InvestorsView(onDataChanged: _onDataChanged),
      TransactionsView(onDataChanged: _onDataChanged),
      const ReportsView(),
      SettingsView(onSettingsChanged: _onDataChanged),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: AppColors.primaryLight.withOpacity(0.2),
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 0) {
            _dashboardKey.currentState?.loadDashboard();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group, color: AppColors.primary),
            label: 'Investors',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Ledger',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment, color: AppColors.primary),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
