class HelperModel {
  int? id;
  String player;
  String type;
  int amount;

  HelperModel({
    this.id,
    required this.player,
    required this.type,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player': player,
      'type': type,
      'amount': amount,
    };
  }

  factory HelperModel.fromMap(Map<String, dynamic> map) {
    return HelperModel(
      id: map['id'],
      player: map['player'],
      type: map['type'],
      amount: map['amount'],
    );
  }

  HelperModel copyWith({
    int? id,
    String? player,
    String? type,
    int? amount,
  }) {
    return HelperModel(
      id: id ?? this.id,
      player: player ?? this.player,
      type: type ?? this.type,
      amount: amount ?? this.amount,
    );
  }
}
