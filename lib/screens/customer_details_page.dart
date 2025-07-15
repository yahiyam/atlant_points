import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerDetailsPage extends StatelessWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Customer not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'Unknown';
          final mobile = snapshot.data!.id;
          final totalPoints = data['totalPoints'] ?? 0;
          final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_circle, size: 80),
                const SizedBox(height: 16),
                Text('Name: $name', style: Theme.of(context).textTheme.titleMedium),
                Text('Mobile: $mobile'),
                Text('Total Atlant Points: $totalPoints'),
                Text(
                  'Last Updated: ${updatedAt != null ? updatedAt.toLocal().toString() : 'Unknown'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
