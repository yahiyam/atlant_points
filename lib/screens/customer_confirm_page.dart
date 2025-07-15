import 'package:atlant_points/model/customer_model.dart';
import 'package:atlant_points/model/point_category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import '../widgets/customer_info_card.dart';

class CustomerConfirmPage extends StatefulWidget {
  final Customer customer;
  final List<PointCategory> selectedCategories;

  const CustomerConfirmPage({
    super.key,
    required this.customer,
    required this.selectedCategories,
  });

  @override
  State<CustomerConfirmPage> createState() => _CustomerConfirmPageState();
}

class _CustomerConfirmPageState extends State<CustomerConfirmPage> {
  bool isSubmitting = false;
  late Set<PointCategory> selectedCategories;

  @override
  void initState() {
    super.initState();
    selectedCategories = Set.from(widget.selectedCategories);
  }

  Future<void> _submitPoints() async {
    setState(() => isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Employee not logged in");

      final totalPoints = selectedCategories.fold<int>(
        0,
        (previousPoints, category) => previousPoints + category.points,
      );

      // 1. Add to logs collection
      await FirebaseFirestore.instance.collection('logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'employeeId': user.uid,
        'customer': {
          'id': widget.customer.id,
          'name': widget.customer.name,
          'mobile': widget.customer.mobile,
        },
        'pointsAdded': totalPoints,
        'categories': selectedCategories
            .map((c) => {'title': c.title, 'points': c.points})
            .toList(),
      });

      // 2. Update totalPoints in customer document
      final customerRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customer.id);

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(customerRef);
        final currentPoints = snap.data()?['totalPoints'] ?? 0;
        txn.update(customerRef, {
          'totalPoints': currentPoints + totalPoints,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // ✅ Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Success 🎉'),
            content: Text(
              '${widget.customer.name} has been awarded $totalPoints points.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit points: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsToAdd = selectedCategories.fold<int>(
      0,
      (previousPoints, category) => previousPoints + category.points,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Points')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomerInfoCard(customer: widget.customer),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selected Categories:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            ...selectedCategories.map(
              (cat) => Dismissible(
                key: ValueKey(cat.title),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  setState(() => selectedCategories.remove(cat));
                },
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.orangeAccent),
                  title: Text(cat.title),
                  trailing: Text('+${cat.points} pts'),
                ),
              ),
            ),
            const Divider(height: 32),
            Text(
              'Points to Add: $pointsToAdd',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Submit Points'),
                    onPressed: selectedCategories.isNotEmpty
                        ? _submitPoints
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
