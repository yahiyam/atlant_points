import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerLogsPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final int currentPoints;

  const CustomerLogsPage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.currentPoints,
  });

  @override
  State<CustomerLogsPage> createState() => _CustomerLogsPageState();
}

class _CustomerLogsPageState extends State<CustomerLogsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs for ${widget.customerName}'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logs')
            .where('customerId', isEqualTo: widget.customerId)
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
              final cats =
                  (data['categories'] as List<dynamic>?)
                      ?.map((c) => c['title'])
                      .join(', ') ??
                  '-';
              final adminAction = data['adminAction'] as String?;
              final redeemed = data['redeemed'] == true;
              final canceled = data['canceled'] == true;
              final employeeId = data['employeeId'] ?? '';

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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categories: $cats\n${ts ?? ''}'),
                    FutureBuilder<DocumentSnapshot>(
                      future: employeeId.isNotEmpty
                          ? FirebaseFirestore.instance
                              .collection('employees')
                              .doc(employeeId)
                              .get()
                          : null,
                      builder: (context, empSnap) {
                        String empName = '-';
                        if (empSnap.hasData &&
                            empSnap.data != null &&
                            empSnap.data!.exists) {
                          empName = (empSnap.data!.data()
                              as Map<String, dynamic>)['name'] ?? '-';
                        }
                        return Text('Employee: $empName');
                      },
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'redeem' && !redeemed && !canceled) {
                      _confirmAction(
                        context,
                        'Redeem Points',
                        'Are you sure you want to redeem these points?',
                        () => _redeemPoints(
                          widget.customerId,
                          logs[i].id,
                          points,
                        ),
                      );
                    }
                    if (value == 'redeem_custom' && !redeemed && !canceled) {
                      _showRedeemPointsDialog(
                        context,
                        widget.customerId,
                        widget.currentPoints,
                      );
                    }
                    if (value == 'return' && !canceled && !redeemed) {
                      _confirmAction(
                        context,
                        'Return/Cancel Points',
                        'Are you sure you want to return/cancel these points?',
                        () => _returnPoints(
                          widget.customerId,
                          logs[i].id,
                          points,
                        ),
                      );
                    }
                    if (value == 'redo_redeem' && redeemed) {
                      _confirmAction(
                        context,
                        'Redo Redeem',
                        'Are you sure you want to undo redeem?',
                        () => _redoRedeem(
                          widget.customerId,
                          logs[i].id,
                          points.abs(),
                        ),
                      );
                    }
                    if (value == 'redo_cancel' && canceled) {
                      _confirmAction(
                        context,
                        'Redo Cancel',
                        'Are you sure you want to undo cancel?',
                        () => _redoCancel(
                          widget.customerId,
                          logs[i].id,
                          points.abs(),
                        ),
                      );
                    }
                    if (value == 'transfer') {
                      _showTransferDialog(context, logs[i].id, employeeId);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!redeemed && !canceled)
                      const PopupMenuItem(
                        value: 'redeem',
                        child: Text('Redeem This Log Points'),
                      ),
                    if (!redeemed && !canceled)
                      const PopupMenuItem(
                        value: 'redeem_custom',
                        child: Text('Redeem Custom Points'),
                      ),
                    if (!canceled && !redeemed)
                      const PopupMenuItem(
                        value: 'return',
                        child: Text('Return/Cancel Points'),
                      ),
                    if (redeemed)
                      const PopupMenuItem(
                        value: 'redo_redeem',
                        child: Text('Redo Redeem'),
                      ),
                    if (canceled)
                      const PopupMenuItem(
                        value: 'redo_cancel',
                        child: Text('Redo Cancel'),
                      ),
                    const PopupMenuItem(
                      value: 'transfer',
                      child: Text('Transfer Credit'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Transfer Credit Dialog ---
  void _showTransferDialog(BuildContext context, String logId, String currentEmployeeId) async {
    String? selectedEmployeeId;
    final employeesSnap = await FirebaseFirestore.instance.collection('employees').get();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Transfer Credit to Employee'),
        content: DropdownButtonFormField<String>(
          value: null,
          isExpanded: true,
          items: employeesSnap.docs.map((doc) {
            final data = doc.data();
            final name = data['name'] ?? '-';
            return DropdownMenuItem(
              value: doc.id,
              child: Text(name),
            );
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
            onPressed: () async {
              if (selectedEmployeeId == null || selectedEmployeeId == currentEmployeeId) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a different employee.')),
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

  // --- Confirmation Dialog for Critical Actions ---
  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  // --- Redeem Custom Points Dialog ---
  void _showRedeemPointsDialog(
    BuildContext context,
    String customerId,
    int currentPoints,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Redeem Points'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Points to Redeem',
            hintText: 'Enter points (e.g. 100)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = controller.text.trim();
              final redeemPoints = int.tryParse(input) ?? 0;
              if (redeemPoints <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid number of points!'),
                  ),
                );
                return;
              }
              if (redeemPoints > currentPoints) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot redeem more than available points!'),
                  ),
                );
                return;
              }
              await _redeemCustomPoints(context, customerId, redeemPoints);
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemCustomPoints(
    BuildContext context,
    String customerId,
    int points,
  ) async {
    final customerRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId);
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(customerRef);
      final currentPoints = snap.data()?['totalPoints'] ?? 0;
      final updatedPoints = (currentPoints - points) < 0
          ? 0
          : (currentPoints - points);
      txn.update(customerRef, {'totalPoints': updatedPoints});
    });
    await FirebaseFirestore.instance.collection('logs').add({
      'timestamp': FieldValue.serverTimestamp(),
      'customerId': customerId,
      'pointsAdded': -points,
      'categories': [
        {'title': 'Redeem', 'points': -points},
      ],
      'adminAction': 'redeem',
      'redeemed': true,
    });
    if (context.mounted) Navigator.pop(context); // Close dialog
    if (context.mounted) Navigator.pop(context); // Close logs page
  }

  // --- Redeem Points (from log) ---
  Future<void> _redeemPoints(
    String customerId,
    String logId,
    int points,
  ) async {
    final customerRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId);
    final logRef = FirebaseFirestore.instance.collection('logs').doc(logId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(customerRef);
      final currentPoints = snap.data()?['totalPoints'] ?? 0;
      final newPoints = (currentPoints - points) < 0
          ? 0
          : (currentPoints - points);
      txn.update(customerRef, {'totalPoints': newPoints});
      txn.update(logRef, {'redeemed': true});
    });
    await FirebaseFirestore.instance.collection('logs').add({
      'timestamp': FieldValue.serverTimestamp(),
      'customerId': customerId,
      'pointsAdded': -points,
      'categories': [
        {'title': 'Redeem', 'points': -points},
      ],
      'adminAction': 'redeem',
      'relatedLogId': logId,
      'redeemed': true,
    });
    if (context.mounted) Navigator.pop(context);
  }

  // --- Redo Redeem ---
  Future<void> _redoRedeem(String customerId, String logId, int points) async {
    final customerRef = FirebaseFirestore.instance.collection('customers').doc(customerId);
    final logRef = FirebaseFirestore.instance.collection('logs').doc(logId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(customerRef);
      final currentPoints = snap.data()?['totalPoints'] ?? 0;
      txn.update(customerRef, {'totalPoints': currentPoints + points});
      txn.update(logRef, {'redeemed': false});
    });
    await FirebaseFirestore.instance.collection('logs').add({
      'timestamp': FieldValue.serverTimestamp(),
      'customerId': customerId,
      'pointsAdded': points,
      'categories': [
        {'title': 'Redo Redeem', 'points': points},
      ],
      'adminAction': 'redo_redeem',
      'relatedLogId': logId,
      'redeemed': false,
    });
    if (context.mounted) Navigator.pop(context);
  }

  // --- Return/Cancel Points ---
  Future<void> _returnPoints(
    String customerId,
    String logId,
    int points,
  ) async {
    final customerRef = FirebaseFirestore.instance.collection('customers').doc(customerId);
    final logRef = FirebaseFirestore.instance.collection('logs').doc(logId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(customerRef);
      final currentPoints = snap.data()?['totalPoints'] ?? 0;
      final newPoints = currentPoints + points;
      txn.update(customerRef, {'totalPoints': newPoints});
      txn.update(logRef, {'canceled': true});
    });
    await FirebaseFirestore.instance.collection('logs').add({
      'timestamp': FieldValue.serverTimestamp(),
      'customerId': customerId,
      'pointsAdded': points,
      'categories': [
        {'title': 'Return/Cancel', 'points': points},
      ],
      'adminAction': 'return',
      'relatedLogId': logId,
      'canceled': true,
    });
    if (context.mounted) Navigator.pop(context);
  }

  // --- Redo Cancel ---
  Future<void> _redoCancel(String customerId, String logId, int points) async {
    final customerRef = FirebaseFirestore.instance.collection('customers').doc(customerId);
    final logRef = FirebaseFirestore.instance.collection('logs').doc(logId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(customerRef);
      final currentPoints = snap.data()?['totalPoints'] ?? 0;
      txn.update(customerRef, {'totalPoints': currentPoints - points});
      txn.update(logRef, {'canceled': false});
    });
    await FirebaseFirestore.instance.collection('logs').add({
      'timestamp': FieldValue.serverTimestamp(),
      'customerId': customerId,
      'pointsAdded': -points,
      'categories': [
        {'title': 'Redo Cancel', 'points': -points},
      ],
      'adminAction': 'redo_cancel',
      'relatedLogId': logId,
      'canceled': false,
    });
    if (context.mounted) Navigator.pop(context);
  }
}