import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure you import intl for date formatting
import 'package:roleflow_app/screens/tabs/edit_routine_sheet.dart';
import '../../models/role.dart';
import '../../models/routine_model.dart';

class RoleRoutinesTab extends StatelessWidget {
  final Role role;
  const RoleRoutinesTab({super.key, required this.role});

  // --- LOGIC 1: INCREMENT (Weekly + Lifetime) ---
  Future<void> _incrementRoutine(BuildContext context, Routine routine) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final routineRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('roles')
        .doc(role.id)
        .collection('routines')
        .doc(routine.id);

    // Update Count + Lifetime + Timestamp
    await routineRef.update({
      'count': FieldValue.increment(1),
      'totalLifetimeCount': FieldValue.increment(1), // Legacy tracking
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      _showJournalDialog(context, routine, routineRef);
    }
  }

  // --- LOGIC 2: UNDO ---
  Future<void> _undoRoutine(BuildContext context, Routine routine) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('roles')
        .doc(role.id)
        .collection('routines')
        .doc(routine.id)
        .update({
          'count': FieldValue.increment(-1),
          'totalLifetimeCount': FieldValue.increment(-1),
          'lastUpdated': DateTime(2000, 1, 1), // Reset date to unlock button
        });
  }

  void _showJournalDialog(
    BuildContext context,
    Routine routine,
    DocumentReference routineRef,
  ) {
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Checked In! ✅",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Great work on '${routine.title}'!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Add a quick note (Optional)',
                hintText: 'e.g., Felt tired but pushed through...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final note = noteController.text.trim();
                if (note.isNotEmpty) {
                  await routineRef.collection('logs').add({
                    'note': note,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(backgroundColor: role.color),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDoneToday(DateTime lastUpdated) {
    final now = DateTime.now();
    return now.year == lastUpdated.year &&
        now.month == lastUpdated.month &&
        now.day == lastUpdated.day;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('roles')
          .doc(role.id)
          .collection('routines')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text('Error loading routines'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              "No routines yet. Tap 'Routine' to add one.",
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final routine = Routine.fromFirestore(data, docs[index].id);

            final bool isCompletedToday = _isDoneToday(routine.lastUpdated);
            final bool isTargetMet = routine.count >= routine.target;
            final bool isOverAchiever = routine.count > routine.target;
            final double progress = (routine.count / routine.target).clamp(
              0.0,
              1.0,
            );

            // Format start date (e.g., "Nov 2023")
            final startStr = DateFormat(
              'MMM d, yyyy',
            ).format(routine.startDate);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isOverAchiever
                    ? const BorderSide(color: Colors.amber, width: 2)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW 1: Title & Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WRAP THIS COLUMN IN EXPANDED + INKWELL TO MAKE IT CLICKABLE
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) => EditRoutineSheet(
                                  routine: routine,
                                  roleId: role.id,
                                  roleColor: role.color,
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      routine.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.grey[400],
                                    ), // Small hint icon
                                  ],
                                ),
                                if (routine.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      routine.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ACTION BUTTON (Unchanged)
                        isCompletedToday
                            ? Tooltip(
                                message: "Done for today! Long press to undo.",
                                child: InkWell(
                                  onLongPress: () =>
                                      _undoRoutine(context, routine),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.grey[300],
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : IconButton.filled(
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(
                                  backgroundColor: isTargetMet
                                      ? (isOverAchiever
                                            ? Colors.amber
                                            : Colors.green)
                                      : role.color,
                                ),
                                onPressed: () =>
                                    _incrementRoutine(context, routine),
                              ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ROW 2: Progress Bar & Weekly Stats
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation(
                                isOverAchiever
                                    ? Colors.amber
                                    : (isTargetMet ? Colors.green : role.color),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isOverAchiever
                              ? "OVER-ACHIEVER! 🔥"
                              : "${routine.count}/${routine.target} this week",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isOverAchiever
                                ? Colors.amber[800]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(),

                    // ROW 3: Lifetime Stats (The Legacy Factor)
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.orange[800],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${routine.totalLifetimeCount} total checks",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Started $startStr",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
