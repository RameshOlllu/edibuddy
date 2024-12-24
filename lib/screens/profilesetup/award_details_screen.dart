import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AwardDetailsScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const AwardDetailsScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<AwardDetailsScreen> createState() => _AwardDetailsScreenState();
}

class _AwardDetailsScreenState extends State<AwardDetailsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> awards = []; // List to hold award data
  final _formKey = GlobalKey<FormState>();

  // Controllers for Add/Edit Form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _organizationController =
      TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();
  String selectedType = 'Award'; // Default type
  DateTime? _receivedDate;

  // Supported types with icons
List<Map<String, dynamic>> achievementTypes = [
  {'type': 'Award', 'icon': Icons.star, 'color': Colors.amber},
  {'type': 'Recognition', 'icon': Icons.emoji_events, 'color': Colors.blue},
  {'type': 'Certification', 'icon': Icons.check_circle, 'color': Colors.green},
  {'type': 'Specialization', 'icon': Icons.school, 'color': Colors.purple},
];


  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && doc.data()?['awards'] != null) {
        setState(() {
          awards = List<Map<String, dynamic>>.from(doc.data()!['awards']);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load award details');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _saveAward() async {
    if (!_formKey.currentState!.validate()) return;

    final newAward = {
      'title': _titleController.text,
      'organization': _organizationController.text,
      'description': _descriptionController.text,
      'receivedDate': _receivedDate?.toIso8601String(),
      'type': selectedType, // Include selected type
    };

    setState(() {
      awards.add(newAward);
      _titleController.clear();
      _organizationController.clear();
      _descriptionController.clear();
      _receivedDate = null;
      selectedType = 'Award'; // Reset type
    });

    Navigator.pop(context); // Close the modal

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'awards': awards,
         'badges.award': {
          'earned': true,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),},);
    } catch (e) {
      _showErrorSnackBar('Failed to save award details');
    }
  }

  Future<void> _deleteAward(int index) async {
    setState(() {
      awards.removeAt(index);
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'awards': awards});
    } catch (e) {
      _showErrorSnackBar('Failed to delete award');
    }
  }

void _openAddAwardModal() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Achievement',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
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
                                  color: _receivedDate == null
                                      ? Colors.grey
                                      : Colors.black,
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
          ),
        ),
      );
    },
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
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}


  Widget _buildAwardCard(Map<String, dynamic> award, int index) {
    final typeData = achievementTypes.firstWhere(
        (type) => type['type'] == award['type'],
        orElse: () => achievementTypes[0]);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              typeData['icon'],
              color: typeData['color'],
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    award['title'] ?? 'Untitled',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    award['organization'] ?? 'Unknown Organization',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  if (award['description'] != null &&
                      award['description']!.isNotEmpty)
                    Text(
                      award['description']!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  if (award['receivedDate'] != null)
                    Text(
                      'Received: ${DateTime.parse(award['receivedDate']).day}/${DateTime.parse(award['receivedDate']).month}/${DateTime.parse(award['receivedDate']).year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAward(index),
            ),
          ],
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Your Achievements'),
      centerTitle: true,
    ),
    resizeToAvoidBottomInset: true, // Allows resizing when the keyboard shows
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: awards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No entries added yet.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _openAddAwardModal,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Entry'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: awards
                              .asMap()
                              .entries
                              .map((entry) =>
                                  _buildAwardCard(entry.value, entry.key))
                              .toList(),
                        ),
                ),
              ),

              // Bottom Action Buttons
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openAddAwardModal,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Entry'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onPrevious,
                              child: const Text('Previous'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(100, 48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onNext,
                              child: const Text('Next'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(100, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );
}


}
