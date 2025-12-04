import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Function to check if the user has created any roles yet
  Future<bool> hasUserCreatedRoles() async {
    if (_user == null) return false;

    // Check if the 'roles' subcollection under the current user's document has any documents
    final rolesCollection = _db.collection('users').doc(_user!.uid).collection('roles');
    
    // We only need to fetch the first document, limit(1) makes this operation very fast and cheap.
    final snapshot = await rolesCollection.limit(1).get();

    return snapshot.docs.isNotEmpty;
  }
}