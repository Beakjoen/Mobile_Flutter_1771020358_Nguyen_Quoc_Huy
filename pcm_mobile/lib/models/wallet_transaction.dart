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
    // Helper to safe parse date
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      String dateStr = val.toString();
      // Handle .NET 7-digit precision by truncating to 6 (microseconds)
      if (dateStr.contains('.')) {
        int dotIndex = dateStr.indexOf('.');
        if (dateStr.length - dotIndex > 7) {
          dateStr = dateStr.substring(0, dotIndex + 7);
        }
      }
      return DateTime.tryParse(dateStr) ?? DateTime.now();
    }

    return WalletTransaction(
      id: json['id'] ?? json['Id'] ?? 0,
      memberId: json['memberId'] ?? json['MemberId'] ?? 0,
      amount: ((json['amount'] ?? json['Amount'] ?? 0) as num).toDouble(),
      type: json['type'] ?? json['Type'] ?? 0,
      status: json['status'] ?? json['Status'] ?? 0,
      description: json['description'] ?? json['Description'] ?? '',
      createdDate: parseDate(json['createdDate'] ?? json['CreatedDate']),
    );
  }
}
