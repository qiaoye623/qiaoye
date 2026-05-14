class SaveRecord {
  final int? id;
  final int planId;
  final int sequenceIndex;
  final double targetAmount;
  final double savedAmount;
  final String status;
  final String? savedDate;
  final String? createdAt;

  SaveRecord({
    this.id,
    required this.planId,
    required this.sequenceIndex,
    required this.targetAmount,
    this.savedAmount = 0,
    this.status = 'pending',
    this.savedDate,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'plan_id': planId,
        'sequence_index': sequenceIndex,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'status': status,
        'saved_date': savedDate,
        'created_at': createdAt,
      };

  factory SaveRecord.fromMap(Map<String, dynamic> map, {int? id}) {
    return SaveRecord(
      id: id ?? map['id'] as int?,
      planId: map['plan_id'] as int,
      sequenceIndex: map['sequence_index'] as int,
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      savedDate: map['saved_date'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  SaveRecord copyWith({
    int? id,
    int? planId,
    int? sequenceIndex,
    double? targetAmount,
    double? savedAmount,
    String? status,
    String? savedDate,
    String? createdAt,
  }) {
    return SaveRecord(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      status: status ?? this.status,
      savedDate: savedDate ?? this.savedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
