import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'customer_details_page.dart';

class CustomerSearchPage extends StatefulWidget {
  const CustomerSearchPage({super.key});

  @override
  State<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends State<CustomerSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  Future<List<DocumentSnapshot>> _search(String q) async {
    if (q.trim().isEmpty) return [];
    final needle = q.toLowerCase();
    final snap = await FirebaseFirestore.instance
        .collection('customers')
        .orderBy('name')
        .get();
    return snap.docs.where((doc) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString().toLowerCase();
      final mobile = doc.id.toLowerCase();
      return name.contains(needle) || mobile.contains(needle);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- Optional: Summary Card ---
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.only(bottom: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search and view all customers.\nTap a customer for details.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Search Bar ---
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or mobile',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => setState(() => _query = val.trim()),
            ),
            const SizedBox(height: 20),

            // --- Customer List ---
            Expanded(
              child: _query.isEmpty
                  ? _buildAllCustomersList()
                  : FutureBuilder<List<DocumentSnapshot>>(
                      future: _search(_query),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snap.hasData || snap.data!.isEmpty) {
                          return _EmptyState(message: 'No customers found.');
                        }
                        return _buildList(snap.data!);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCustomersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyState(message: 'No customers yet.');
        }
        return _buildList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildList(List<DocumentSnapshot> docs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        final id = docs[i].id;
        final name = data['name'] ?? 'Unknown';
        final totalPoints = data['totalPoints'] ?? 0;

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Mobile: $id • Points: $totalPoints'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailsPage(customerId: id),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Empty State Widget ---
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
