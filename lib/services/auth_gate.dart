import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter/material.dart';
import '../screens/login_screen.dart'; // Ensure this points to your new Login UI
import '../screens/home_screen.dart';  // Ensure this points to your placeholder Home

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has data, the user is logged in -> Show Home
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Otherwise, they are logged out -> Show Login
        return const LoginScreen();
      },
    );
  }
}