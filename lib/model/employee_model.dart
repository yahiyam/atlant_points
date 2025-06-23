class Employee {
  final String id;
  final String mobile;
  final String name;

  Employee({required this.id, required this.mobile, required this.name});

  factory Employee.fromJson(Map<String, dynamic> json, String id) {
    return Employee(
      id: id,
      mobile: json['mobile'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'mobile': mobile, 'name': name};
  }

  Employee copyWith({String? id, String? mobile, String? name}) {
    return Employee(
      id: id ?? this.id,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
    );
  }
}

final Employee sampleEmployee = Employee(
  id: '12',
  mobile: "mobile",
  name: "name",
);
