import 'package:atlant_points/model/customer_model.dart';
import 'package:atlant_points/model/point_category_model.dart';
import 'package:atlant_points/screens/customer_confirm_page.dart';
import 'package:atlant_points/widgets/customer_info_card.dart';
import 'package:flutter/material.dart';

class CustomerPointsSelectionPage extends StatefulWidget {
  final Customer customer;

  const CustomerPointsSelectionPage({super.key, required this.customer});

  @override
  State<CustomerPointsSelectionPage> createState() =>
      _CustomerPointsSelectionPageState();
}

class _CustomerPointsSelectionPageState
    extends State<CustomerPointsSelectionPage> {
  final Set<PointCategory> selectedCategories = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Point Categories')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CustomerInfoCard(customer: widget.customer),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: pointCategories.map((category) {
                    final isSelected = selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(
                        '${category.title} (+${category.points} pts)',
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            selectedCategories.remove(category);
                          } else {
                            selectedCategories.add(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: selectedCategories.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerConfirmPage(
                            customer: widget.customer,
                            selectedCategories: selectedCategories.toList(),
                          ),
                        ),
                      );
                    }
                  : null,
              child: const Text('Confirm Points'),
            ),
          ],
        ),
      ),
    );
  }
}
