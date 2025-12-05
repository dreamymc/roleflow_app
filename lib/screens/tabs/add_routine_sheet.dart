import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddRoutineSheet extends StatefulWidget {
  final String roleId;
  final Color roleColor;

  const AddRoutineSheet({
    super.key,
    required this.roleId,
    required this.roleColor,
  });

  @override
  State<AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends State<AddRoutineSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController(); // NEW
  double _targetFrequency = 3.0;
  bool _isSaving = false;

  Future<void> _saveRoutine() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('roles')
          .doc(widget.roleId)
          .collection('routines')
          .add({
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(), // Save Description
            'target': _targetFrequency.toInt(),
            'count': 0,
            'totalLifetimeCount': 0, // Start at 0
            'roleId': widget.roleId,
            // THE BUG FIX: Set date to the past so it's clickable today!
            'lastUpdated': DateTime(2000, 1, 1),
            'startDate': FieldValue.serverTimestamp(),
          });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Over-Achiever Routine',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.roleColor,
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Routine Name',
              hintText: 'e.g., Study Flutter',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.repeat),
            ),
          ),
          const SizedBox(height: 12),

          // NEW DESCRIPTION FIELD
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Protocol / Description',
              hintText: 'e.g., Read 10 pages before bed',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "Weekly Target: ${_targetFrequency.toInt()} times",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _targetFrequency,
            min: 1,
            max: 7,
            divisions: 6,
            activeColor: widget.roleColor,
            label: "${_targetFrequency.toInt()}x / week",
            onChanged: (val) => setState(() => _targetFrequency = val),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _isSaving ? null : _saveRoutine,
            style: FilledButton.styleFrom(
              backgroundColor: widget.roleColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Icon(Icons.add_circle),
            label: const Text('Start Routine'),
          ),
        ],
      ),
    );
  }
}
