class Ledger {
  final int? id;
  final String name;
  final String icon;
  final bool isDefault;
  final int sortOrder;
  final String? createdAt;

  const Ledger({
    this.id,
    required this.name,
    this.icon = '📒',
    this.isDefault = false,
    this.sortOrder = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'isDefault': isDefault ? 1 : 0,
      'sortOrder': sortOrder,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Ledger.fromMap(Map<String, dynamic> map) {
    return Ledger(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '📒',
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: map['createdAt'] as String?,
    );
  }

  Ledger copyWith({
    int? id,
    String? name,
    String? icon,
    bool? isDefault,
    int? sortOrder,
    String? createdAt,
  }) {
    return Ledger(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
