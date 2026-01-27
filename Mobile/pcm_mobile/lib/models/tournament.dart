class Tournament {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int format; // 0: Knockout, 1: RoundRobin
  final double entryFee;
  final double prizePool;
  final int status; // 0=Open, 1=Registering, 2=DrawCompleted, 3=Ongoing, 4=Finished

  Tournament({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.entryFee,
    required this.prizePool,
    required this.status,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      format: json['format'],
      entryFee: (json['entryFee'] as num).toDouble(),
      prizePool: (json['prizePool'] as num).toDouble(),
      status: json['status'],
    );
  }
}
