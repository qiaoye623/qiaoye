class RateItem {
  double odds;
  double rebate;
  String type;

  RateItem({
    required this.odds,
    required this.rebate,
    required this.type,
  });

  factory RateItem.fromJson(Map<String, dynamic> json) {
    return RateItem(
      odds: (json['odds'] as num?)?.toDouble() ?? 0,
      rebate: (json['rebate'] as num?)?.toDouble() ?? 0,
      type: (json['type'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'odds': odds,
        'rebate': rebate,
        'type': type,
      };
}

class RateConfig {
  Map<String, RateItem> items;

  RateConfig({Map<String, RateItem>? items})
      : items = items ??
            Map.fromEntries(_defaultData.entries.map((e) => MapEntry(
                  e.key,
                  RateItem(
                    odds: (e.value['odds'] as num).toDouble(),
                    rebate: (e.value['rebate'] as num).toDouble(),
                    type: e.value['type'] as String,
                  ),
                )));

  double getOdds(String playName) => items[playName]?.odds ?? 0;
  double getRebate(String playName) => items[playName]?.rebate ?? 0;

  RateConfig copyWith({Map<String, RateItem>? items}) {
    return RateConfig(items: items ?? this.items);
  }

  /// 更新单个玩法的赔率，返回新 RateConfig
  RateConfig withUpdatedOdds(String playName, double odds) {
    final newItems = Map<String, RateItem>.from(items);
    final existing = newItems[playName];
    newItems[playName] = RateItem(
      odds: odds,
      rebate: existing?.rebate ?? 0,
      type: existing?.type ?? '',
    );
    return RateConfig(items: newItems);
  }

  /// 更新单个玩法的返水，返回新 RateConfig
  RateConfig withUpdatedRebate(String playName, double rebate) {
    final newItems = Map<String, RateItem>.from(items);
    final existing = newItems[playName];
    newItems[playName] = RateItem(
      odds: existing?.odds ?? 0,
      rebate: rebate,
      type: existing?.type ?? '',
    );
    return RateConfig(items: newItems);
  }

  static const Map<String, Map<String, dynamic>> _defaultData = {
    '特码': {'odds': 45, 'rebate': 0.08, 'type': 'number'},
    '二中二': {'odds': 60, 'rebate': 0.05, 'type': 'twoNumbers'},
    '连特': {'odds': 55, 'rebate': 0.05, 'type': 'special'},
    '平肖': {'odds': 2, 'rebate': 0.05, 'type': 'animal'},
    '本肖马': {'odds': 1.8, 'rebate': 0.02, 'type': 'animal'},
    '二友': {'odds': 4, 'rebate': 0.05, 'type': 'animalGroup'},
    '二友带马': {'odds': 3.5, 'rebate': 0.05, 'type': 'animalGroup'},
    '三友': {'odds': 10, 'rebate': 0.05, 'type': 'animalGroup'},
    '三友带马': {'odds': 9, 'rebate': 0.05, 'type': 'animalGroup'},
    '四友': {'odds': 30, 'rebate': 0, 'type': 'animalGroup'},
    '四友带马': {'odds': 28, 'rebate': 0, 'type': 'animalGroup'},
    '五友': {'odds': 100, 'rebate': 0, 'type': 'animalGroup'},
    '五友带马': {'odds': 90, 'rebate': 0, 'type': 'animalGroup'},
    '特大小': {'odds': 1.8, 'rebate': 0.05, 'type': 'size'},
    '特单双': {'odds': 1.8, 'rebate': 0.05, 'type': 'oddEven'},
    '六肖中特': {'odds': 1.8, 'rebate': 0.05, 'type': 'multiAnimal'},
    '五肖中特': {'odds': 2, 'rebate': 0.05, 'type': 'multiAnimal'},
    '红波': {'odds': 2.5, 'rebate': 0.05, 'type': 'color'},
    '蓝波': {'odds': 2.6, 'rebate': 0.05, 'type': 'color'},
    '绿波': {'odds': 2.6, 'rebate': 0.05, 'type': 'color'},
    '独平': {'odds': 7, 'rebate': 0.05, 'type': 'singleFlat'},
    '五不中': {'odds': 2, 'rebate': 0, 'type': 'notHit'},
    '七不中': {'odds': 3, 'rebate': 0, 'type': 'notHit'},
    '九不中': {'odds': 4, 'rebate': 0, 'type': 'notHit'},
    '十不中': {'odds': 5, 'rebate': 0, 'type': 'notHit'},
    '尾数': {'odds': 1.8, 'rebate': 0.02, 'type': 'tail'},
    '0尾': {'odds': 2, 'rebate': 0.02, 'type': 'tail'},
    '二连尾': {'odds': 2.5, 'rebate': 0.05, 'type': 'consecutiveTail'},
    '三连尾': {'odds': 5, 'rebate': 0.04, 'type': 'consecutiveTail'},
    '四连尾': {'odds': 15, 'rebate': 0.04, 'type': 'consecutiveTail'},
  };

  static List<String> get playNames => _defaultData.keys.toList();

  factory RateConfig.fromJson(Map<String, dynamic> json) {
    if (json['items'] is Map) {
      final items = <String, RateItem>{};
      for (final entry in (json['items'] as Map).entries) {
        if (entry.value is Map) {
          items[entry.key] =
              RateItem.fromJson(entry.value as Map<String, dynamic>);
        }
      }
      return RateConfig(items: items);
    }
    return RateConfig();
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((k, v) => MapEntry(k, v.toJson())),
      };
}
