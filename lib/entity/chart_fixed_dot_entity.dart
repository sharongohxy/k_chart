import 'dart:ui';

class ChartFixedDotEntity {
  String? label;
  Color? color;
  int? millisecond;
  double? backgroundPointRadius;
  double? foregroundPointRadius;

  ChartFixedDotEntity({
    required this.label,
    required this.color,
    required this.millisecond,
    this.backgroundPointRadius,
    this.foregroundPointRadius,
  });

  ChartFixedDotEntity.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    color = json['color'];
    millisecond = json['millisecond'];
    backgroundPointRadius = json['backgroundPointRadius'];
    foregroundPointRadius = json['foregroundPointRadius'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['label'] = this.label;
    data['color'] = this.color;
    data['millisecond'] = this.millisecond;
    data['backgroundPointRadius'] = this.backgroundPointRadius;
    data['foregroundPointRadius'] = this.foregroundPointRadius;
    return data;
  }
}
