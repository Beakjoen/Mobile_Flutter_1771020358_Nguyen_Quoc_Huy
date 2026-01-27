/// Một trận trong giải (dùng cho tab Nhánh đấu - dữ liệu từ API /tournaments/{id}/matches)
class TournamentMatch {
  final int id;
  final String roundName;
  final String date;
  final String startTime;
  final String team1Name;
  final String team2Name;
  final int score1;
  final int score2;
  final String? details;
  final int status; // 0=Scheduled, 1=InProgress, 2=Finished

  TournamentMatch({
    required this.id,
    required this.roundName,
    required this.date,
    required this.startTime,
    required this.team1Name,
    required this.team2Name,
    required this.score1,
    required this.score2,
    this.details,
    required this.status,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'],
      roundName: json['roundName'] ?? '',
      date: json['date']?.toString().split('T').first ?? '',
      startTime: json['startTime'] ?? '',
      team1Name: json['team1Name'] ?? '?',
      team2Name: json['team2Name'] ?? '?',
      score1: (json['score1'] as num?)?.toInt() ?? 0,
      score2: (json['score2'] as num?)?.toInt() ?? 0,
      details: json['details']?.toString(),
      status: (json['status'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isFinished => status == 2;
  String get scoreText => isFinished ? '$score1 - $score2' : 'vs';
}
