import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Role {
  final String id;
  final String name;
  final Color color;
  final DateTime createdAt;

  Role({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  // Factory constructor to create a Role object from a Firestore document
  factory Role.fromFirestore(Map<String, dynamic> data, String id) {
    // Firestore stores Color as an integer (ARGB value), so we convert it back to a Flutter Color object.
    int colorValue = data['color'] as int? ?? Colors.blueGrey.value;

    return Role(
      id: id,
      name: data['name'] as String? ?? 'Unnamed Role',
      color: Color(colorValue),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Method to convert the Role object back to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': color.value, // Store as integer
      'createdAt': createdAt,
    };
  }
}