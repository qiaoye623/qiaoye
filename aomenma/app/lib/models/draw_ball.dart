class DrawBall {
  final String number;
  final String zodiac;
  final String element;
  final bool isSpecial;

  const DrawBall({
    required this.number,
    required this.zodiac,
    required this.element,
    this.isSpecial = false,
  });
}

class DrawResult {
  final String period;
  final List<DrawBall> balls;
  final String specialNumber;

  const DrawResult({
    this.period = '',
    this.balls = const [],
    this.specialNumber = '',
  });

  bool get isEmpty => balls.isEmpty;
}
