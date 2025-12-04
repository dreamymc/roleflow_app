import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final DateTime? reminder; // Reminder is optional
  final bool isCompleted;
  final String roleId; // Links this task to a specific role (Contextual Isolation)

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.reminder,
    this.isCompleted = false,
    required this.roleId,
  });

  // Convert from Firestore
  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      reminder: (data['reminder'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] ?? false,
      roleId: data['roleId'] ?? '',
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'reminder': reminder != null ? Timestamp.fromDate(reminder!) : null,
      'isCompleted': isCompleted,
      'roleId': roleId,
      'createdAt': FieldValue.serverTimestamp(), // For sorting later
    };
  }
}