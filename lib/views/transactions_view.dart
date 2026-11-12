import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';

class TransactionsView extends StatefulWidget {
  final VoidCallback onDataChanged;
  const TransactionsView({super.key, required this.onDataChanged});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TransactionModel> _transactions = [];
  String _selectedBusinessType = 'All';
  String _currency = '₹';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _applyFilters();
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cur = await DatabaseHelper.instance.getSetting('currency', defaultValue: '₹');
    _currency = cur;
    await _applyFilters();
  }

  Future<void> _applyFilters() async {
    String? type;
    switch (_tabController.index) {
      case 1:
        type = 'investment';
        break;
      case 2:
        type = 'expense';
        break;
      case 3:
        type = 'income';
        break;
      default:
        type = null;
    }

    final txList = await DatabaseHelper.instance.getTransactions(
      type: type,
      businessType: _selectedBusinessType == 'All' ? null : _selectedBusinessType,
      searchQuery: _searchQuery,
    );

    if (mounted) {
      setState(() {
        _transactions = txList;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Ledger'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Investments'),
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search title, category...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedBusinessType,
                  underline: const SizedBox(),
                  items: ['All', 'Goat', 'Fish', 'Common'].map((b) {
                    return DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedBusinessType = val);
                      _applyFilters();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(child: Text('No transactions recorded yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, idx) {
                          final tx = _transactions[idx];
                          return _buildTransactionCard(tx);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddActionSheet(),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    Color typeColor;
    IconData icon;
    if (tx.type == 'investment') {
      typeColor = AppColors.investmentBlue;
      icon = Icons.account_balance_wallet;
    } else if (tx.type == 'expense') {
      typeColor = AppColors.expenseRed;
      icon = Icons.arrow_outward;
    } else {
      typeColor = AppColors.incomeGreen;
      icon = Icons.arrow_downward;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.12),
          child: Icon(icon, color: typeColor, size: 20),
        ),
        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          '${tx.date} • ${tx.businessType} • ${tx.category.isNotEmpty ? tx.category : tx.paymentMethod}'
          '${tx.investorName != null ? ' • ${tx.investorName}' : ''}',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${tx.type == 'expense' ? '-' : '+'} $_currency ${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: typeColor),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              onPressed: () => _confirmDeleteTx(tx),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTx(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Remove "${tx.title}" of $_currency ${tx.amount}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteTransaction(tx.id);
              if (mounted) {
                Navigator.pop(ctx);
                _applyFilters();
                widget.onDataChanged();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Financial Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.investmentBlue, child: Icon(Icons.person, color: Colors.white)),
              title: const Text('Add Investment', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Investor deposit into business'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddInvestmentSheet();
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.expenseRed, child: Icon(Icons.money_off, color: Colors.white)),
              title: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Goat purchase, feed, fuel, labour, snacks, etc.'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddExpenseSheet();
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.incomeGreen, child: Icon(Icons.attach_money, color: Colors.white)),
              title: const Text('Add Income', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Sale of goat, fish or other proceeds'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddIncomeSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAddInvestmentSheet() async {
    final investors = await DatabaseHelper.instance.getInvestors();
    if (investors.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add an investor first in Investor tab!')));
      }
      return;
    }

    String selectedInvId = investors.first.id;
    String selectedInvName = investors.first.name;
    String businessType = 'Common';
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Investment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedInvId,
                  decoration: const InputDecoration(labelText: 'Investor Name'),
                  items: investors.map((inv) => DropdownMenuItem(value: inv.id, child: Text(inv.name))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedInvId = val;
                        selectedInvName = investors.firstWhere((i) => i.id == val).name;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount ($_currency) *'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: businessType,
                  decoration: const InputDecoration(labelText: 'Business Type'),
                  items: ['Goat', 'Fish', 'Common'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) => setModalState(() => businessType = val!),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${DateFormat('yyyy-MM-dd').format(pickedDate)}'),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: pickedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setModalState(() => pickedDate = d);
                  },
                ),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Description / Notes')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                      if (amt <= 0) return;

                      final tx = TransactionModel(
                        id: const Uuid().v4(),
                        type: 'investment',
                        businessType: businessType,
                        title: 'Investment by $selectedInvName',
                        category: 'Partner Contribution',
                        amount: amt,
                        date: DateFormat('yyyy-MM-dd').format(pickedDate),
                        investorId: selectedInvId,
                        investorName: selectedInvName,
                        paymentMethod: 'Bank/Cash',
                        description: noteCtrl.text.trim(),
                        createdAt: DateTime.now().toIso8601String(),
                      );

                      await DatabaseHelper.instance.insertTransaction(tx);
                      if (mounted) {
                        Navigator.pop(ctx);
                        _applyFilters();
                        widget.onDataChanged();
                      }
                    },
                    child: const Text('Save Investment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAddExpenseSheet() {
    final titleCtrl = TextEditingController();
    final customCatCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String businessType = 'Goat';
    String paymentMethod = 'Cash';
    DateTime pickedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Business Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.expenseRed)),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Expense Title * (e.g. Goat purchase, Medicine, Fuel)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: customCatCtrl,
                  decoration: const InputDecoration(labelText: 'Category (e.g. Feed, Fuel, Labour, Travel, Electricity)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount ($_currency) *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: businessType,
                        decoration: const InputDecoration(labelText: 'Department'),
                        items: ['Goat', 'Fish', 'Common'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setModalState(() => businessType = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: const InputDecoration(labelText: 'Payment'),
                        items: ['Cash', 'Bank', 'UPI', 'Other'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setModalState(() => paymentMethod = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${DateFormat('yyyy-MM-dd').format(pickedDate)}'),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: pickedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setModalState(() => pickedDate = d);
                  },
                ),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description / Notes')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                      if (title.isEmpty || amt <= 0) return;

                      final cat = customCatCtrl.text.trim().isEmpty ? 'General Expense' : customCatCtrl.text.trim();

                      final tx = TransactionModel(
                        id: const Uuid().v4(),
                        type: 'expense',
                        businessType: businessType,
                        title: title,
                        category: cat,
                        amount: amt,
                        date: DateFormat('yyyy-MM-dd').format(pickedDate),
                        paymentMethod: paymentMethod,
                        description: descCtrl.text.trim(),
                        createdAt: DateTime.now().toIso8601String(),
                      );

                      await DatabaseHelper.instance.insertTransaction(tx);
                      if (mounted) {
                        Navigator.pop(ctx);
                        _applyFilters();
                        widget.onDataChanged();
                      }
                    },
                    child: const Text('Save Expense'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAddIncomeSheet() {
    final titleCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String businessType = 'Goat';
    String paymentMethod = 'Cash';
    DateTime pickedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Business Income', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.incomeGreen)),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Income Title * (e.g. Sold 4 Goats, Fish Harvest)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sourceCtrl,
                  decoration: const InputDecoration(labelText: 'Customer / Buyer Name (Optional)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount ($_currency) *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: businessType,
                        decoration: const InputDecoration(labelText: 'Source Dept'),
                        items: ['Goat', 'Fish', 'Common', 'Other'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setModalState(() => businessType = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: const InputDecoration(labelText: 'Payment'),
                        items: ['Cash', 'Bank', 'UPI', 'Other'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setModalState(() => paymentMethod = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${DateFormat('yyyy-MM-dd').format(pickedDate)}'),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: pickedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setModalState(() => pickedDate = d);
                  },
                ),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description / Notes')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.incomeGreen),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                      if (title.isEmpty || amt <= 0) return;

                      final tx = TransactionModel(
                        id: const Uuid().v4(),
                        type: 'income',
                        businessType: businessType,
                        title: title,
                        category: sourceCtrl.text.trim().isEmpty ? 'General Income' : sourceCtrl.text.trim(),
                        amount: amt,
                        date: DateFormat('yyyy-MM-dd').format(pickedDate),
                        paymentMethod: paymentMethod,
                        description: descCtrl.text.trim(),
                        createdAt: DateTime.now().toIso8601String(),
                      );

                      await DatabaseHelper.instance.insertTransaction(tx);
                      if (mounted) {
                        Navigator.pop(ctx);
                        _applyFilters();
                        widget.onDataChanged();
                      }
                    },
                    child: const Text('Save Income'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
