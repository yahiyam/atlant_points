import 'package:atlant_points/model/customer_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerInfoCard extends StatelessWidget {
  final Customer customer;

  const CustomerInfoCard({super.key, required this.customer});

  Stream<int> _getLivePoints(String customerId) {
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) return 0;
          return data['totalPoints'] is int ? data['totalPoints'] : 0;
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _getLivePoints(customer.id),
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final points = snapshot.data ?? 0;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            leading: const Icon(Icons.person, size: 32),
            title: Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mobile Number: ${customer.mobile}'),
                const SizedBox(height: 4),
                if (loading)
                  const Text('Loading points...')
                else if (hasError)
                  const Text('Error fetching points')
                else
                  Text('Available Atlant Points: $points'),
              ],
            ),
          ),
        );
      },
    );
  }
}
