import 'package:atlant_points/model/customer_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'customer_points_selection_page.dart';

class CustomerMobileEntryPage extends StatefulWidget {
  const CustomerMobileEntryPage({super.key});

  @override
  State<CustomerMobileEntryPage> createState() => _CustomerMobileEntryPageState();
}

class _CustomerMobileEntryPageState extends State<CustomerMobileEntryPage> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final FocusNode mobileFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool showNameField = false;
  String? notFoundMessage;
  Customer? foundCustomer;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(mobileFocus);
    });
  }

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
    try {
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
          totalPoints: data['totalPoints'] ?? 0,
        );
      }
      return null;
    } catch (e) {
      setState(() => errorMessage = 'Error fetching customer: $e');
      return null;
    }
  }

  Future<void> registerCustomer(String mobile, String name) async {
    try {
      await FirebaseFirestore.instance.collection('customers').doc(mobile).set({
        'name': name,
        'totalPoints': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() => errorMessage = 'Error registering customer: $e');
    }
  }

  void handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = mobileController.text.trim();

    setState(() {
      isLoading = true;
      notFoundMessage = null;
      errorMessage = null;
      foundCustomer = null;
    });

    final customer = await fetchCustomer(mobile);

    setState(() {
      isLoading = false;
      showNameField = customer == null;
      notFoundMessage = customer == null ? 'No customer found. Please register.' : null;
      foundCustomer = customer;
    });

    if (customer != null) {
      FocusScope.of(context).unfocus();
    } else {
      FocusScope.of(context).requestFocus(nameFocus);
    }
  }

  void handleFinalSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = mobileController.text.trim();
    final name = nameController.text.trim();

    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await registerCustomer(mobile, name);
    setState(() => isLoading = false);

    final customer = Customer(
      mobile: mobile,
      name: name,
      id: mobile,
      totalPoints: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerPointsSelectionPage(customer: customer),
      ),
    );
  }

  void handleContinue() {
    if (foundCustomer != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerPointsSelectionPage(customer: foundCustomer!),
        ),
      );
    }
  }

  void handleClear() {
    setState(() {
      mobileController.clear();
      nameController.clear();
      showNameField = false;
      notFoundMessage = null;
      foundCustomer = null;
      errorMessage = null;
    });
    FocusScope.of(context).requestFocus(mobileFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Customer Mobile Entry'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Enter Customer Mobile',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: mobileController,
                            focusNode: mobileFocus,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Customer Mobile',
                              helperText: '05X XXX XXXX',
                              border: const OutlineInputBorder(),
                              suffixIcon: mobileController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: handleClear,
                                    )
                                  : null,
                            ),
                            validator: validateMobile,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            enabled: !showNameField,
                            textInputAction: TextInputAction.search,
                            onChanged: (_) => setState(() {}),
                            onFieldSubmitted: (_) => handleNext(),
                          ),
                          const SizedBox(height: 16),
                          if (showNameField)
                            TextFormField(
                              controller: nameController,
                              focusNode: nameFocus,
                              decoration: const InputDecoration(
                                labelText: 'Customer Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: validateName,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => handleFinalSubmit(),
                            ),
                          if (notFoundMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                notFoundMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          if (foundCustomer != null && !showNameField)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Card(
                                elevation: 0,
                                color: Colors.green[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green[100],
                                    child: const Icon(Icons.check_circle, color: Colors.green),
                                  ),
                                  title: Text(foundCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Points: ${foundCustomer!.totalPoints}'),
                                  trailing: FilledButton(
                                    onPressed: handleContinue,
                                    child: const Text('Continue'),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          if (!showNameField && foundCustomer == null)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.search),
                                onPressed: handleNext,
                                label: const Text('Next'),
                              ),
                            ),
                          if (showNameField)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.person_add),
                                onPressed: handleFinalSubmit,
                                label: const Text('Register & Continue'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}