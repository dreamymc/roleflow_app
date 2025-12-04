import 'package:flutter/material.dart';
import '../models/role.dart';
import 'tabs/role_overview_tab.dart';
import 'tabs/role_tasks_tab.dart';
import 'tabs/role_routines_tab.dart';
import 'add_task_sheet.dart'; // Import your existing logic-gated sheet

class RoleDetailScreen extends StatefulWidget {
  final Role role;
  
  const RoleDetailScreen({super.key, required this.role});

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  int _currentIndex = 0;

  // --- FAB BUILDER ---
  // Decides which button to show based on the active tab
  Widget? _buildFloatingActionButton() {
    if (_currentIndex == 1) {
      // TASKS TAB -> Add Task Button
      return FloatingActionButton.extended(
        backgroundColor: widget.role.color,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text("Task", style: TextStyle(color: Colors.white)),
        onPressed: () {
          // Open the Logic-Gated Sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => AddTaskSheet(
              roleId: widget.role.id,
              roleColor: widget.role.color,
            ),
          );
        },
      );
    } else if (_currentIndex == 2) {
      // ROUTINES TAB -> Add Routine Button
      return FloatingActionButton.extended(
        backgroundColor: widget.role.color,
        icon: const Icon(Icons.repeat, color: Colors.white),
        label: const Text("Routine", style: TextStyle(color: Colors.white)),
        onPressed: () {
          // Placeholder for Routine Creation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Routine Creator coming in Phase B!")),
          );
        },
      );
    }
    // OVERVIEW TAB -> No Button
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // List of tab pages
    final List<Widget> pages = [
      RoleOverviewTab(role: widget.role),
      RoleTasksTab(role: widget.role),
      RoleRoutinesTab(role: widget.role),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      
      // HEADER
      appBar: AppBar(
        title: Text(widget.role.name),
        backgroundColor: widget.role.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // BODY (Switches based on index)
      body: pages[_currentIndex],

      // SMART FAB
      floatingActionButton: _buildFloatingActionButton(),

      // NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: widget.role.color,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Routines'),
        ],
      ),
    );
  }
}