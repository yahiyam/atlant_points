import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmployeeLogsPage extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeLogsPage({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeLogsPage> createState() => _EmployeeLogsPageState();
}

class _EmployeeLogsPageState extends State<EmployeeLogsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs by ${widget.employeeName}'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logs')
            .where('employeeId', isEqualTo: widget.employeeId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No logs.'));
          }
          final logs = snap.data!.docs.toList();
          logs.sort((a, b) {
            final aTime =
                (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final bTime =
                (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Newest first
          });

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final data = logs[i].data() as Map<String, dynamic>;
              final ts = (data['timestamp'] as Timestamp?)?.toDate();
              final points = data['pointsAdded'] ?? 0;
              final customerName = data['customerName'] ?? '-';
              final cats =
                  (data['categories'] as List<dynamic>?)
                      ?.map((c) => c['title'])
                      .join(', ') ??
                  '-';
              final adminAction = data['adminAction'] as String?;
              final redeemed = data['redeemed'] == true;
              final canceled = data['canceled'] == true;

              return ListTile(
                title: Row(
                  children: [
                    Text('Points: $points'),
                    if (adminAction != null && adminAction.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: adminAction == 'redeem'
                              ? Colors.deepPurple.withOpacity(0.12)
                              : adminAction == 'return'
                              ? Colors.green.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          adminAction.toUpperCase(),
                          style: TextStyle(
                            color: adminAction == 'redeem'
                                ? Colors.deepPurple
                                : adminAction == 'return'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    if (redeemed)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'REDEEMED',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    if (canceled)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CANCELED',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  'Customer: $customerName\nCategories: $cats\n${ts ?? ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.deepPurple),
                  tooltip: 'Transfer Credit',
                  onPressed: () => _showTransferDialog(
                    context,
                    logs[i].id,
                    widget.employeeId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Transfer Credit Dialog ---
  void _showTransferDialog(
    BuildContext context,
    String logId,
    String currentEmployeeId,
  ) async {
    String? selectedEmployeeId;
    final employeesSnap = await FirebaseFirestore.instance
        .collection('employees')
        .get();

    // Filter out the current employee
    final otherEmployees = employeesSnap.docs
        .where((doc) => doc.id != currentEmployeeId)
        .toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Transfer Credit to Employee'),
        content: otherEmployees.isEmpty
            ? const Text('No other employees available for transfer.')
            : DropdownButtonFormField<String>(
                value: null,
                isExpanded: true,
                items: otherEmployees.map((doc) {
                  final data = doc.data();
                  final name = data['name'] ?? '-';
                  return DropdownMenuItem(value: doc.id, child: Text(name));
                }).toList(),
                onChanged: (val) {
                  selectedEmployeeId = val;
                },
                decoration: const InputDecoration(
                  labelText: 'Select Employee',
                  border: OutlineInputBorder(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: otherEmployees.isEmpty
                ? null
                : () async {
                    if (selectedEmployeeId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select an employee.'),
                        ),
                      );
                      return;
                    }
                    await FirebaseFirestore.instance
                        .collection('logs')
                        .doc(logId)
                        .update({'employeeId': selectedEmployeeId});
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Credit transferred!')),
                    );
                  },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }
}
