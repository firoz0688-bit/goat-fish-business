class Investor {
  final String id;
  final String name;
  final String phone;
  final String notes;
  final int isActive;
  final String createdAt;

  Investor({
    required this.id,
    required this.name,
    this.phone = '',
    this.notes = '',
    this.isActive = 1,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'notes': notes,
    'is_active': isActive,
    'created_at': createdAt,
  };

  factory Investor.fromMap(Map<String, dynamic> map) => Investor(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    phone: map['phone'] ?? '',
    notes: map['notes'] ?? '',
    isActive: map['is_active'] ?? 1,
    createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
  );
}

class TransactionModel {
  final String id;
  final String type; // 'investment', 'expense', 'income'
  final String businessType; // 'Goat', 'Fish', 'Common'
  final String title;
  final String category;
  final double amount;
  final String date; // YYYY-MM-DD
  final String? investorId;
  final String? investorName;
  final String paymentMethod;
  final String description;
  final String? receiptPath;
  final String createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.businessType,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.investorId,
    this.investorName,
    this.paymentMethod = 'Cash',
    this.description = '',
    this.receiptPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'business_type': businessType,
    'title': title,
    'category': category,
    'amount': amount,
    'date': date,
    'investor_id': investorId,
    'investor_name': investorName,
    'payment_method': paymentMethod,
    'description': description,
    'receipt_path': receiptPath,
    'created_at': createdAt,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
    id: map['id'] ?? '',
    type: map['type'] ?? '',
    businessType: map['business_type'] ?? 'Goat',
    title: map['title'] ?? '',
    category: map['category'] ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    date: map['date'] ?? '',
    investorId: map['investor_id'],
    investorName: map['investor_name'],
    paymentMethod: map['payment_method'] ?? 'Cash',
    description: map['description'] ?? '',
    receiptPath: map['receipt_path'],
    createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
  );
}

class DashboardSummary {
  final double totalInvestment;
  final double totalExpense;
  final double totalIncome;
  final double remainingBalance;
  final double netProfitLoss;
  final double goatInvestment;
  final double fishInvestment;
  final double commonInvestment;
  final double goatExpense;
  final double fishExpense;
  final double commonExpense;
  final double goatIncome;
  final double fishIncome;
  final double commonIncome;
  final double todayInvestment;
  final double todayExpense;
  final double monthlyInvestment;
  final double monthlyExpense;

  DashboardSummary({
    required this.totalInvestment,
    required this.totalExpense,
    required this.totalIncome,
    required this.remainingBalance,
    required this.netProfitLoss,
    required this.goatInvestment,
    required this.fishInvestment,
    required this.commonInvestment,
    required this.goatExpense,
    required this.fishExpense,
    required this.commonExpense,
    required this.goatIncome,
    required this.fishIncome,
    required this.commonIncome,
    required this.todayInvestment,
    required this.todayExpense,
    required this.monthlyInvestment,
    required this.monthlyExpense,
  });
}
