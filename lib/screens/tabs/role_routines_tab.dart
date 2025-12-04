import 'package:flutter/material.dart';
import '../../models/role.dart';

class RoleRoutinesTab extends StatelessWidget {
  final Role role;
  const RoleRoutinesTab({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Habit Routines for ${role.name} coming soon"));
  }
}