class TimerModel {
  int? timerId;
  String player;
  String? playerTag;
  String? villageType;
  int? upgradeId;
  String timerName;
  String? upgradeType;
  int? upgradeLevel;
  bool isExtra;
  DateTime readyDateTime;

  TimerModel({
    this.timerId,
    required this.player,
    required this.playerTag,
    required this.villageType,
    required this.upgradeId,
    required this.timerName,
    required this.upgradeType,
    required this.upgradeLevel,
    this.isExtra = false,
    required this.readyDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'timerId': timerId,
      'player': player,
      'playerTag': playerTag,
      'villageType': villageType,
      'upgradeId': upgradeId,
      'timerName': timerName,
      'upgradeType': upgradeType,
      'upgradeLevel': upgradeLevel,
      'Extra': isExtra ? 1 : 0,
      'readyDateTime': readyDateTime.toIso8601String(),
    };
  }

  factory TimerModel.fromMap(Map<String, dynamic> map) {
    return TimerModel(
      timerId: map['TimerId'],
      player: map['Player'],
      playerTag: map['PlayerTag'],
      villageType: map['VillageType'],
      upgradeId: map['UpgradeId'],
      timerName: map['TimerName'],
      upgradeType: map['UpgradeType'],
      upgradeLevel: map['UpgradeLevel'],
      isExtra: ((map['Extra'] as int?) ?? 0) == 1,
      readyDateTime: DateTime.parse(map['ReadyDateTime']),
    );
  }

  TimerModel copyWith({
    int? timerId,
    String? player,
    String? playerTag,
    String? villageType,
    int? upgradeId,
    String? timerName,
    String? upgradeType,
    int? upgradeLevel,
    bool? isExtra,
    DateTime? readyDateTime,
  }) {
    return TimerModel(
      timerId: timerId ?? this.timerId,
      player: player ?? this.player,
      playerTag: playerTag ?? this.playerTag,
      villageType: villageType ?? this.villageType,
      upgradeId: upgradeId ?? this.upgradeId,
      timerName: timerName ?? this.timerName,
      upgradeType: upgradeType ?? this.upgradeType,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      isExtra: isExtra ?? this.isExtra,
      readyDateTime: readyDateTime ?? this.readyDateTime,
    );
  }
}
