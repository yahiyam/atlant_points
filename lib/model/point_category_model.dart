class PointCategory {
  final String title;
  final int points;
  final String? description;

  PointCategory({
    required this.title,
    required this.points,
    this.description,
  });

  factory PointCategory.fromJson(Map<String, dynamic> json) {
    return PointCategory(
      title: json['title'] ?? '',
      points: json['points'] ?? 0,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'points': points,
      if (description != null) 'description': description,
    };
  }
}

// // Example categories
// final List<PointCategory> pointCategories = [
//   PointCategory(
//     title: 'One Month Recharge',
//     points: 5,
//     description: 'Recharge for one month and earn 5 points.',
//   ),
//   PointCategory(
//     title: 'Three Month Recharge',
//     points: 10,
//     description: 'Recharge for three months and earn 10 points.',
//   ),
//   PointCategory(
//     title: 'New SIM Activation',
//     points: 15,
//     description: 'Activate a new SIM and earn 15 points.',
//   ),
//   PointCategory(
//     title: 'Device Repair',
//     points: 20,
//     description: 'Repair a device and earn 20 points.',
//   ),
//   PointCategory(
//     title: 'Porting SIM Offer',
//     points: 25,
//     description: 'Port a SIM and get 25 points.',
//   ),
//   PointCategory(
//     title: 'Accessory Purchase',
//     points: 5,
//     description: 'Buy an accessory and earn 5 points.',
//   ),
//   PointCategory(
//     title: 'Bill Payment',
//     points: 5,
//     description: 'Pay a bill and earn 5 points.',
//   ), PointCategory(
//     title: 'Bill Payment',
//     points: 5,
//     description: 'Pay a bill and earn 5 points.',
//   ), PointCategory(
//     title: 'Bill Payment',
//     points: 5,
//     description: 'Pay a bill and earn 5 points.',
//   ), PointCategory(
//     title: 'Bill Payment',
//     points: 5,
//     description: 'Pay a bill and earn 5 points.',
//   ), PointCategory(
//     title: 'Bill Payment',
//     points: 5,
//     description: 'Pay a bill and earn 5 points.',
//   ), PointCategory(
//     title: 'Bill Payment',
//     points: 5,
//     description: 'Pay a bill and earn 5 points.',
//   ), PointCategory(
//     title: 'Bill Payment',
//     points: 5,
//     description: 'Pay a bill and earn 5 points.',
//   ),
//   PointCategory(
//     title: 'Combo Offer Sale',
//     points: 30,
//     description: 'Sell a combo offer and earn 30 points.',
//   ),
// ];