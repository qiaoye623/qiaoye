class DailySummary {
  double totalBet;
  double totalWin;
  double totalRebate;
  double pay;
  int userCount;

  DailySummary({
    this.totalBet = 0.0,
    this.totalWin = 0.0,
    this.totalRebate = 0.0,
    this.pay = 0.0,
    this.userCount = 0,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      totalBet: (json['totalBet'] as num?)?.toDouble() ?? 0.0,
      totalWin: (json['totalWin'] as num?)?.toDouble() ?? 0.0,
      totalRebate: (json['totalRebate'] as num?)?.toDouble() ?? 0.0,
      pay: (json['pay'] as num?)?.toDouble() ?? 0.0,
      userCount: json['userCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalBet': totalBet,
        'totalWin': totalWin,
        'totalRebate': totalRebate,
        'pay': pay,
        'userCount': userCount,
      };
}
