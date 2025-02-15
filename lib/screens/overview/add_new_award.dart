import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddAwardScreen extends StatefulWidget {
  final String userId;
  final Function(Map<String, dynamic>) onAwardAdded;

  const AddAwardScreen({
    Key? key,
    required this.userId,
    required this.onAwardAdded,
  }) : super(key: key);

  @override
  State<AddAwardScreen> createState() => _AddAwardScreenState();
}

class _AddAwardScreenState extends State<AddAwardScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String selectedType = 'Award';
  DateTime? _receivedDate;

  final List<Map<String, dynamic>> achievementTypes = [
    {'type': 'Award', 'icon': Icons.star, 'color': Colors.amber},
    {'type': 'Recognition', 'icon': Icons.emoji_events, 'color': Colors.blue},
    {'type': 'Certification', 'icon': Icons.check_circle, 'color': Colors.green},
    {'type': 'Specialization', 'icon': Icons.school, 'color': Colors.purple},
  ];

Future<void> _saveAward() async {
  if (!_formKey.currentState!.validate()) return;

  final newAward = {
    'title': _titleController.text,
    'organization': _organizationController.text,
    'description': _descriptionController.text,
    'receivedDate': _receivedDate?.toIso8601String(),
    'type': selectedType, // Include selected type
  };

  try {
    // Add the new award to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'awards': FieldValue.arrayUnion([newAward]),
      'badges.award': {
        'earned': true,
        'earnedAt': FieldValue.serverTimestamp(),
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Pass the new award back to the widget using the callback
    widget.onAwardAdded(newAward);


    Navigator.pop(context); // Close the modal after saving
  } catch (e) {
    // Handle errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Failed to save award details'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Achievement'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Achievement',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),

              // Type Dropdown
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: DropdownButtonFormField<String>(
                  value: selectedType,
                  items: achievementTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['type'] as String,
                      child: Row(
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            color: type['color'] as Color,
                          ),
                          const SizedBox(width: 8),
                          Text(type['type'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Title Field
              _buildInputField(
                controller: _titleController,
                label: 'Title*',
                hint: 'Enter achievement title',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Organization Field
              _buildInputField(
                controller: _organizationController,
                label: 'Organization*',
                hint: 'Enter organization name',
                icon: Icons.business_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Organization is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              _buildInputField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Optional description',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Received Date
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() => _receivedDate = pickedDate);
                  }
                },
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _receivedDate == null
                              ? 'Select Received Date'
                              : '${_receivedDate!.day}/${_receivedDate!.month}/${_receivedDate!.year}',
                          style: TextStyle(
                            color: _receivedDate == null ? Colors.grey : Colors.black,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveAward,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor:
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
