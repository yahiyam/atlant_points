import 'package:atlant_points/model/customer_model.dart';
import 'package:atlant_points/model/point_category_model.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import '../widgets/customer_info_card.dart';

class CustomerConfirmPage extends StatefulWidget {
  final Customer customer;
  final List<PointCategory> selectedCategories;

  const CustomerConfirmPage({
    super.key,
    required this.customer,
    required this.selectedCategories,
  });

  @override
  State<CustomerConfirmPage> createState() => _CustomerConfirmPageState();
}

class _CustomerConfirmPageState extends State<CustomerConfirmPage> {
  bool isSubmitting = false;
  late Set<PointCategory> selectedCategories;

  @override
  void initState() {
    super.initState();
    selectedCategories = Set.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    final pointsToAdd = selectedCategories.fold<int>(
      0,
      (sum, category) => sum + category.points,
    );
    final newTotal = 25 + pointsToAdd;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Points')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomerInfoCard(customer: widget.customer),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selected Categories:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            ...selectedCategories.map((cat) => Dismissible(
                  key: ValueKey(cat.title),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() => selectedCategories.remove(cat));
                  },
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.orangeAccent),
                    title: Text(cat.title),
                    trailing: Text('+${cat.points} pts'),
                  ),
                )),
            const Divider(height: 32),
            Text('Points to Add: $pointsToAdd', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('New Total: $newTotal'),
            const SizedBox(height: 32),
            isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: selectedCategories.isNotEmpty
                        ? () async {
                            setState(() => isSubmitting = true);
                            await Future.delayed(const Duration(seconds: 2));
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const HomePage()),
                              (route) => false,
                            );
                          }
                        : null,
                    child: const Text('Submit Points'),
                  ),
          ],
        ),
      ),
    );
  }
}