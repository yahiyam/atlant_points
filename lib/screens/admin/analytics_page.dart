import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  List<Map<String, dynamic>> topEmployees = [];
  List<Map<String, dynamic>> topCustomers = [];
  Map<String, String> employeeNames = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      await _fetchEmployees();
      await _fetchLeaderboard();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _fetchEmployees() async {
    final snap = await FirebaseFirestore.instance.collection('employees').get();
    employeeNames = {
      for (var doc in snap.docs) doc.id: (doc.data())['name'] ?? '-',
    };
  }

  Future<void> _fetchLeaderboard() async {
    final logsSnap = await FirebaseFirestore.instance.collection('logs').get();

    Map<String, int> employeePoints = {};
    Map<String, int> customerPoints = {};

    for (var doc in logsSnap.docs) {
      final data = doc.data();
      final pointsRaw = data['pointsAdded'] ?? 0;
      final int points = (pointsRaw is int)
          ? pointsRaw
          : (pointsRaw as num).toInt();
      final employeeId = data['employeeId'] ?? '';
      final customerName = data['customerName'] ?? '';

      employeePoints[employeeId] = (employeePoints[employeeId] ?? 0) + points;
      customerPoints[customerName] =
          (customerPoints[customerName] ?? 0) + points;
    }

    List<Map<String, dynamic>> employeeList = employeePoints.entries
        .map((e) => {'name': employeeNames[e.key] ?? '-', 'points': e.value})
        .toList();
    employeeList.sort((a, b) => b['points'].compareTo(a['points']));

    List<Map<String, dynamic>> customerList = customerPoints.entries
        .map((e) => {'name': e.key, 'points': e.value})
        .toList();
    customerList.sort((a, b) => b['points'].compareTo(a['points']));

    setState(() {
      topEmployees = employeeList.take(10).toList();
      topCustomers = customerList.take(10).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logs & Analytics'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text('Error: $error'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Leaderboard Section ---
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Top Employees',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildList(topEmployees, Colors.blueAccent),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Top Customers',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildList(topCustomers, Colors.amber),
                  const SizedBox(height: 30),
                  // --- Recent Logs Section ---
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Logs',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRecentLogsTable(context),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, Color color) {
    if (list.isEmpty) {
      return const Text('No data yet.');
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade100), // lighter border
      ),
      color: Theme.of(context).colorScheme.surface, // much lighter
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = list[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(40),
              child: Text('${i + 1}', style: TextStyle(color: color)),
            ),
            title: Text(item['name']),
            trailing: Text(
              '${item['points']} pts',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentLogsTable(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text('No logs found.');
        }
        final logs = snap.data!.docs;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade100), // lighter border
          ),
          color: Theme.of(context).colorScheme.surface, // much lighter
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 600,
              child: SizedBox(
                height: 360,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Points')),
                      DataColumn(label: Text('Employee')),
                    ],
                    rows: logs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final ts = (data['timestamp'] as Timestamp?)?.toDate();
                      final dateStr = ts != null
                          ? '${ts.day}/${ts.month}/${ts.year}'
                          : '-';
                      final customer = data['customerName'] ?? '-';
                      final points = data['pointsAdded'] ?? 0;
                      final employeeId = data['employeeId'] ?? '';
                      final empName = employeeNames[employeeId] ?? '-';
                      return DataRow(
                        cells: [
                          DataCell(Text(dateStr)),
                          DataCell(Text(customer)),
                          DataCell(Text(points.toString())),
                          DataCell(Text(empName)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
