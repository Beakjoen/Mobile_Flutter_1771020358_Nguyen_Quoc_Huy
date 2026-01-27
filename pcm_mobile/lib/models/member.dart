class Member {
  final int id;
  final String fullName;
  final double rankLevel;
  final double walletBalance;
  final int tier;
  final String? avatarUrl;
  final String? email;
  final String? phoneNumber;
  final List<String> roles;

  Member({
    required this.id,
    required this.fullName,
    required this.rankLevel,
    required this.walletBalance,
    required this.tier,
    this.avatarUrl,
    this.email,
    this.phoneNumber,
    this.roles = const [],
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      fullName: json['fullName'],
      rankLevel: (json['rankLevel'] as num).toDouble(),
      walletBalance: (json['walletBalance'] as num).toDouble(),
      tier: json['tier'],
      avatarUrl: json['avatarUrl'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : (json['Roles'] != null ? List<String>.from(json['Roles']) : []),
    );
  }
}
