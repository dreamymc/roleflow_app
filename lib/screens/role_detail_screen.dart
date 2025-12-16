import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role.dart';
import '../services/ai_service.dart'; // Ensure this import is correct

// import 'tabs/role_overview_tab.dart'; // REMOVED: We defined it below for the Refresh Logic
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
      // TASKS FAB
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
      // ROUTINES FAB
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
      // 1. OVERVIEW (Defined below with Refresh Logic)
      RoleOverviewTab(role: widget.role),
      // 2. TASKS (Kept external)
      RoleTasksTab(role: widget.role),
      // 3. ROUTINES (Kept external)
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
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Routines'),
        ],
      ),
    );
  }
}

// ==============================================================================
// INTERNAL CLASS: RoleOverviewTab
// Moved here to implement the specific AI Refresh Logic needed
// ==============================================================================

class RoleOverviewTab extends StatefulWidget {
  final Role role;
  const RoleOverviewTab({super.key, required this.role});

  @override
  State<RoleOverviewTab> createState() => _RoleOverviewTabState();
}

class _RoleOverviewTabState extends State<RoleOverviewTab> {
  // Changing this key forces the FutureBuilder to re-run (Refresh)
  Key _refreshKey = UniqueKey();

  void _refreshSummary() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. AI INTELLIGENCE CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: widget.role.color.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: widget.role.color,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "RoleFlow Intelligence",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    // --- THE REFRESH BUTTON ---
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: _refreshSummary, // Rebuilds the FutureBuilder
                      tooltip: "Retry AI Analysis",
                    ),
                  ],
                ),
                const Divider(height: 24),

                // FUTURE BUILDER FOR AI
                FutureBuilder<String>(
                  key: _refreshKey, // Key change triggers re-run
                  future: AIService().generateRoleSummary(widget.role),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerLoading();
                    }
                    if (snapshot.hasError) {
                      return Text(
                        "System Error. Tap refresh to try again.",
                        style: TextStyle(color: Colors.red[300]),
                      );
                    }

                    // Display result (Success OR the "Unavailable" message)
                    return Text(
                      snapshot.data ?? "No insight available.",
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. LIVE STATS ROW
          const Text(
            "Live Status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Pending Tasks Stat
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('roles')
                      .doc(widget.role.id)
                      .collection('tasks')
                      .where('isCompleted', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return _OverviewStatCard(
                      label: "Pending",
                      count: count.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.orangeAccent,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Active Routines Stat
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('roles')
                      .doc(widget.role.id)
                      .collection('routines')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return _OverviewStatCard(
                      label: "Habits",
                      count: count.toString(),
                      icon: Icons.repeat,
                      color: Colors.blueAccent,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 14, width: double.infinity, color: Colors.grey[100]),
        const SizedBox(height: 8),
        Container(height: 14, width: 200, color: Colors.grey[100]),
        const SizedBox(height: 8),
        Container(height: 14, width: 250, color: Colors.grey[100]),
      ],
    );
  }
}

// Simple Stat Card for the Overview
class _OverviewStatCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;

  const _OverviewStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}
