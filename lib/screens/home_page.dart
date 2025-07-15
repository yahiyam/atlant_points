import 'package:atlant_points/screens/customer_mobile_entry_page.dart';
import 'package:atlant_points/screens/customer_search_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // void _confirmLogout(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text("Confirm Logout"),
  //       content: const Text("Are you sure you want to log out?"),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text("Cancel"),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             Navigator.of(context).pop();
  //             await FirebaseAuth.instance.signOut();
  //             if (context.mounted) {
  //               Navigator.pushReplacement(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => const WrapperScreen()),
  //               );
  //             }
  //           },
  //           child: const Text("Logout"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Stream<QuerySnapshot> getTodayLogsStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('logs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<String> getEmployeeName() async {
    final user = FirebaseAuth.instance.currentUser;
    final doc = await FirebaseFirestore.instance
        .collection('employees')
        .doc(user?.uid)
        .get();
    final name = doc.data()?['name'] ?? 'Employee';
    return name.toString().toUpperCase(); // UPPERCASE
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlant Points'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     onPressed: () => _confirmLogout(context),
        //     tooltip: 'Logout',
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('View Customers'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerSearchPage()),
                );
              },
            ),

            FutureBuilder<String>(
              future: getEmployeeName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Center(child: LinearProgressIndicator()),
                  );
                }
                final name = snapshot.data ?? 'EMPLOYEE';
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'WELCOME, $name',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Atlant Points'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerMobileEntryPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              "Today's Point Logs",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getTodayLogsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading logs.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No logs today.'));
                  }

                  final logs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final data =
                          logs[index].data() as Map<String, dynamic>? ?? {};
                      final customer = data['customer'] ?? {};
                      final name = customer['name'] ?? 'Unknown';
                      final points = data['pointsAdded'] ?? 0;
                      final timestamp = (data['timestamp'] as Timestamp?)
                          ?.toDate();
                      final timeStr = timestamp != null
                          ? TimeOfDay.fromDateTime(timestamp).format(context)
                          : 'Unknown time';
                      final categories =
                          (data['categories'] as List<dynamic>? ?? [])
                              .map((c) => "${c['title']} (+${c['points']})")
                              .join(', ');
                      final employeeId = data['employeeId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('employees')
                            .doc(employeeId)
                            .get(),
                        builder: (context, snapshot) {
                          final employeeName = snapshot.data?.data() != null
                              ? (snapshot.data!.data()
                                        as Map<String, dynamic>)['name'] ??
                                    'Unknown'
                              : 'Unknown';

                          return ExpansionTile(
                            leading: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            title: Text('$name earned $points pts'),
                            subtitle: Text('Time: $timeStr'),
                            children: [
                              ListTile(
                                title: Text('Employee: $employeeName'),
                                subtitle: Text('Categories: $categories'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
