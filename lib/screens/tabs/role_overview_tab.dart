import 'package:flutter/material.dart';
import '../../models/role.dart';

class RoleOverviewTab extends StatelessWidget {
  final Role role;
  const RoleOverviewTab({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("AI Summary for ${role.name} coming soon"));
  }
}