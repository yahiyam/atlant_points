import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:atlant_points/model/customer_model.dart';
import 'package:atlant_points/screens/pointsAdding/customer_points_selection_page.dart';

class CustomerDetailsPage extends StatelessWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details'), centerTitle: true),
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

          final customer = Customer(
            id: mobile,
            name: name,
            totalPoints: totalPoints,
            mobile: mobile,
          );

          return Column(
            children: [
              // --- Customer Card ---
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.only(top: 24, left: 16, right: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mobile: $mobile',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Points: $totalPoints',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.blue),
                      ),
                      if (updatedAt != null)
                        Text(
                          'Last update: ${DateFormat('dd MMM yyyy, hh:mm a').format(updatedAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Points'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerPointsSelectionPage(
                                customer: customer,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Point Logs Table ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('logs')
                      .snapshots(), // Get ALL logs for debugging
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(child: Text('No logs in Database.'));
                    }

                    final logs = snap.data!.docs;

                    // Filter logs in Dart for your customerId
                    final filteredLogs = logs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return d['customerId'] == customerId;
                    }).toList();

                    if (filteredLogs.isEmpty) {
                      return const Center(
                        child: Text('No logs for this customer.'),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ListView(
                        children: [
                          // Header row
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Points',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Categories',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Data rows
                          ...filteredLogs.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            final ts = (d['timestamp'] as Timestamp?)?.toDate();
                            final points = d['pointsAdded'] ?? 0;
                            final cats =
                                (d['categories'] as List<dynamic>?)
                                    ?.map((c) => c['title'])
                                    .join(', ') ??
                                '-';

                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: .5,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      ts != null
                                          ? DateFormat(
                                              'dd/MM/yyyy, hh:mm a',
                                            ).format(ts)
                                          : '-',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '+$points',
                                      style: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  Expanded(flex: 3, child: Text(cats)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
