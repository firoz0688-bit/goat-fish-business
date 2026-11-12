import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reports')),
    body: FutureBuilder(
      future: DatabaseHelper.instance.getDashboardSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: Text('No data'));
        final s = snapshot.data!;
        final items = <MapEntry<String, double>>[
          MapEntry('Total Investment', s.totalInvestment),
          MapEntry('Total Expenses', s.totalExpense),
          MapEntry('Total Income', s.totalIncome),
          MapEntry('Remaining Balance', s.remainingBalance),
          MapEntry('Net Profit / Loss', s.netProfitLoss),
          MapEntry('Goat Investment', s.goatInvestment),
          MapEntry('Fish Investment', s.fishInvestment),
          MapEntry('Common Investment', s.commonInvestment),
          MapEntry('Goat Expenses', s.goatExpense),
          MapEntry('Fish Expenses', s.fishExpense),
          MapEntry('Common Expenses', s.commonExpense),
          MapEntry('Goat Income', s.goatIncome),
          MapEntry('Fish Income', s.fishIncome),
          MapEntry('Common Income', s.commonIncome),
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Business Financial Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...items.map((e) => Card(child: ListTile(
              title: Text(e.key),
              trailing: Text(e.value.toStringAsFixed(2)),
            ))),
          ],
        );
      },
    ),
  );
}
