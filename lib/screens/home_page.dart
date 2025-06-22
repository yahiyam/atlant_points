import 'package:flutter/material.dart';
import 'customer_mobile_entry_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleLogs = [
      {'name': 'Ahmed', 'points': 10, 'time': '10:30 AM'},
      {'name': 'Sara', 'points': 15, 'time': '11:00 AM'},
      {'name': 'Mohammed', 'points': 5, 'time': '12:45 PM'},
      {'name': 'Ahmed', 'points': 10, 'time': '10:30 AM'},
      {'name': 'Sara', 'points': 15, 'time': '11:00 AM'},
      {'name': 'Mohammed', 'points': 5, 'time': '12:45 PM'},
      {'name': 'Ahmed', 'points': 10, 'time': '10:30 AM'},
      {'name': 'Sara', 'points': 15, 'time': '11:00 AM'},
      {'name': 'Mohammed', 'points': 5, 'time': '12:45 PM'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlant Points'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {},
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome, Employee',
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
            ),
            const SizedBox(height: 32),
            Text(
              "Today's Point Logs",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: sampleLogs.length,
                itemBuilder: (context, index) {
                  final log = sampleLogs[index];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text('${log['name']} earned ${log['points']} pts'),
                      subtitle: Text('Time: ${log['time']}'),
                    ),
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
