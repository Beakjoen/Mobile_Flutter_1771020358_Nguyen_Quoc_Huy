import 'member.dart';
import 'court.dart';

class Booking {
  final int id;
  final int courtId;
  final int memberId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final int status; // 0: Pending, 1: Confirmed, 2: Cancelled
  final Member? member;
  final Court? court;

  Booking({
    required this.id,
    required this.courtId,
    required this.memberId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.member,
    this.court,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      courtId: json['courtId'],
      memberId: json['memberId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'],
      member: json['member'] != null ? Member.fromJson(json['member']) : null,
      court: json['court'] != null ? Court.fromJson(json['court']) : null,
    );
  }
}
