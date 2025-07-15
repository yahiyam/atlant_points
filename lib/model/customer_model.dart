class Customer {
  final String id;
  final String mobile;
  final String name;
  final int? points;

  Customer({
    required this.id,
    required this.mobile,
    required this.name,
    this.points,
  });

  factory Customer.fromJson(Map<String, dynamic> json, String id) {
    return Customer(
      id: id,
      mobile: json['mobile'] ?? '',
      name: json['name'] ?? '',
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'name': name,
      if (points != null) 'points': points,
    };
  }

  Customer copyWith({String? id, String? mobile, String? name, int? points}) {
    return Customer(
      id: id ?? this.id,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      points: points ?? this.points,
    );
  }
}
