import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'pay_benefits_screen.dart';

class WalkInInterviewScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic>? jobData;
  final bool? isEdit;

  const WalkInInterviewScreen({
    Key? key,
    required this.jobId,
    this.jobData,
    this.isEdit,
  }) : super(key: key);

  @override
  _WalkInInterviewScreenState createState() => _WalkInInterviewScreenState();
}

class _WalkInInterviewScreenState extends State<WalkInInterviewScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _hasWalkIn = false;
  bool _isLoading = false;
  final List<WalkInSlot> _walkInSlots = [];
  final _venueController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  String? _selectedInterviewMode;
  bool _requiresDocuments = false;

  final List<String> _interviewModes = [
    'In-person only',
    'Virtual only',
    'Both in-person and virtual',
  ];

  final List<String> _requiredDocuments = [
    'Original Educational Certificates',
    'Experience Certificates',
    'Photo ID Proof',
    'Address Proof',
    'Teaching Certificates',
    'Portfolio',
    'Demo Class Plan',
  ];

  final List<String> _selectedDocuments = [];

  @override
  void initState() {
    super.initState();
    _loadWalkInData();
  }

  void _loadWalkInData() {
    if (widget.jobData != null && widget.jobData!['walkInDetails'] != null) {
      final walkInDetails = widget.jobData!['walkInDetails'];
      setState(() {
        _hasWalkIn = true;
        _venueController.text = walkInDetails['venue'] ?? '';
        _contactPersonController.text = walkInDetails['contactPerson'] ?? '';
        _contactNumberController.text = walkInDetails['contactNumber'] ?? '';
        _additionalInfoController.text = walkInDetails['additionalInfo'] ?? '';
        _selectedInterviewMode = walkInDetails['interviewMode'];
        _requiresDocuments = walkInDetails['requiresDocuments'] ?? false;
        
        if (walkInDetails['requiredDocuments'] != null) {
          _selectedDocuments.addAll(
            List<String>.from(walkInDetails['requiredDocuments']),
          );
        }

        if (walkInDetails['slots'] != null) {
          final slots = List<Map<String, dynamic>>.from(walkInDetails['slots']);
          _walkInSlots.addAll(
            slots.map((slot) => WalkInSlot(
              date: (slot['date'] as Timestamp).toDate(),
              startTime: TimeOfDay(
                hour: slot['startTime']['hour'],
                minute: slot['startTime']['minute'],
              ),
              endTime: TimeOfDay(
                hour: slot['endTime']['hour'],
                minute: slot['endTime']['minute'],
              ),
            )),
          );
        }
      });
    }
  }

  Future<void> _saveWalkInDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hasWalkIn && _walkInSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one walk-in slot')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final walkInDetails = _hasWalkIn
          ? {
              'hasWalkIn': true,
              'venue': _venueController.text,
              'contactPerson': _contactPersonController.text,
              'contactNumber': _contactNumberController.text,
              'additionalInfo': _additionalInfoController.text,
              'interviewMode': _selectedInterviewMode,
              'requiresDocuments': _requiresDocuments,
              'requiredDocuments': _selectedDocuments,
              'slots': _walkInSlots.map((slot) => {
                    'date': Timestamp.fromDate(slot.date),
                    'startTime': {
                      'hour': slot.startTime.hour,
                      'minute': slot.startTime.minute,
                    },
                    'endTime': {
                      'hour': slot.endTime.hour,
                      'minute': slot.endTime.minute,
                    },
                  }).toList(),
            }
          : {
              'hasWalkIn': false,
            };

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({'walkInDetails': walkInDetails});

      if (widget.isEdit == true) {
        Navigator.pop(context, true);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayBenefitsScreen(jobId: widget.jobId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving walk-in details: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWalkInSlot() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime day) {
        // Disable past dates and Sundays
        return day.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
            day.weekday != DateTime.sunday;
      },
    );

    if (date == null) return;

    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour + 2,
        minute: startTime.minute,
      ),
    );

    if (endTime == null) return;

    setState(() {
      _walkInSlots.add(WalkInSlot(
        date: date,
        startTime: startTime,
        endTime: endTime,
      ));
      _walkInSlots.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk-in Interview Details'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Walk-in Interview Availability',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Offer walk-in interviews'),
                      subtitle: const Text(
                        'Allow candidates to walk in for interviews on specific dates',
                      ),
                      value: _hasWalkIn,
                      onChanged: (value) {
                        setState(() => _hasWalkIn = value);
                      },
                    ),
                    if (_hasWalkIn) ...[
                      const SizedBox(height: 24),
                      _buildWalkInForm(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildWalkInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Interview Mode',
            border: OutlineInputBorder(),
          ),
          value: _selectedInterviewMode,
          items: _interviewModes
              .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedInterviewMode = value);
          },
          validator: (value) {
            if (value == null) return 'Please select an interview mode';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _venueController,
          decoration: const InputDecoration(
            labelText: 'Venue/Location',
            border: OutlineInputBorder(),
            hintText: 'Enter complete address for walk-in',
          ),
          maxLines: 2,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter the venue';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter contact person';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Interview Slots',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: _addWalkInSlot,
              icon: const Icon(Icons.add),
              label: const Text('Add Slot'),
            ),
          ],
        ),
        if (_walkInSlots.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No walk-in slots added yet'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _walkInSlots.length,
            itemBuilder: (context, index) {
              final slot = _walkInSlots[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(
                    DateFormat('EEE, MMM d, yyyy').format(slot.date),
                  ),
                  subtitle: Text(
                    '${slot.startTime.format(context)} - ${slot.endTime.format(context)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() => _walkInSlots.removeAt(index));
                    },
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: const Text('Require Documents'),
          subtitle: const Text('Specify documents needed for walk-in interview'),
          value: _requiresDocuments,
          onChanged: (value) {
            setState(() => _requiresDocuments = value);
          },
        ),
        if (_requiresDocuments) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _requiredDocuments.map((document) {
              final isSelected = _selectedDocuments.contains(document);
              return FilterChip(
                label: Text(document),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDocuments.add(document);
                    } else {
                      _selectedDocuments.remove(document);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _additionalInfoController,
          decoration: const InputDecoration(
            labelText: 'Additional Information',
            border: OutlineInputBorder(),
            hintText: 'Any additional instructions for candidates',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveWalkInDetails,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEdit == true ? 'Save Changes' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _venueController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }
}

class WalkInSlot {
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  WalkInSlot({
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}