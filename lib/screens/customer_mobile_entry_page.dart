import 'package:atlant_points/screens/customer_points_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  Future<bool> checkIfCustomerExists(String mobile) async {
    // TODO: Replace with Firestore query
    await Future.delayed(const Duration(milliseconds: 500));
    return false; // Simulated: No existing customer found
  }

  void handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = mobileController.text.trim();

    setState(() => isLoading = true);

    final exists = await checkIfCustomerExists(mobile);

    setState(() {
      isLoading = false;
      showNameField = !exists;
    });

    if (exists) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerPointsSelectionPage()),
      );
    }
  }

  void handleFinalSubmit() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerPointsSelectionPage()),
      );
    }
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
