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
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      type: map['type'] as String,
      categoryId: map['categoryId'] as int,
      categoryName: map['categoryName'] as String,
      categoryIcon: map['categoryIcon'] as String,
      note: map['note'] as String? ?? '',
      date: map['date'] as String,
      createdAt: map['createdAt'] as String?,
      ledgerId: map['ledgerId'] as int? ?? 1,
    );
  }
}
