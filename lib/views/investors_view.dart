import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';

class InvestorsView extends StatefulWidget {
  final VoidCallback onDataChanged;
  const InvestorsView({super.key, required this.onDataChanged});

  @override
  State<InvestorsView> createState() => _InvestorsViewState();
}

class _InvestorsViewState extends State<InvestorsView> {
  List<Investor> _investors = [];
  Map<String, double> _contributions = {};
  String _currency = '₹';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadInvestors();
  }

  Future<void> loadInvestors() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getInvestors();
    final map = await DatabaseHelper.instance.getInvestorContributions();
    final cur = await DatabaseHelper.instance.getSetting('currency', defaultValue: '₹');
    if (mounted) {
      setState(() {
        _investors = list;
        _contributions = map;
        _currency = cur;
        _isLoading = false;
      });
    }
  }

  double get totalAllInvestorsContribution {
    return _contributions.values.fold(0.0, (sum, val) => sum + val);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investor Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Investor',
            onPressed: () => _openInvestorDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: AppColors.primary.withOpacity(0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Investors Contribution', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text('$_currency ${totalAllInvestorsContribution.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                Chip(
                  label: Text('${_investors.length} Members'),
                  backgroundColor: AppColors.primary,
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _investors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final inv = _investors[index];
                final contributed = _contributions[inv.id] ?? 0.0;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      child: Text(inv.name.isNotEmpty ? inv.name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (inv.phone.isNotEmpty) Text(inv.phone, style: const TextStyle(fontSize: 11)),
                        Text('Total: $_currency ${contributed.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.investmentBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: AppColors.textMuted),
                          onPressed: () => _openInvestorDialog(investor: inv),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _confirmDeleteInvestor(inv),
                        ),
                      ],
                    ),
                    onTap: () => _viewInvestorHistory(inv),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openInvestorDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Investor', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _openInvestorDialog({Investor? investor}) {
    final nameCtrl = TextEditingController(text: investor?.name ?? '');
    final phoneCtrl = TextEditingController(text: investor?.phone ?? '');
    final notesCtrl = TextEditingController(text: investor?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(investor == null ? 'Add New Investor' : 'Edit Investor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Investor Name *')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number (Optional)')),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (Optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                if (investor == null) {
                  final newInv = Investor(
                    id: const Uuid().v4(),
                    name: name,
                    phone: phoneCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  await DatabaseHelper.instance.insertInvestor(newInv);
                } else {
                  final updated = Investor(
                    id: investor.id,
                    name: name,
                    phone: phoneCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                    isActive: investor.isActive,
                    createdAt: investor.createdAt,
                  );
                  await DatabaseHelper.instance.updateInvestor(updated);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  loadInvestors();
                  widget.onDataChanged();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteInvestor(Investor inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${inv.name}?'),
        content: const Text(
          'Deleting this investor will remove them from future selections.\n\nNOTE: Historical investments and financial records remain safe and preserved in the ledger.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteInvestor(inv.id);
              if (mounted) {
                Navigator.pop(ctx);
                loadInvestors();
                widget.onDataChanged();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewInvestorHistory(Investor inv) async {
    final history = await DatabaseHelper.instance.getTransactions(investorId: inv.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                  ),
                  const SizedBox(height: 12),
                  Text('${inv.name} - Deposit History', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Total: $_currency ${(_contributions[inv.id] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: history.isEmpty
                        ? const Center(child: Text('No investment records found.'))
                        : ListView.builder(
                            controller: controller,
                            itemCount: history.length,
                            itemBuilder: (context, i) {
                              final item = history[i];
                              return ListTile(
                                dense: true,
                                title: Text(item.title.isNotEmpty ? item.title : 'Investment Deposit'),
                                subtitle: Text('${item.date} • ${item.businessType}'),
                                trailing: Text(
                                  '$_currency ${item.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.investmentBlue),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
