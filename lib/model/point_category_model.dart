class PointCategory {
  final String title;
  final int points;

  PointCategory({required this.title, required this.points});
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
