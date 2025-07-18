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

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 1.2),
            // boxShadow removed!
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customer.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_android, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      customer.mobile,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, size: 18, color: Colors.amber),
                    const SizedBox(width: 6),
                    if (loading)
                      const Text('Loading points...')
                    else if (hasError)
                      const Text('Error fetching points')
                    else
                      Text(
                        'Total Points: $points',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}