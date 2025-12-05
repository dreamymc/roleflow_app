import 'package:cloud_firestore/cloud_firestore.dart';

class Routine {
  final String id;
  final String title;
  final String description; // NEW: Context
  final int target; 
  final int count;  
  final int totalLifetimeCount; // NEW: Legacy Stat
  final String roleId;
  final DateTime lastUpdated; 
  final DateTime startDate; // NEW: "Started on..."

  Routine({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.count,
    required this.totalLifetimeCount,
    required this.roleId,
    required this.lastUpdated,
    required this.startDate,
  });

  factory Routine.fromFirestore(Map<String, dynamic> data, String id) {
    return Routine(
      id: id,
      title: data['title'] ?? 'Untitled Routine',
      description: data['description'] ?? '',
      target: data['target'] ?? 3,
      count: data['count'] ?? 0,
      totalLifetimeCount: data['totalLifetimeCount'] ?? 0,
      roleId: data['roleId'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime(2000),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'target': target,
      'count': count,
      'totalLifetimeCount': totalLifetimeCount,
      'roleId': roleId,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'startDate': Timestamp.fromDate(startDate),
    };
  }
}