import 'package:flutter/material.dart';
import '../models/role.dart';
import 'tabs/role_overview_tab.dart';
import 'tabs/role_tasks_tab.dart';
import 'tabs/role_routines_tab.dart';
import 'tabs/add_task_sheet.dart';
import 'tabs/add_routine_sheet.dart';

class RoleDetailScreen extends StatefulWidget {
  final Role role;
  
  const RoleDetailScreen({super.key, required this.role});

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  int _currentIndex = 0;

  Widget? _buildFloatingActionButton() {
    if (_currentIndex == 1) {
      return FloatingActionButton.extended(
        backgroundColor: widget.role.color,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text("Task", style: TextStyle(color: Colors.white)),
        onPressed: () {
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
      return FloatingActionButton.extended(
        backgroundColor: widget.role.color,
        icon: const Icon(Icons.repeat, color: Colors.white),
        label: const Text("Routine", style: TextStyle(color: Colors.white)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => AddRoutineSheet(
              roleId: widget.role.id,
              roleColor: widget.role.color,
            ),
          );
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      RoleOverviewTab(role: widget.role),
      RoleTasksTab(role: widget.role),
      RoleRoutinesTab(role: widget.role),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.role.name),
        backgroundColor: widget.role.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: pages[_currentIndex],
      floatingActionButton: _buildFloatingActionButton(),
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