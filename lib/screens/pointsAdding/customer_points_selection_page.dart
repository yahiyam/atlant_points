import 'package:atlant_points/model/customer_model.dart';
import 'package:atlant_points/model/point_category_model.dart';
import 'package:atlant_points/screens/pointsAdding/customer_confirm_page.dart';
import 'package:atlant_points/widgets/customer_info_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerPointsSelectionPage extends StatelessWidget {
  final Customer customer;

  const CustomerPointsSelectionPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Point Categories'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pointCategories')
            .orderBy('points')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          final pointCategories = snap.data!.docs
              .map((doc) => PointCategory.fromJson(doc.data() as Map<String, dynamic>))
              .toList();

          return _CategorySelector(
            customer: customer,
            pointCategories: pointCategories,
          );
        },
      ),
    );
  }
}

class _CategorySelector extends StatefulWidget {
  final Customer customer;
  final List<PointCategory> pointCategories;

  const _CategorySelector({
    required this.customer,
    required this.pointCategories,
  });

  @override
  State<_CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<_CategorySelector> {
  final Map<PointCategory, int> selectedCategories = {};
  bool isSubmitting = false;

  int get totalPoints => selectedCategories.entries
      .fold(0, (sum, entry) => sum + entry.key.points * entry.value);

  void handleClear() {
    setState(() => selectedCategories.clear());
  }

  void handleConfirm() async {
    setState(() => isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => isSubmitting = false);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerConfirmPage(
          customer: widget.customer,
          selectedCategories: Map<PointCategory, int>.from(selectedCategories),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Categories selected!'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void showDescriptionDialog(PointCategory category) {
    if (category.description == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category.title),
        content: Text(category.description!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        CustomerInfoCard(customer: widget.customer),
        const SizedBox(height: 10),
        Divider(color: Colors.grey[200], thickness: 1, height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Select Categories:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.pointCategories.map((category) {
            final isSelected = selectedCategories.containsKey(category);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InputChip(
                  label: Text(
                    '${category.title} (+${category.points} pts)',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                  isEnabled: !isSelected,
                  disabledColor: Colors.grey[300],
                  onSelected: (_) {
                    if (!isSelected) {
                      setState(() {
                        selectedCategories[category] = 1;
                      });
                    }
                  },
                ),
                if (category.description != null)
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: 'Info',
                    onPressed: () => showDescriptionDialog(category),
                  ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (selectedCategories.isNotEmpty) ...[
          const Divider(height: 24),
          ...selectedCategories.entries.map((entry) {
            final category = entry.key;
            final count = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(category.title),
                subtitle: category.description != null
                    ? Text(category.description!)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: count > 1
                          ? () {
                              setState(() {
                                selectedCategories[category] = count - 1;
                              });
                            }
                          : null,
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          selectedCategories[category] = count + 1;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          selectedCategories.remove(category);
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Total Points: ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '$totalPoints',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Confirm Points'),
                  onPressed: selectedCategories.isNotEmpty && !isSubmitting
                      ? handleConfirm
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                onPressed: selectedCategories.isNotEmpty && !isSubmitting
                    ? handleClear
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}