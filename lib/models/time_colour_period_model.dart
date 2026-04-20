import 'package:flutter/material.dart';

class TimeColourPeriodModel {
  int? id;
  String label;
  int startHour;
  int endHour;
  int colourValue;

  TimeColourPeriodModel({
    this.id,
    required this.label,
    required this.startHour,
    required this.endHour,
    required this.colourValue,
  });

  factory TimeColourPeriodModel.fromMap(Map<String, dynamic> map) {
    return TimeColourPeriodModel(
      id: map['SettingId'] as int?,
      label: map['Label'] as String? ?? '',
      startHour: map['StartHour'] as int? ?? 0,
      endHour: map['EndHour'] as int? ?? 0,
      colourValue: map['ColourValue'] as int? ?? Colors.white.toARGB32(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'Label': label,
      'StartHour': startHour,
      'EndHour': endHour,
      'ColourValue': colourValue,
    };

    if (id != null) {
      map['SettingId'] = id;
    }

    return map;
  }

  bool matches(int hour) {
    if (startHour == endHour) {
      return false;
    }

    if (startHour < endHour) {
      return hour >= startHour && hour < endHour;
    }

    return hour >= startHour || hour < endHour;
  }

  Color get colour => Color(colourValue);
}
