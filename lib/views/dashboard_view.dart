import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../database/db_helper.dart';

class DashboardView extends StatefulWidget {
  final VoidCallback onRefreshNeeded;
  const DashboardView({super.key, required this.onRefreshNeeded});

  @override
  State<DashboardView> createState() => DashboardViewState();
}

class DashboardViewState extends State<DashboardView> {
  DashboardSummary? _summary;
  String _currency = '₹';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() => _isLoading = true);
    final summary = await DatabaseHelper.instance.getDashboardSummary();
    final cur = await DatabaseHelper.instance.getSetting('currency', defaultValue: '₹');
    if (mounted) {
      setState(() {
        _summary = summary;
        _currency = cur;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _summary == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final s = _summary!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const FarmLogoWidget(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('GOAT & FISH FARMING', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('Shared Business Ledger', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvailableFundsCard(s),
              const SizedBox(height: 14),
              _buildFinancialGrid(s),
              const SizedBox(height: 14),
              _buildDepartmentSummaries(s),
              const SizedBox(height: 16),
              _buildChartCard(s),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableFundsCard(DashboardSummary s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL AVAILABLE BUSINESS FUNDS',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(
            '$_currency ${s.remainingBalance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '= Total Investment + Total Income - Total Expenses',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
          ),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricSmall('Net Profit / Loss', '$_currency ${s.netProfitLoss.toStringAsFixed(2)}',
                  s.netProfitLoss >= 0 ? Colors.greenAccent : Colors.redAccent),
              _metricSmall("Today's Spent", '$_currency ${s.todayExpense.toStringAsFixed(2)}', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricSmall(String label, String value, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valColor, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFinancialGrid(DashboardSummary s) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _finCard('Total Investment', '$_currency ${s.totalInvestment.toStringAsFixed(2)}', Icons.account_balance, AppColors.investmentBlue),
        _finCard('Total Expenses', '$_currency ${s.totalExpense.toStringAsFixed(2)}', Icons.trending_down, AppColors.expenseRed),
        _finCard('Total Income', '$_currency ${s.totalIncome.toStringAsFixed(2)}', Icons.trending_up, AppColors.incomeGreen),
        _finCard('Monthly Expense', '$_currency ${s.monthlyExpense.toStringAsFixed(2)}', Icons.calendar_month, AppColors.warningOrange),
      ],
    );
  }

  Widget _finCard(String title, String val, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentSummaries(DashboardSummary s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BUSINESS BREAKDOWN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 8),
        _deptRow(
          title: 'Goat Business',
          icon: Icons.pets,
          inv: s.goatInvestment,
          exp: s.goatExpense,
          inc: s.goatIncome,
          profit: s.goatIncome - s.goatExpense,
        ),
        const SizedBox(height: 8),
        _deptRow(
          title: 'Fish Business',
          icon: Icons.water,
          inv: s.fishInvestment,
          exp: s.fishExpense,
          inc: s.fishIncome,
          profit: s.fishIncome - s.fishExpense,
        ),
        const SizedBox(height: 8),
        _deptRow(
          title: 'Common / Shared',
          icon: Icons.group_work,
          inv: s.commonInvestment,
          exp: s.commonExpense,
          inc: s.commonIncome,
          profit: s.commonIncome - s.commonExpense,
        ),
      ],
    );
  }

  Widget _deptRow({
    required String title,
    required IconData icon,
    required double inv,
    required double exp,
    required double inc,
    required double profit,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Text(
                  'Profit: $_currency ${profit.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: profit >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _subCol('Invested', '$_currency ${inv.toStringAsFixed(0)}'),
                _subCol('Expenses', '$_currency ${exp.toStringAsFixed(0)}'),
                _subCol('Income', '$_currency ${inc.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _subCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildChartCard(DashboardSummary s) {
    final maxVal = [s.totalInvestment, s.totalExpense, s.totalIncome].reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financial Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 14),
            SizedBox(
              height: 130,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxVal <= 0 ? 100.0 : maxVal * 1.25),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          switch (val.toInt()) {
                            case 0:
                              return const Text('Inv', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                            case 1:
                              return const Text('Exp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                            case 2:
                              return const Text('Inc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: s.totalInvestment, color: AppColors.investmentBlue, width: 22, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: s.totalExpense, color: AppColors.expenseRed, width: 22, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: s.totalIncome, color: AppColors.incomeGreen, width: 22, borderRadius: BorderRadius.circular(4))]),
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
