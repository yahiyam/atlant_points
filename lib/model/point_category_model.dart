class PointCategory {
  final String title;
  final int points;

  PointCategory({required this.title, required this.points});

  factory PointCategory.fromJson(Map<String, dynamic> json) {
    return PointCategory(
      title: json['title'] ?? '',
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'points': points};
  }

  PointCategory copyWith({String? title, int? points}) {
    return PointCategory(
      title: title ?? this.title,
      points: points ?? this.points,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointCategory &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          points == other.points;

  @override
  int get hashCode => title.hashCode ^ points.hashCode;
}

final List<PointCategory> pointCategories = [
  PointCategory(title: 'One Month Recharge', points: 5),
  PointCategory(title: 'Three Month Recharge', points: 10),
  PointCategory(title: 'New SIM Activation', points: 15),
  PointCategory(title: 'Device Repair', points: 20),
  PointCategory(title: 'Porting SIM Offer', points: 25),
  PointCategory(title: 'Accessory Purchase', points: 5),
  PointCategory(title: 'Bill Payment', points: 5),
  PointCategory(title: 'Combo Offer Sale', points: 30),
];
