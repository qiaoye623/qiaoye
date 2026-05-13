class AssetAccount {
  final int? id;
  final String name;
  final String icon;
  final String type;
  final double balance;
  final bool isDefault;

  const AssetAccount({
    this.id,
    required this.name,
    required this.icon,
    this.type = 'wallet',
    this.balance = 0.0,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'type': type,
      'balance': balance,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory AssetAccount.fromMap(Map<String, dynamic> map) {
    return AssetAccount(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      type: map['type'] as String? ?? 'wallet',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
    );
  }

  AssetAccount copyWith({
    int? id,
    String? name,
    String? icon,
    String? type,
    double? balance,
    bool? isDefault,
  }) {
    return AssetAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
