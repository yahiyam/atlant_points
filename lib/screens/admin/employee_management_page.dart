import 'package:atlant_points/model/employee_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// You need to create this page as shown below
import 'employee_logs_page.dart';

class EmployeeManagementPage extends StatelessWidget {
  const EmployeeManagementPage({super.key});

  Future<void> _toggleAdminStatus(BuildContext context, Employee employee) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (employee.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot change your own admin status.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employee.id)
          .update({'isAdmin': !employee.isAdmin});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${employee.name}\'s role updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Employees')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading employees.'));
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final employee = Employee.fromJson(doc.data() as Map<String, dynamic>, doc.id);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(employee.name),
                  subtitle: Text(employee.mobile),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(employee.isAdmin ? 'Admin' : 'Employee'),
                      Switch(
                        value: employee.isAdmin,
                        onChanged: (value) => _toggleAdminStatus(context, employee),
                        activeColor: Colors.deepPurple,
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeLogsPage(
                        employeeId: employee.id,
                        employeeName: employee.name,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}