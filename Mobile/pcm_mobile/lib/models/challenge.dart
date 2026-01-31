/// Model kèo thách đấu (Duel) — 1vs1 với phần thưởng nhỏ.
class Challenge {
  final int id;
  final int challengerId;
  final String? challengerName;
  final int? opponentId;
  final String? opponentName;
  final double stakeAmount;
  final String status; // Pending, Accepted, Finished, Cancelled
  final int? winnerId;
  final String? winnerName;
  final String? message;
  final DateTime createdDate;
  final DateTime? acceptedDate;
  final DateTime? finishedDate;

  Challenge({
    required this.id,
    required this.challengerId,
    this.challengerName,
    this.opponentId,
    this.opponentName,
    required this.stakeAmount,
    required this.status,
    this.winnerId,
    this.winnerName,
    this.message,
    required this.createdDate,
    this.acceptedDate,
    this.finishedDate,
  });

  bool get isPending => status == 'Pending';
  bool get isAccepted => status == 'Accepted';
  bool get isFinished => status == 'Finished';
  bool get isCancelled => status == 'Cancelled';
  bool get canAccept => isPending;
  bool get canSetResult => isAccepted;
  bool get canCancel => isPending || isAccepted;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as int,
      challengerId: json['challengerId'] as int,
      challengerName: json['challengerName'] as String?,
      opponentId: json['opponentId'] as int?,
      opponentName: json['opponentName'] as String?,
      stakeAmount: (json['stakeAmount'] as num).toDouble(),
      status: json['status'] as String? ?? 'Pending',
      winnerId: json['winnerId'] as int?,
      winnerName: json['winnerName'] as String?,
      message: json['message'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
      acceptedDate: json['acceptedDate'] != null ? DateTime.parse(json['acceptedDate'] as String) : null,
      finishedDate: json['finishedDate'] != null ? DateTime.parse(json['finishedDate'] as String) : null,
    );
  }
}
