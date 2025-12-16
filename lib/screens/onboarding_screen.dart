import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/auth_gate.dart'; // Needed to reload the app state

// A simple local model to hold role data temporarily before saving
class RoleData {
  String name;
  Color color;
  RoleData({required this.name, required this.color});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // The templates to show in the grid
  final List<String> _templates = [
    'Student',
    'Professional',
    'Parental',
    'Personal',
    'Health',
    'Custom',
  ];

  // The list of roles the user has actually created and customized locally
  final List<RoleData> _createdRoles = [];

  bool _isSaving = false;

  // --- 1. THE CUSTOMIZATION DIALOG (UPDATED) ---
  void _showRoleCreationDialog(String templateName) {
    String currentName = templateName == 'Custom' ? '' : templateName;
    // Default colors based on template vibe
    Color currentColor = switch (templateName) {
      'Student' => Colors.blue,
      'Professional' => Colors.indigo,
      'Parental' => Colors.orange,
      'Personal' => Colors.teal,
      'Health' => Colors.green,
      _ => Colors.purple, // Custom default
    };

    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder so the dialog can update its own state (color picker)
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Customize $templateName Role'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name Input
                    TextField(
                      controller: TextEditingController(text: currentName),
                      decoration: const InputDecoration(
                        labelText: 'Role Name',
                        hintText: 'e.g., Medical School',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => currentName = val,
                    ),
                    const SizedBox(height: 24),

                    // Color Picker Row (Now uses the PRO version)
                    _buildProColorRow(
                      context,
                      'Role Color Theme',
                      currentColor,
                      (color) {
                        setStateDialog(() => currentColor = color);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), // Cancel
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (currentName.trim().isEmpty) return;
                    // Add to the local list in the main screen state
                    setState(() {
                      _createdRoles.add(
                        RoleData(name: currentName.trim(), color: currentColor),
                      );
                    });
                    Navigator.pop(context); // Close Dialog
                  },
                  child: const Text('Add Role'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- HELPER: PRO COLOR PICKER (WHEEL + RGB SLIDERS) ---
  Widget _buildProColorRow(
    BuildContext context,
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700])),
        const Spacer(),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) {
                // Initialize local state for the dialog
                Color pickerColor = currentColor;

                return AlertDialog(
                  contentPadding: const EdgeInsets.all(0),
                  // SizedBox to control height of the TabBarView
                  content: SizedBox(
                    width: 340,
                    height: 450,
                    child: DefaultTabController(
                      length: 2,
                      child: StatefulBuilder(
                        builder: (context, setDialogState) {
                          return Column(
                            children: [
                              const TabBar(
                                labelColor: Colors.black,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: Colors.black,
                                tabs: [
                                  Tab(text: "Visual Wheel"),
                                  Tab(text: "RGB Inputs"),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    // TAB 1: THE DRAGGABLE WHEEL + HEX
                                    SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 16.0,
                                        ),
                                        child: ColorPicker(
                                          pickerColor: pickerColor,
                                          onColorChanged: (c) => setDialogState(
                                            () => pickerColor = c,
                                          ),
                                          enableAlpha: false,
                                          displayThumbColor: true,
                                          hexInputBar: true, // Hex is Editable
                                          paletteType: PaletteType.hsvWithHue,
                                          labelTypes: const [],
                                        ),
                                      ),
                                    ),
                                    // TAB 2: THE RGB SLIDERS + TEXT FIELDS
                                    Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: SlidePicker(
                                        pickerColor: pickerColor,
                                        onColorChanged: (c) => setDialogState(
                                          () => pickerColor = c,
                                        ),
                                        enableAlpha: false,
                                        displayThumbColor: true,
                                        showLabel: true, // Shows R: 255
                                        showIndicator: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    FilledButton(
                      child: const Text('Select'),
                      onPressed: () {
                        onColorChanged(pickerColor);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(
              Icons.palette,
              color: currentColor.computeLuminance() > 0.5
                  ? Colors.black54
                  : Colors.white70,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. THE SAVE LOGIC (Batch Write to Firestore) ---
  Future<void> _saveAndContinue() async {
    if (_createdRoles.isEmpty) return;

    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    // A Batch write is efficient: it sends all changes in one network request.
    WriteBatch batch = firestore.batch();

    for (var role in _createdRoles) {
      // Create a new empty document reference inside users/UID/roles/
      DocumentReference newRoleRef = firestore
          .collection('users')
          .doc(uid)
          .collection('roles')
          .doc();

      // Prepare data. We save color as an integer (AARRGGBB hex value)
      Map<String, dynamic> roleData = {
        'name': role.name,
        'color': role.color.value,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add to batch
      batch.set(newRoleRef, roleData);
    }

    try {
      // Commit all changes
      await batch.commit();

      if (mounted) {
        // HACK: Force reload the application state.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  // --- 3. THE MAIN UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Roles'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button
      ),
      // Floating button to finish setup
      floatingActionButton: _createdRoles.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveAndContinue,
              label: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Finish Setup (${_createdRoles.length})'),
              icon: const Icon(Icons.check),
              backgroundColor: Colors.blueGrey,
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Define your life compartments.\nTap a template to customize and add it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Area to show roles currently added to the list
            if (_createdRoles.isNotEmpty)
              Container(
                height: 60,
                margin: const EdgeInsets.only(bottom: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _createdRoles.length,
                  itemBuilder: (context, index) {
                    final role = _createdRoles[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        avatar: CircleAvatar(backgroundColor: role.color),
                        label: Text(role.name),
                        onDeleted: () {
                          setState(() {
                            _createdRoles.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

            // The Grid of Templates
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  childAspectRatio: 1.5, // wider than tall
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final tempName = _templates[index];
                  return InkWell(
                    onTap: () => _showRoleCreationDialog(tempName),
                    child: Card(
                      elevation: 2,
                      // Color code the templates slightly based on vibe
                      color: switch (tempName) {
                        'Student' => Colors.blue[50],
                        'Professional' => Colors.indigo[50],
                        'Personal' => Colors.teal[50],
                        _ => Colors.grey[50],
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              switch (tempName) {
                                'Student' => Icons.school,
                                'Professional' => Icons.work,
                                'Parental' => Icons.family_restroom,
                                'Personal' => Icons.self_improvement,
                                'Health' => Icons.fitness_center,
                                _ => Icons.edit,
                              },
                              size: 32,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tempName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
