class Customer {
  final String id;
  final String mobile;
  final String name;
  final int points;

  Customer({
    required this.id,
    required this.mobile,
    required this.name,
    required this.points,
  });

  factory Customer.fromJson(Map<String, dynamic> json, String id) {
    return Customer(
      id: id,
      mobile: json['mobile'] ?? '',
      name: json['name'] ?? '',
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'mobile': mobile, 'name': name, 'points': points};
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

final Customer sampleCustomer = Customer(
  id: '12',
  mobile: "mobile",
  name: "name",
  points: 25,
);
