import 'package:atlant_points/screens/wraper_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const AtlantApp());
}

class AtlantApp extends StatelessWidget {
  const AtlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlant Points',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF009FFD),
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: WrapperScreen(),
    );
  }
}
