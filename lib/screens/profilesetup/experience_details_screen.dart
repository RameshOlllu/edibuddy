import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import '../../data/experience_data.dart';

class ExperienceDetailsScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const ExperienceDetailsScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<ExperienceDetailsScreen> createState() =>
      _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState extends State<ExperienceDetailsScreen> {
  List<Map<String, dynamic>> experienceDetails = [];
  bool isLoading = true;
  bool isAddingExperience = false;
  Map<String, dynamic>? editingExperience;
  final _formKey = GlobalKey<FormBuilderState>();
  final _jobTitleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _locationController = TextEditingController();

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

      if (doc.exists && doc.data()?['experienceDetails'] != null) {
        setState(() {
          experienceDetails =
              List<Map<String, dynamic>>.from(doc.data()!['experienceDetails']);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load experience details');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _checkAndUpdateCurrentPosition(bool isCurrentPosition) async {
    if (isCurrentPosition) {
      final currentPositionIndex =
          experienceDetails.indexWhere((exp) => exp['isCurrent'] == true);
      if (currentPositionIndex != -1) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update Current Position'),
            content: const Text(
                'You already have a current position. Would you like to update it?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Update'),
              ),
            ],
          ),
        ).then((shouldUpdate) {
          if (shouldUpdate) {
            setState(() {
              experienceDetails[currentPositionIndex]['isCurrent'] = false;
            });
          } else {
            _formKey.currentState?.fields['isCurrent']?.didChange(false);
          }
        });
      }
    }
  }

  Future<void> _saveExperience() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final formData = _formKey.currentState!.value;

    await _checkAndUpdateCurrentPosition(formData['isCurrent'] ?? false);

    final newExperience = {
      'jobTitle': _jobTitleController.text,
      'companyName': _companyNameController.text,
      'startDate': formData['startDate']?.toString().split(' ')[0],
      'endDate': formData['isCurrent'] == true
          ? null
          : formData['endDate']?.toString().split(' ')[0],
      'isCurrent': formData['isCurrent'] ?? false,
      'location': _locationController.text,
    };

    setState(() {
      if (editingExperience != null) {
        final index = experienceDetails.indexOf(editingExperience!);
        experienceDetails[index] = newExperience;
      } else {
        experienceDetails.add(newExperience);
      }
      isAddingExperience = false;
      editingExperience = null;
      _jobTitleController.clear();
      _companyNameController.clear();
      _locationController.clear();
    });
  }

  Future<void> _saveAndNext() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'experienceDetails': experienceDetails,
        'badges.experience': {
          'earned': true,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) widget.onNext();
    } catch (e) {
      _showErrorSnackBar('Failed to save experience details');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Experience Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isAddingExperience) ...[
                          if (experienceDetails.isEmpty)
                            _buildEmptyState()
                          else ...[
                            Text(
                              'Your Experience',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ...experienceDetails
                                .map((exp) => _buildExperienceCard(exp)),
                          ],
                          const SizedBox(height: 16),
                          Center(
                            child: FilledButton.tonalIcon(
                              onPressed: () => setState(() {
                                isAddingExperience = true;
                                editingExperience = null;
                              }),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Experience'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ] else
                          _buildExperienceForm(),
                      ],
                    ),
                  ),
                ),
                if (!isAddingExperience)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onPrevious,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Previous'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: experienceDetails.isEmpty
                                  ? null
                                  : _saveAndNext,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Next'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Experience Added Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding your teaching experience\nto complete your profile',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => setState(() {
              isAddingExperience = true;
              editingExperience = null;
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Experience'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(Map<String, dynamic> experience) {
    final colorScheme = Theme.of(context).colorScheme;
    final startDate = DateTime.parse(experience['startDate']);
    final endDate = experience['endDate'] != null
        ? DateTime.parse(experience['endDate'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            editingExperience = experience;
            isAddingExperience = true;
            _jobTitleController.text = experience['jobTitle'];
            _companyNameController.text = experience['companyName'];
            _locationController.text = experience['location'];
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.work_rounded,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          experience['jobTitle'],
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          experience['companyName'],
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    color: colorScheme.primary,
                    onPressed: () {
                      setState(() {
                        editingExperience = experience;
                        isAddingExperience = true;
                        _jobTitleController.text = experience['jobTitle'];
                        _companyNameController.text = experience['companyName'];
                        _locationController.text = experience['location'];
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      experience['location'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('MMM yyyy').format(startDate)} - ${experience['isCurrent'] ? 'Present' : DateFormat('MMM yyyy').format(endDate!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (experience['isCurrent'])
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Current Position',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceForm() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            editingExperience != null
                                ? Icons.edit_note_rounded
                                : Icons.work_history_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          editingExperience != null
                              ? 'Edit Experience'
                              : 'Add Experience',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        isAddingExperience = false;
                        editingExperience = null;
                        _jobTitleController.clear();
                        _companyNameController.clear();
                        _locationController.clear();
                      }),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            colorScheme.errorContainer.withOpacity(0.1),
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: TypeAheadField<String>(
                    controller: _jobTitleController,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Job Title*',
                          hintText: 'e.g., Mathematics Teacher',
                          prefixIcon: Icon(
                            Icons.work_rounded,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          filled: true,
                          fillColor:
                              colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      return ExperienceData.getAllJobTitles()
                          .where((title) => title
                              .toLowerCase()
                              .contains(pattern.toLowerCase()))
                          .toList();
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        leading: Icon(
                          Icons.school_rounded,
                          color: colorScheme.primary,
                        ),
                        title: Text(suggestion),
                      );
                    },
                    onSelected: (suggestion) {
                      _jobTitleController.text = suggestion;
                    },
                    decorationBuilder: (context, child) {
                      return Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: TypeAheadField<String>(
                    controller: _companyNameController,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Institution Name*',
                          prefixIcon: Icon(
                            Icons.apartment_rounded,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                           
                          ),
                          filled: true,
                          fillColor:
                              colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      return ExperienceData.companies
                          .where((company) => company
                              .toLowerCase()
                              .contains(pattern.toLowerCase()))
                          .toList();
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        leading: Icon(
                          Icons.apartment_rounded,
                          color: colorScheme.primary,
                        ),
                        title: Text(suggestion),
                      );
                    },
                    onSelected: (suggestion) {
                      _companyNameController.text = suggestion;
                    },
                    decorationBuilder: (context, child) {
                      return Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderDateTimePicker(
                        name: 'startDate',
                        initialValue: editingExperience != null
                            ? DateTime.parse(editingExperience!['startDate'])
                            : null,
                        inputType: InputType.date,
                        format: DateFormat('yyyy-MM-dd'),
                        decoration: InputDecoration(
                          labelText: 'Start Date*',
                          prefixIcon: Icon(
                            Icons.calendar_today_rounded,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          filled: true,
                          fillColor:
                              colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                        validator: FormBuilderValidators.required(
                          errorText: 'Please select start date',
                        ),
                      ),
                    ),
                    if (_formKey.currentState?.fields['isCurrent']?.value !=
                        true) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderDateTimePicker(
                          name: 'endDate',
                          initialValue: editingExperience != null &&
                                  editingExperience!['endDate'] != null
                              ? DateTime.parse(editingExperience!['endDate'])
                              : null,
                          inputType: InputType.date,
                          format: DateFormat('yyyy-MM-dd'),
                          decoration: InputDecoration(
                            labelText: 'End Date*',
                            prefixIcon: Icon(
                              Icons.event_rounded,
                              color: colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            filled: true,
                            fillColor:
                                colorScheme.surfaceVariant.withOpacity(0.5),
                          ),
                          validator: (value) {
                            if (_formKey.currentState?.fields['isCurrent']
                                        ?.value !=
                                    true &&
                                value == null) {
                              return 'Please enter end date';
                            }
                            if (value != null &&
                                _formKey.currentState?.fields['startDate']
                                        ?.value !=
                                    null &&
                                value.isBefore(_formKey.currentState!
                                    .fields['startDate']!.value)) {
                              return 'End date must be after start date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: FormBuilderSwitch(
                    name: 'isCurrent',
                    title: Row(
                      children: [
                        Icon(
                          Icons.work_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Current Position'),
                        const SizedBox(width: 8),
                        if (_formKey.currentState?.fields['isCurrent']?.value ==
                            true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    initialValue: editingExperience?['isCurrent'] ?? false,
                    onChanged: (value) {
                      if (value == true) {
                        _formKey.currentState?.fields['endDate']
                            ?.didChange(null);
                      }
                      setState(() {});
                    },
                    activeColor: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: TypeAheadField<String>(
                    controller: _locationController,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Location*',
                          hintText: 'e.g., Mumbai',
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          filled: true,
                          fillColor:
                              colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      return ExperienceData.cities
                          .where((city) => city
                              .toLowerCase()
                              .contains(pattern.toLowerCase()))
                          .toList();
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        leading: Icon(
                          Icons.location_city_rounded,
                          color: colorScheme.primary,
                        ),
                        title: Text(suggestion),
                      );
                    },
                    onSelected: (suggestion) {
                      _locationController.text = suggestion;
                    },
                    decorationBuilder: (context, child) {
                      return Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          isAddingExperience = false;
                          editingExperience = null;
                          _jobTitleController.clear();
                          _companyNameController.clear();
                          _locationController.clear();
                        }),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saveExperience,
                        icon: Icon(
                          editingExperience != null
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                        ),
                        label: Text(
                          editingExperience != null ? 'Update' : 'Save',
                        ),
                        style: FilledButton.styleFrom(
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
    );
  }

  // Continue with your existing _buildExperienceForm() method...
}
