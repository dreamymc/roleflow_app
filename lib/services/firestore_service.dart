import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role.dart'; // Make sure this import matches your folder structure

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Helper to get current User ID safely
  String? get _uid => _user?.uid;

  // --- 1. CHECKER (Used by AuthGate) ---
  Future<bool> hasUserCreatedRoles() async {
    if (_uid == null) return false;

    // Fast check if the 'roles' subcollection has any documents
    final rolesCollection = _db.collection('users').doc(_uid).collection('roles');
    final snapshot = await rolesCollection.limit(1).get();

    return snapshot.docs.isNotEmpty;
  }

  // --- 2. FETCH ROLES (Used by HomeScreen) ---
  // This is the function the error says is missing!
  Future<List<Role>> fetchRoles() async {
    if (_uid == null) return [];

    try {
      final rolesSnapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('roles')
          .orderBy('createdAt', descending: false) // Optional: Sort by creation time
          .get();

      // Convert the raw documents into a List of Role objects
      return rolesSnapshot.docs.map((doc) => Role.fromFirestore(doc.data(), doc.id)).toList();
      
    } catch (e) {
      print('Error fetching roles: $e');
      return [];
    }
  }
}