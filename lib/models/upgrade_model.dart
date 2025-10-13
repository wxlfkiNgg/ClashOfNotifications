class UpgradeModel {
  int? recordId;
  int? upgradeId;
  String? upgradeName;
  String? upgradeType;

  UpgradeModel({
    this.recordId,
    required this.upgradeId,
    required this.upgradeName,
    required this.upgradeType,
  });

  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'upgradeId': upgradeId,
      'upgradeName': upgradeName,
      'upgradeType': upgradeType,
    };
  }

  factory UpgradeModel.fromMap(Map<String, dynamic> map) {
    return UpgradeModel(
      recordId: map['recordId'],
      upgradeId: map['upgradeId'],
      upgradeName: map['upgradeName'],
      upgradeType: map['upgradeType'],
    );
  }

  UpgradeModel copyWith({
    int? recordId,
    int? upgradeId,
    String? upgradeName,
    String? upgradeType,
  }) {
    return UpgradeModel(
      recordId: recordId ?? this.recordId,
      upgradeId: upgradeId ?? this.upgradeId,
      upgradeName: upgradeName ?? this.upgradeName,
      upgradeType: upgradeType ?? this.upgradeType,
    );
  }
}
