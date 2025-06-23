import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atlant_points/model/customer_model.dart';
import 'package:atlant_points/model/point_category_model.dart';

class AtlantPointLog {
  final String id;
  final Customer customer;
  final int pointsAdded;
  final String employeeEmail;
  final DateTime timestamp;
  final List<PointCategory> categories;

  AtlantPointLog({
    required this.id,
    required this.customer,
    required this.pointsAdded,
    required this.employeeEmail,
    required this.timestamp,
    required this.categories,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer': customer.toJson(),
      'pointsAdded': pointsAdded,
      'employeeEmail': employeeEmail,
      'timestamp': Timestamp.fromDate(timestamp),
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }

  factory AtlantPointLog.fromJson(Map<String, dynamic> json, String id) {
    return AtlantPointLog(
      id: id,
      customer: Customer.fromJson(Map<String, dynamic>.from(json['customer']), id),
      pointsAdded: json['pointsAdded'] ?? 0,
      employeeEmail: json['employeeEmail'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      categories: (json['categories'] as List)
          .map((item) => PointCategory.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  AtlantPointLog copyWith({
    String? id,
    Customer? customer,
    int? pointsAdded,
    String? employeeEmail,
    DateTime? timestamp,
    List<PointCategory>? categories,
  }) {
    return AtlantPointLog(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      pointsAdded: pointsAdded ?? this.pointsAdded,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      timestamp: timestamp ?? this.timestamp,
      categories: categories ?? this.categories,
    );
  }
}
