import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Ensure you installed this
import '../../models/role.dart';
import '../../services/ai_service.dart';

class RoleOverviewTab extends StatefulWidget {
  final Role role;
  const RoleOverviewTab({super.key, required this.role});

  @override
  State<RoleOverviewTab> createState() => _RoleOverviewTabState();
}

class _RoleOverviewTabState extends State<RoleOverviewTab> {
  String? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  // Trigger the (Mock) Brain
  Future<void> _loadSummary() async {
    // In a real app, we would fetch tasks/logs here first to pass to the AI
    final result = await AIService().generateRoleSummary(widget.role);
    
    if (mounted) {
      setState(() {
        _summary = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ------------------------------------------------
          // 1. QUICK STATS ROW (Real Data)
          // ------------------------------------------------
          // We display real numbers here to give the "AI" context visually
          Row(
            children: [
              Expanded(
                child: _buildLiveStatCard(
                  user!.uid, 
                  'tasks', 
                  Icons.check_circle_outline, 
                  "Pending Tasks"
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLiveStatCard(
                  user.uid, 
                  'routines', 
                  Icons.repeat, 
                  "Active Habits"
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // ------------------------------------------------
          // 2. THE AI INSIGHT SECTION
          // ------------------------------------------------
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple[300], size: 20),
              const SizedBox(width: 8),
              Text(
                "RoleFlow Intelligence",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // THE BRAIN BOX
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoading 
                ? _buildShimmerLoading() // Show Skeleton
                : Text(
                    _summary ?? "Unable to generate summary.",
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- HELPER: SHIMMER SKELETON ---
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: double.infinity, height: 12, color: Colors.white),
          const SizedBox(height: 8),
          Container(width: double.infinity, height: 12, color: Colors.white),
          const SizedBox(height: 8),
          Container(width: 200, height: 12, color: Colors.white),
          const SizedBox(height: 16),
          Container(width: double.infinity, height: 12, color: Colors.white),
          const SizedBox(height: 8),
          Container(width: 150, height: 12, color: Colors.white),
        ],
      ),
    );
  }

  // --- HELPER: LIVE STAT CARD ---
  Widget _buildLiveStatCard(String uid, String collection, IconData icon, String label) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('roles')
          .doc(widget.role.id)
          .collection(collection)
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          if (collection == 'tasks') {
            // Filter only incomplete tasks for the stat
            count = snapshot.data!.docs.where((doc) => doc['isCompleted'] == false).length;
          } else {
            count = snapshot.data!.docs.length;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.role.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: widget.role.color, size: 24),
              const SizedBox(height: 8),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: widget.role.color
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, 
                  color: widget.role.color.withOpacity(0.8),
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}