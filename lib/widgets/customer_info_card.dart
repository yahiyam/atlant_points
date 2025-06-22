import 'package:atlant_points/model/customer_model.dart';
import 'package:flutter/material.dart';

class CustomerInfoCard extends StatelessWidget {
  final Customer customer;

  const CustomerInfoCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
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
            Text('Available Atlant Points: ${customer.points}'),
          ],
        ),
      ),
    );
  }
}
