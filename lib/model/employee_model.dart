class Employee {
  final String id;
  final String mobile;
  final String name;
  final bool isAdmin;
  final String? email;     // <-- ADDED
  final String? password;  // <-- ADDED

  Employee({
    required this.id,
    required this.mobile,
    required this.name,
    this.isAdmin = false,
    this.email,            // <-- ADDED
    this.password,         // <-- ADDED
  });

  factory Employee.fromJson(Map<String, dynamic> json, String id) {
    return Employee(
      id: id,
      mobile: json['mobile'] ?? json['phone'] ?? '',
      name: json['name'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      email: json['email'],        // <-- ADDED
      password: json['password'],  // <-- ADDED
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'name': name,
      'isAdmin': isAdmin,
      'email': email,        // <-- ADDED
      'password': password,  // <-- ADDED
    };
  }

  Employee copyWith({
    String? id,
    String? mobile,
    String? name,
    bool? isAdmin,
    String? email,        // <-- ADDED
    String? password,     // <-- ADDED
  }) {
    return Employee(
      id: id ?? this.id,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      isAdmin: isAdmin ?? this.isAdmin,
      email: email ?? this.email,         // <-- ADDED
      password: password ?? this.password,// <-- ADDED
    );
  }
}