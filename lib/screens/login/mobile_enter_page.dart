// import 'package:atlant_points/widgets/app_logo_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/services.dart';
// import 'otp_verification_page.dart';

// class PhoneNumberEntryPage extends StatefulWidget {
//   const PhoneNumberEntryPage({super.key});

//   @override
//   State<PhoneNumberEntryPage> createState() => _PhoneNumberEntryPageState();
// }

// class _PhoneNumberEntryPageState extends State<PhoneNumberEntryPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController phoneController = TextEditingController();
//   bool _isLoading = false;

//   Widget _gap() => const SizedBox(height: 16);

//   Future<void> _sendOtp() async {
//     if (!_formKey.currentState!.validate()) return;

//     final rawPhone = phoneController.text.trim();
//     final phoneNumber = "+966${rawPhone.substring(1)}";
//     setState(() => _isLoading = true);

//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       timeout: const Duration(seconds: 60),
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await FirebaseAuth.instance.signInWithCredential(credential);
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Verification failed: ${e.message}')),
//         );
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => OTPVerificationPage(
//               phoneNumber: phoneNumber,
//               verificationId: verificationId,
//             ),
//           ),
//         );
//         setState(() => _isLoading = false);
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {},
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: SingleChildScrollView(
//           child: Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Container(
//               padding: const EdgeInsets.all(32),
//               constraints: const BoxConstraints(maxWidth: 350),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const AppLogo(size: 120),
//                     _gap(),
//                     const Text(
//                       'Welcome to',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                     const Text(
//                       'Atlant Points',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                     _gap(),
//                     const Text(
//                       'Login using Mobile Number',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                     ),
//                     _gap(),
//                     TextFormField(
//                       controller: phoneController,
//                       keyboardType: TextInputType.phone,
//                       maxLength: 10,
//                       decoration: const InputDecoration(
//                         labelText: 'Phone Number',
//                         hintText: '05XXXXXXXX',
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.phone),
//                         counterText: '',
//                       ),
//                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                       validator: (value) {
//                         if (value == null ||
//                             value.length != 10 ||
//                             !value.startsWith('05')) {
//                           return 'Enter a valid 10-digit Saudi number';
//                         }
//                         return null;
//                       },
//                     ),
//                     _gap(),
//                     _isLoading
//                         ? const CircularProgressIndicator()
//                         : SizedBox(
//                             width: double.infinity,
//                             child: FilledButton(
//                               onPressed: _sendOtp,
//                               child: const Padding(
//                                 padding: EdgeInsets.all(10.0),
//                                 child: Text(
//                                   'Send OTP',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }