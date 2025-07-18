import 'package:atlant_points/screens/admin/customer_log_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManageCustomerPage extends StatefulWidget {
  const ManageCustomerPage({super.key});

  @override
  State<ManageCustomerPage> createState() => _ManageCustomerPageState();
}

class _ManageCustomerPageState extends State<ManageCustomerPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Customers'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
        onPressed: () => _showEditDialog(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or mobile',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _search = val.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No customers found.'));
                }
                final docs = snap.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final mobile = doc.id.toLowerCase();
                  return name.contains(_search.toLowerCase()) ||
                      mobile.contains(_search.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;
                    final name = data['name'] ?? 'Unknown';
                    final points = data['totalPoints'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(name),
                        subtitle: Text('Mobile: $id'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(100),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$points pts',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditDialog(context, id: id, data: data);
                                }
                                if (value == 'delete') {
                                  _deleteCustomer(context, id, name);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerLogsPage(
                              customerId: id,
                              customerName: name,
                              currentPoints: points,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Edit/Add Customer Dialog ---
  void _showEditDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) {
    final nameController = TextEditingController(text: data?['name'] ?? '');
    final mobileController = TextEditingController(text: id ?? '');
    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: mobileController,
              enabled: !isEdit,
              decoration: const InputDecoration(labelText: 'Mobile'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final mobile = mobileController.text.trim();
              final name = nameController.text.trim();

              if (mobile.isEmpty || name.isEmpty) return;
              if (!RegExp(r'^05\d{8}$').hasMatch(mobile)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mobile must be 10 digits and start with 05',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              if (!isEdit) {
                // Check if customer already exists
                final doc = await FirebaseFirestore.instance
                    .collection('customers')
                    .doc(mobile)
                    .get();
                if (doc.exists) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Customer with this mobile already exists!',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }

              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(mobile)
                  .set({
                    'name': name,
                    'totalPoints': data?['totalPoints'] ?? 0,
                  }, SetOptions(merge: true));
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  // --- Delete Customer ---
  void _deleteCustomer(BuildContext context, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete $name and all their logs?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // 1. Delete all logs for this customer
      final logsSnap = await FirebaseFirestore.instance
          .collection('logs')
          .where('customerId', isEqualTo: id)
          .get();

      for (final doc in logsSnap.docs) {
        await doc.reference.delete();
      }

      // 2. Delete the customer document
      await FirebaseFirestore.instance.collection('customers').doc(id).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer and all their logs deleted.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
