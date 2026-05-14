class SavePlan {
  final int? id;
  final String name;
  final String type;
  final double startAmount;
  final int durationDays;
  final double incrementCoeff;
  final double monthAmount;
  final double totalTarget;
  final double currentAmount;
  final int iconCode;
  final String startDate;
  final String? createdAt;
  final String status;

  SavePlan({
    this.id,
    required this.name,
    required this.type,
    required this.startAmount,
    required this.durationDays,
    this.incrementCoeff = 0,
    this.monthAmount = 0,
    required this.totalTarget,
    this.currentAmount = 0,
    this.iconCode = 0,
    required this.startDate,
    this.createdAt,
    this.status = 'active',
  });

  String? get endDate {
    if (durationDays <= 0) return null;
    final parts = startDate.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final date = DateTime(year, month, day);
    final end = date.add(Duration(days: durationDays - 1));
    return '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'start_amount': startAmount,
        'duration_days': durationDays,
        'increment_coeff': incrementCoeff,
        'month_amount': monthAmount,
        'total_target': totalTarget,
        'current_amount': currentAmount,
        'icon_code': iconCode,
        'start_date': startDate,
        'created_at': createdAt,
        'status': status,
      };

  factory SavePlan.fromMap(Map<String, dynamic> map, {int? id}) {
    return SavePlan(
      id: id ?? map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      startAmount: (map['start_amount'] as num).toDouble(),
      durationDays: map['duration_days'] as int,
      incrementCoeff: (map['increment_coeff'] as num?)?.toDouble() ?? 0,
      monthAmount: (map['month_amount'] as num?)?.toDouble() ?? 0,
      totalTarget: (map['total_target'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0,
      iconCode: map['icon_code'] as int? ?? 0,
      startDate: map['start_date'] as String,
      createdAt: map['created_at'] as String?,
      status: map['status'] as String? ?? 'active',
    );
  }

  SavePlan copyWith({
    int? id,
    String? name,
    String? type,
    double? startAmount,
    int? durationDays,
    double? incrementCoeff,
    double? monthAmount,
    double? totalTarget,
    double? currentAmount,
    int? iconCode,
    String? startDate,
    String? createdAt,
    String? status,
  }) {
    return SavePlan(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startAmount: startAmount ?? this.startAmount,
      durationDays: durationDays ?? this.durationDays,
      incrementCoeff: incrementCoeff ?? this.incrementCoeff,
      monthAmount: monthAmount ?? this.monthAmount,
      totalTarget: totalTarget ?? this.totalTarget,
      currentAmount: currentAmount ?? this.currentAmount,
      iconCode: iconCode ?? this.iconCode,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
