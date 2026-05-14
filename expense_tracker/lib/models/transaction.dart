class Transaction {
  final int? id;
  final double amount;
  final String type;
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String note;
  final String date;
  final String createdAt;
  final int ledgerId;
  final int? accountId;

  Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    this.note = '',
    required this.date,
    String? createdAt,
    this.ledgerId = 1,
    this.accountId,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'note': note,
      'date': date,
      'createdAt': createdAt,
      'ledgerId': ledgerId,
      'accountId': accountId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['categoryId'] as int,
      categoryName: map['categoryName'] as String,
      categoryIcon: map['categoryIcon'] as String,
      note: map['note'] as String? ?? '',
      date: map['date'] as String,
      createdAt: map['createdAt'] as String?,
      ledgerId: map['ledgerId'] as int? ?? 1,
      accountId: map['accountId'] as int?,
    );
  }

  Transaction copyWith({
    int? id,
    double? amount,
    String? type,
    int? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? note,
    String? date,
    String? createdAt,
    int? ledgerId,
    int? accountId,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      ledgerId: ledgerId ?? this.ledgerId,
      accountId: accountId ?? this.accountId,
    );
  }
}
