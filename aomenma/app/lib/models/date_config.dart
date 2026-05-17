import 'rate_config.dart';

class DateConfig {
  String drawNo;
  String drawInfo;
  List<String> drawNumbers;
  int rateCode;
  int rateZodiac;
  RateConfig rateConfig;

  DateConfig({
    this.drawNo = '',
    this.drawInfo = '',
    this.drawNumbers = const [],
    this.rateCode = 45,
    this.rateZodiac = 2,
    RateConfig? rateConfig,
  }) : rateConfig = rateConfig ?? RateConfig();

  DateConfig copyWith({
    String? drawNo,
    String? drawInfo,
    List<String>? drawNumbers,
    int? rateCode,
    int? rateZodiac,
    RateConfig? rateConfig,
  }) {
    return DateConfig(
      drawNo: drawNo ?? this.drawNo,
      drawInfo: drawInfo ?? this.drawInfo,
      drawNumbers: drawNumbers ?? this.drawNumbers,
      rateCode: rateCode ?? this.rateCode,
      rateZodiac: rateZodiac ?? this.rateZodiac,
      rateConfig: rateConfig ?? this.rateConfig,
    );
  }

  factory DateConfig.fromJson(Map<String, dynamic> json) {
    return DateConfig(
      drawNo: json['drawNo'] as String? ?? '',
      drawInfo: json['drawInfo'] as String? ?? '',
      drawNumbers: (json['drawNumbers'] as List?)?.cast<String>() ?? [],
      rateCode: json['rateCode'] as int? ?? 45,
      rateZodiac: json['rateZodiac'] as int? ?? 2,
      rateConfig: json['rateConfig'] != null
          ? RateConfig.fromJson(json['rateConfig'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'drawNo': drawNo,
        'drawInfo': drawInfo,
        'drawNumbers': drawNumbers,
        'rateCode': rateCode,
        'rateZodiac': rateZodiac,
        'rateConfig': rateConfig.toJson(),
      };
}
