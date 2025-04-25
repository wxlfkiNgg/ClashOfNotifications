class BoostModel {
  int? id;
  double amount; // e.g., 10 for 10x speed
  Duration duration;
  DateTime startTime;
  List<int> affectedTimerIds;

  BoostModel({
    this.id,
    required this.amount,
    required this.duration,
    required this.startTime,
    required this.affectedTimerIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'duration': duration.inSeconds,
      'startTime': startTime.toIso8601String(),
      'affectedTimerIds': affectedTimerIds.join(','),
    };
  }

  factory BoostModel.fromMap(Map<String, dynamic> map) {
    return BoostModel(
      id: map['id'],
      amount: map['amount'],
      duration: Duration(seconds: map['duration']),
      startTime: DateTime.parse(map['startTime']),
      affectedTimerIds: (map['affectedTimerIds'] as String).split(',').map((id) => int.parse(id)).toList(),
    );
  }
}
