import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart'; // We will create this next
import 'firestore_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen for Authentication state changes (Login/Logout)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If they are not logged in, show the Login Screen
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // If they ARE logged in, check their role status
        return FutureBuilder<bool>(
          future: FirestoreService().hasUserCreatedRoles(),
          builder: (context, roleSnapshot) {
            // Wait for the database check to complete
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If the user HAS roles, send them to the Home Dashboard
            if (roleSnapshot.data == true) {
              return const HomeScreen();
            }

            // If the user is logged in BUT has NO roles, send them to Onboarding
            return const OnboardingScreen();
          },
        );
      },
    );
  }
}