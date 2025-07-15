import 'package:atlant_points/model/customer_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'customer_points_selection_page.dart';

class CustomerMobileEntryPage extends StatefulWidget {
  const CustomerMobileEntryPage({super.key});

  @override
  State<CustomerMobileEntryPage> createState() =>
      _CustomerMobileEntryPageState();
}

class _CustomerMobileEntryPageState extends State<CustomerMobileEntryPage> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool showNameField = false;

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
      return 'Enter a valid 10-digit number starting with 05';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  Future<Customer?> fetchCustomer(String mobile) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('customers')
        .doc(mobile)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      return Customer(
        id: mobile,
        mobile: mobile,
        name: data['name'] ?? 'Unknown',
        points: data['points'] ?? 0, // ✅ include points here
      );
    }
    return null;
  }

  Future<void> registerCustomer(String mobile, String name) async {
    await FirebaseFirestore.instance.collection('customers').doc(mobile).set({
      'name': name,
      'points': 0, // ✅ initialize points
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = mobileController.text.trim();

    setState(() => isLoading = true);

    final customer = await fetchCustomer(mobile);

    setState(() {
      isLoading = false;
      showNameField = customer == null;
    });

    if (customer != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerPointsSelectionPage(customer: customer),
        ),
      );
    }
  }

  void handleFinalSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = mobileController.text.trim();
    final name = nameController.text.trim();

    setState(() => isLoading = true);
    await registerCustomer(mobile, name);
    setState(() => isLoading = false);

    final customer = Customer(mobile: mobile, name: name, id: mobile);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerPointsSelectionPage(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Mobile Entry')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Customer Mobile',
                  helperText: '05X XXX XXXX',
                  border: OutlineInputBorder(),
                ),
                validator: validateMobile,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 16),
              if (showNameField)
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: validateName,
                ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: showNameField ? handleFinalSubmit : handleNext,
                      child: Text(
                        showNameField ? 'Register & Continue' : 'Next',
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
