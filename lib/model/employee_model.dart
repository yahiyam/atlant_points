class Employee {
  final String id;
  final String mobile;
  final String name;
  final bool isAdmin; // <-- ADD THIS

  Employee({
    required this.id,
    required this.mobile,
    required this.name,
    this.isAdmin = false, // <-- Default to false
  });

  factory Employee.fromJson(Map<String, dynamic> json, String id) {
    return Employee(
      id: id,
      // Note: Your OTP page uses 'phone', but this model uses 'mobile'. Ensure consistency.
      mobile: json['mobile'] ?? json['phone'] ?? '',
      name: json['name'] ?? '',
      isAdmin: json['isAdmin'] ?? false, // <-- ADD THIS
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'name': name,
      'isAdmin': isAdmin, // <-- ADD THIS
    };
  }

  Employee copyWith({String? id, String? mobile, String? name, bool? isAdmin}) {
    return Employee(
      id: id ?? this.id,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      isAdmin: isAdmin ?? this.isAdmin, // <-- ADD THIS
    );
  }
}
