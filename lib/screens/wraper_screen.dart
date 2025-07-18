import 'package:atlant_points/screens/home_page.dart';
import 'package:atlant_points/screens/login/email_login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WrapperScreen extends StatelessWidget {
  const WrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the user is logged in
    final user = FirebaseAuth.instance.currentUser;

    // If the user is logged in, show the HomePage
    if (user != null) {
      return const HomePage();
    } else {
      // If the user is not logged in, show the SignInPage
      return const EmailLoginPage();
    }
  }
}
