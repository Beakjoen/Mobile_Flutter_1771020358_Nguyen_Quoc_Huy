class WalletTransaction {
  final int id;
  final int memberId;
  final double amount;
  final int type; // 0: Deposit, 1: Payment, 2: Refund
  final int status; // 0: Pending, 1: Completed, 2: Failed
  final String? description;
  final DateTime createdDate;

  WalletTransaction({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    required this.createdDate,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? json['Id'],
      memberId: json['memberId'] ?? json['MemberId'],
      amount: ((json['amount'] ?? json['Amount']) as num).toDouble(),
      type: json['type'] ?? json['Type'],
      status: json['status'] ?? json['Status'],
      description: json['description'] ?? json['Description'],
      createdDate: DateTime.parse(json['createdDate'] ?? json['CreatedDate']),
    );
  }
}
