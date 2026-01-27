class Court {
  final int id;
  final String name;
  final double pricePerHour;
  final String? description;

  Court({
    required this.id,
    required this.name,
    required this.pricePerHour,
    this.description,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'],
      name: json['name'],
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      description: json['description'],
    );
  }
}
