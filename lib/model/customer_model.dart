class Customer {
  final String id;
  final String mobile;
  final String name;

  Customer({required this.id, required this.mobile, required this.name});

  factory Customer.fromJson(Map<String, dynamic> json, String id) {
    return Customer(
      id: id,
      mobile: json['mobile'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'mobile': mobile, 'name': name};
  }

  Customer copyWith({String? id, String? mobile, String? name}) {
    return Customer(
      id: id ?? this.id,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
    );
  }
}

final Customer sampleCustomer = Customer(
  id: '12',
  mobile: "mobile",
  name: "name",
);
