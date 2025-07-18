import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PointCategoryAdminPage extends StatefulWidget {
  const PointCategoryAdminPage({super.key});

  @override
  State<PointCategoryAdminPage> createState() => _PointCategoryAdminPageState();
}

class _PointCategoryAdminPageState extends State<PointCategoryAdminPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  String? _errorText;

  Future<void> addOrUpdateCategory({
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final title = titleController.text.trim();
    final points = int.tryParse(pointsController.text.trim()) ?? 0;
    final description = descController.text.trim();

    if (title.isEmpty || points <= 0) {
      setState(() => _errorText = 'Title and points are required.');
      return;
    }

    // Prevent duplicate titles (case-insensitive)
    final query = await FirebaseFirestore.instance
        .collection('pointCategories')
        .where('title', isEqualTo: title)
        .get();

    if ((id == null && query.docs.isNotEmpty) ||
        (id != null && query.docs.any((doc) => doc.id != id))) {
      setState(() => _errorText = 'A category with this title already exists.');
      return;
    }

    if (id == null) {
      // Add new
      await FirebaseFirestore.instance.collection('pointCategories').add({
        'title': title,
        'points': points,
        'description': description,
      });
    } else {
      // Update existing
      await FirebaseFirestore.instance
          .collection('pointCategories')
          .doc(id)
          .update({
            'title': title,
            'points': points,
            'description': description,
          });
    }

    titleController.clear();
    pointsController.clear();
    descController.clear();
    setState(() => _errorText = null);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
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
      await FirebaseFirestore.instance
          .collection('pointCategories')
          .doc(id)
          .delete();
    }
  }

  void _showEditDialog({String? id, Map<String, dynamic>? data}) {
    titleController.text = data?['title'] ?? '';
    pointsController.text = data?['points']?.toString() ?? '';
    descController.text = data?['description'] ?? '';
    setState(() => _errorText = null);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: const InputDecoration(labelText: 'Points'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              titleController.clear();
              pointsController.clear();
              descController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => addOrUpdateCategory(id: id, data: data),
            child: Text(id == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Point Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
              onPressed: () => _showEditDialog(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const Divider(height: 30),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pointCategories')
                    .orderBy('points')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final id = docs[index].id;
                      final title = data['title'] ?? '';
                      final points = data['points'] ?? 0;
                      final description = data['description'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text('$title (+$points pts)'),
                          subtitle: description.isNotEmpty
                              ? Text(description)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Edit',
                                onPressed: () =>
                                    _showEditDialog(id: id, data: data),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete',
                                onPressed: () => deleteCategory(id),
                              ),
                            ],
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
