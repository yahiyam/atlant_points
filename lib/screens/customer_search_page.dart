import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'customer_details_page.dart';

class CustomerSearchPage extends StatefulWidget {
  const CustomerSearchPage({super.key});

  @override
  State<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends State<CustomerSearchPage> {
  final TextEditingController searchController = TextEditingController();
  List<DocumentSnapshot> results = [];
  bool isLoading = false;

  void searchCustomers(String query) async {
    setState(() {
      isLoading = true;
      results = [];
    });

    final q = query.toLowerCase();

    final mobileResults = await FirebaseFirestore.instance
        .collection('customers')
        .where(FieldPath.documentId, isEqualTo: q)
        .get();

    final nameResults = await FirebaseFirestore.instance
        .collection('customers')
        .where('name', isGreaterThanOrEqualTo: q)
        .where('name', isLessThanOrEqualTo: '$q\uf8ff')
        .get();

    final merged = [...mobileResults.docs, ...nameResults.docs]
        .fold<Map<String, DocumentSnapshot>>({}, (map, doc) {
      map[doc.id] = doc; // to avoid duplicates
      return map;
    }).values.toList();

    setState(() {
      results = merged;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Customers')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or mobile',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchCustomers(searchController.text.trim()),
                ),
              ),
              onSubmitted: (_) => searchCustomers(searchController.text.trim()),
            ),
            const SizedBox(height: 16),
            if (isLoading) const CircularProgressIndicator(),
            if (!isLoading && results.isEmpty)
              const Text('No customers found.'),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final data = results[index].data() as Map<String, dynamic>;
                  final id = results[index].id;
                  final name = data['name'] ?? 'Unknown';
                  final mobile = id;
                  final totalPoints = data['totalPoints'] ?? 0;

                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(name),
                    subtitle: Text('Mobile: $mobile\nPoints: $totalPoints'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailsPage(
                            customerId: id,
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
      ),
    );
  }
}
