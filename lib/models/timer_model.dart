class TimerModel {
  int? timerId;
  String player;
  String? villageType;
  int? upgradeId;
  String timerName;
  String? upgradeType;
  int? upgradeLevel;
  DateTime readyDateTime;

  TimerModel({
    this.timerId,
    required this.player,
    required this.villageType,
    required this.upgradeId,
    required this.timerName,
    required this.upgradeType,
    required this.upgradeLevel,
    required this.readyDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'timerId': timerId,
      'player': player,
      'villageType': villageType,
      'upgradeId': upgradeId,
      'timerName': timerName,
      'upgradeType': upgradeType,
      'upgradeLevel': upgradeLevel,
      'readyDateTime': readyDateTime.toIso8601String(),
    };
  }

  factory TimerModel.fromMap(Map<String, dynamic> map) {
    return TimerModel(
      timerId: map['TimerId'],
      player: map['Player'],
      villageType: map['VillageType'],
      upgradeId: map['UpgradeId'],
      timerName: map['TimerName'],
      upgradeType: map['UpgradeType'],
      upgradeLevel: map['UpgradeLevel'],
      readyDateTime: DateTime.parse(map['ReadyDateTime']),
    );
  }

  TimerModel copyWith({
    int? timerId,
    String? player,
    String? villageType,
    int? upgradeId,
    String? timerName,
    String? upgradeType,
    int? upgradeLevel,
    DateTime? expiry,
  }) {
    return TimerModel(
      timerId: timerId ?? this.timerId,
      player: player ?? this.player,
      villageType: villageType ?? this.villageType,
      upgradeId: upgradeId ?? this.upgradeId,
      timerName: timerName ?? this.timerName,
      upgradeType: upgradeType ?? this.upgradeType,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      readyDateTime: readyDateTime,
    );
  }
}
