import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/routine_model.dart';

class EditRoutineSheet extends StatefulWidget {
  final Routine routine;
  final String roleId;
  final Color roleColor;

  const EditRoutineSheet({
    super.key, 
    required this.routine, 
    required this.roleId, 
    required this.roleColor
  });

  @override
  State<EditRoutineSheet> createState() => _EditRoutineSheetState();
}

class _EditRoutineSheetState extends State<EditRoutineSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late double _targetFrequency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data
    _titleController = TextEditingController(text: widget.routine.title);
    _descController = TextEditingController(text: widget.routine.description);
    _targetFrequency = widget.routine.target.toDouble();
  }

  Future<void> _updateRoutine() async {
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
          .doc(widget.routine.id)
          .update({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'target': _targetFrequency.toInt(),
        // We DO NOT update count or stats here to preserve history
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteRoutine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine?'),
        content: const Text('This will remove all progress and history for this routine. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('roles')
          .doc(widget.roleId)
          .collection('routines')
          .doc(widget.routine.id)
          .delete();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Routine',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.roleColor),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _isSaving ? null : _deleteRoutine,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Routine Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.repeat),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Protocol / Description',
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
            onPressed: _isSaving ? null : _updateRoutine,
            style: FilledButton.styleFrom(
              backgroundColor: widget.roleColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
              : const Icon(Icons.save_as),
            label: const Text('Update Routine'),
          ),
        ],
      ),
    );
  }
}