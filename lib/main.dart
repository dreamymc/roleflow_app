
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_gate.dart'; // Make sure this path matches where you put AuthGate

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  runApp(const RoleFlowApp());
}

class RoleFlowApp extends StatelessWidget {
  const RoleFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoleFlow',
      // We use BlueGrey as the seed to give it that "Serious/Productivity" vibe
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      // THIS is the switch. It points to the Gate, not the Test Screen.
      home: const AuthGate(),
    );
  }
}
