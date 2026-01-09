class Expense {
  final int? id;
  final String category;
  final double amount;
  final String date;
  final String? supabaseId;
  final bool isSynced;

  Expense({
    this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.supabaseId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': date,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      amount: map['amount'],
      date: map['date'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
    );
  }
}
