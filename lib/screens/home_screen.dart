import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Ensure this is imported
import '../services/auth_service.dart';
import '../models/role.dart';
import 'role_detail_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ADD ROLE LOGIC ---
  void _showAddRoleDialog() {
    String newRoleName = '';
    Color newRoleColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add New Role'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Role Name',
                        hintText: 'e.g., Side Hustle',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => newRoleName = val,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Color:'),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Pick a color'),
                                content: BlockPicker(
                                  pickerColor: newRoleColor,
                                  onColorChanged: (color) {
                                    setStateDialog(() => newRoleColor = color);
                                    Navigator.pop(ctx);
                                  },
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(backgroundColor: newRoleColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (newRoleName.trim().isEmpty) return;
                    
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('roles')
                          .add({
                        'name': newRoleName.trim(),
                        'color': newRoleColor.value,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DELETE ROLE LOGIC ---
  void _deleteRole(String roleId, String roleName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role?'),
        content: Text('Are you sure you want to delete "$roleName"?\nThis will delete all tasks and routines inside it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('roles')
                    .doc(roleId)
                    .delete();
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String? photoURL = user?.photoURL;
    final String email = user?.email ?? 'User';
    // Fix: Explicitly check displayName. If null, use empty string to hide the row or fallback.
    final String name = user?.displayName ?? 'RoleFlow User';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // FAB TO ADD NEW ROLE
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoleDialog,
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // 1. THE DASHBOARD HEADER
            // ------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blueGrey,
                    backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                    child: photoURL == null 
                        ? const Text('?', style: TextStyle(fontSize: 24, color: Colors.white)) // Fallback char
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name, // Display Name is here now
                          style: const TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.grey[600],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () async => await AuthService().signOut(),
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Text(
                'Your Roles',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ),

            // ------------------------------------------------
            // 2. THE ROLE LIST
            // ------------------------------------------------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('roles')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('Error loading roles'));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  
                  if (docs.isEmpty) {
                    return const Center(child: Text("No roles defined yet. Tap + to add one."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 80), // Extra bottom padding for FAB
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final role = Role.fromFirestore(
                        docs[index].data() as Map<String, dynamic>, 
                        docs[index].id
                      );
                      
                      return _RoleDashboardCard(
                        role: role, 
                        onLongPress: () => _deleteRole(role.id, role.name),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------
// HELPER: Role Card
// ------------------------------------------------------
class _RoleDashboardCard extends StatelessWidget {
  final Role role;
  final VoidCallback onLongPress;

  const _RoleDashboardCard({required this.role, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onLongPress: onLongPress, // DELETE TRIGGER
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoleDetailScreen(role: role),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 12, color: role.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: role.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .collection('roles')
                              .doc(role.id)
                              .collection('tasks')
                              .where('isCompleted', isEqualTo: false)
                              .snapshots(),
                          builder: (context, taskSnapshot) {
                            int count = 0;
                            if (taskSnapshot.hasData) {
                              count = taskSnapshot.data!.docs.length;
                            }
                            return Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[700]),
                                const SizedBox(width: 4),
                                Text('$count Tasks', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[300]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}