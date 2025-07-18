import 'package:atlant_points/screens/admin/employee_management_page.dart';
import 'package:atlant_points/screens/admin/analytics_page.dart';
import 'package:atlant_points/screens/admin/manage_customer.dart';
import 'package:atlant_points/screens/admin/point_category_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // --- Admin Summary Card with real data ---
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FirestoreCountSummary(
                    icon: Icons.badge,
                    label: 'Employees',
                    collection: 'employees',
                    color: Colors.deepPurple,
                  ),
                  _FirestoreCountSummary(
                    icon: Icons.people,
                    label: 'Customers',
                    collection: 'customers',
                    color: Colors.blue,
                  ),
                  _FirestoreCountSummary(
                    icon: Icons.category,
                    label: 'Categories',
                    collection: 'pointCategories',
                    color: Colors.amber[800]!,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey[100], thickness: 1, height: 24),
          // --- Admin Actions ---
          _AdminTile(
            title: 'Manage Point Categories',
            icon: Icons.category,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PointCategoryAdminPage(),
                ),
              );
            },
          ),
          _AdminTile(
            title: 'Manage Employees',
            icon: Icons.badge,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeManagementPage(),
                ),
              );
            },
          ),
          _AdminTile(
            title: 'Manage Customers',
            icon: Icons.people,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCustomerPage(),
                ),
              );
            },
          ),
          _AdminTile(
            title: 'View Logs / Analytics',
            icon: Icons.analytics,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAnalyticsPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // --- Special Admin Action ---
          FilledButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Add New Employee'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () {
              // TODO: Implement add employee logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add Employee pressed (not implemented)'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
          semanticLabel: title,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}

// --- Summary Item with Firestore Count and loading spinner ---
class _FirestoreCountSummary extends StatelessWidget {
  final IconData icon;
  final String label;
  final String collection;
  final Color color;

  const _FirestoreCountSummary({
    required this.icon,
    required this.label,
    required this.collection,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 60,
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final count = snapshot.data?.docs.length ?? 0;
        return _SummaryItem(
          icon: icon,
          label: label,
          value: count.toString(),
          color: color,
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withAlpha(30),
          radius: 22,
          child: Icon(icon, color: color, size: 24, semanticLabel: label),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}