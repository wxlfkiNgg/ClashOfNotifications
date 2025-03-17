class TimerModel {
  int? id;
  String player;
  String village;
  String upgrade;
  DateTime expiry;
  bool isFinished;

  TimerModel({
    this.id,
    required this.player,
    required this.village,
    required this.upgrade,
    required this.expiry,
    this.isFinished = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player': player,
      'village': village,
      'upgrade': upgrade,
      'expiry': expiry.toIso8601String(),
      'isFinished' : isFinished ? 1 : 0,
    };
  }

  factory TimerModel.fromMap(Map<String, dynamic> map) {
    return TimerModel(
      id: map['id'],
      player: map['player'],
      village: map['village'],
      upgrade: map['upgrade'],
      expiry: DateTime.parse(map['expiry']),
      isFinished: map['isFinished'] == 1, // Convert int to bool
    );
  }
}
