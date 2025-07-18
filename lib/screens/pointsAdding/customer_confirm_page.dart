import 'package:atlant_points/model/customer_model.dart';
import 'package:atlant_points/model/point_category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../home_page.dart';
import '../../widgets/customer_info_card.dart';

class CustomerConfirmPage extends StatefulWidget {
  final Customer customer;
  final Map<PointCategory, int> selectedCategories;

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

  Future<void> _submitPoints() async {
    setState(() => isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Employee not logged in");

      final totalPoints = widget.selectedCategories.entries.fold<int>(
        0,
        (sum, entry) => sum + entry.key.points * entry.value,
      );

      await FirebaseFirestore.instance.collection('logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'employeeId': user.uid,
        'customerId': widget.customer.id,
        'customerName': widget.customer.name,
        'pointsAdded': totalPoints,
        'categories': widget.selectedCategories.entries
            .map((e) => {
                  'title': e.key.title,
                  'points': e.key.points,
                  'quantity': e.value,
                })
            .toList(),
      });

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

      if (mounted) {
        final dialogFuture = showDialog(
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
                  Navigator.of(context).pop();
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

        Future.delayed(const Duration(milliseconds: 2500), () async {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          }
        });

        await dialogFuture;
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
    final pointsToAdd = widget.selectedCategories.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.key.points * entry.value,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Points'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  CustomerInfoCard(customer: widget.customer),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selected Categories:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.selectedCategories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'No categories selected.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ...widget.selectedCategories.entries.map(
                    (entry) => Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.star, color: Colors.orangeAccent),
                        title: Text(entry.key.title),
                        subtitle: entry.key.description != null
                            ? Text(entry.key.description!)
                            : null,
                        trailing: Text(
                          'x${entry.value}  +${entry.key.points * entry.value} pts',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Points to Add: $pointsToAdd',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            isSubmitting
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Submit Points'),
                      onPressed: widget.selectedCategories.isNotEmpty
                          ? _submitPoints
                          : null,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}