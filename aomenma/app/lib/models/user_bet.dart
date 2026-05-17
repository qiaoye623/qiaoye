class UserBet {
  String id;
  String name;
  String rawInput;
  String codeBets;
  String zodiacBets;
  String playBets;
  double totalBet;
  int winCodeCount;
  int winZodiacCount;
  int playWinCount;
  double winMoney;
  double rebate;

  UserBet({
    required this.id,
    this.name = '',
    this.rawInput = '',
    this.codeBets = '',
    this.zodiacBets = '',
    this.playBets = '',
    this.totalBet = 0.0,
    this.winCodeCount = 0,
    this.winZodiacCount = 0,
    this.playWinCount = 0,
    this.winMoney = 0.0,
    this.rebate = 0.0,
  });

  factory UserBet.fromJson(Map<String, dynamic> json) {
    return UserBet(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rawInput: json['rawInput'] as String? ?? '',
      codeBets: json['codeBets'] as String? ?? '',
      zodiacBets: json['zodiacBets'] as String? ?? '',
      playBets: json['playBets'] as String? ?? '',
      totalBet: (json['totalBet'] as num?)?.toDouble() ?? 0.0,
      winCodeCount: json['winCodeCount'] as int? ?? 0,
      winZodiacCount: json['winZodiacCount'] as int? ?? 0,
      playWinCount: json['playWinCount'] as int? ?? 0,
      winMoney: (json['winMoney'] as num?)?.toDouble() ?? 0.0,
      rebate: (json['rebate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rawInput': rawInput,
        'codeBets': codeBets,
        'zodiacBets': zodiacBets,
        'playBets': playBets,
        'totalBet': totalBet,
        'winCodeCount': winCodeCount,
        'winZodiacCount': winZodiacCount,
        'playWinCount': playWinCount,
        'winMoney': winMoney,
        'rebate': rebate,
      };
}
