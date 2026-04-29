import 'package:flutter/material.dart';

class PlayerModel {
  int? id;
  String name;
  String tag;
  int colourValue;
  bool active;
  int displayOrder;
  bool exportClockTowerBoost;
  bool exportHelperTimer;
  bool exportBuilderBaseUpgrades;

  PlayerModel({
    this.id,
    required this.name,
    required this.tag,
    required this.colourValue,
    this.active = true,
    this.displayOrder = 0,
    this.exportClockTowerBoost = true,
    this.exportHelperTimer = true,
    this.exportBuilderBaseUpgrades = true,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['PlayerId'] as int?,
      name: map['Name'] as String? ?? '',
      tag: map['Tag'] as String? ?? '',
      colourValue: map['ColourValue'] as int? ?? Colors.grey.toARGB32(),
      active: ((map['Active'] as int?) ?? 1) == 1,
      displayOrder: (map['DisplayOrder'] as int?) ?? 0,
      exportClockTowerBoost: ((map['ExportClockTowerBoost'] as int?) ?? 1) == 1,
      exportHelperTimer: ((map['ExportHelperTimer'] as int?) ?? 1) == 1,
      exportBuilderBaseUpgrades: ((map['ExportBuilderBaseUpgrades'] as int?) ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'Name': name,
      'Tag': tag,
      'ColourValue': colourValue,
      'Active': active ? 1 : 0,
      'DisplayOrder': displayOrder,
      'ExportClockTowerBoost': exportClockTowerBoost ? 1 : 0,
      'ExportHelperTimer': exportHelperTimer ? 1 : 0,
      'ExportBuilderBaseUpgrades': exportBuilderBaseUpgrades ? 1 : 0,
    };

    if (id != null) {
      map['PlayerId'] = id;
    }

    return map;
  }

  Color get colour => Color(colourValue);
}