import 'package:flutter/material.dart';

class PlayerModel {
  int? id;
  String name;
  String tag;
  int colourValue;

  PlayerModel({
    this.id,
    required this.name,
    required this.tag,
    required this.colourValue,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['PlayerId'] as int?,
      name: map['Name'] as String? ?? '',
      tag: map['Tag'] as String? ?? '',
      colourValue: map['ColourValue'] as int? ?? Colors.grey.toARGB32(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'Name': name,
      'Tag': tag,
      'ColourValue': colourValue,
    };

    if (id != null) {
      map['PlayerId'] = id;
    }

    return map;
  }

  Color get colour => Color(colourValue);
}