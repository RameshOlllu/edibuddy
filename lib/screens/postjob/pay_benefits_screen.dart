import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/animated_text_field.dart';
import 'job_description_screen.dart';

class PayBenefitsScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic>? jobData;
  final bool? isEdit;

  PayBenefitsScreen({required this.jobId, this.jobData, this.isEdit});

  @override
  _PayBenefitsScreenState createState() => _PayBenefitsScreenState();
}

class _PayBenefitsScreenState extends State<PayBenefitsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final List<String> _selectedCompensation = [];
  final List<String> _selectedBenefits = [];

  final List<String> _compensationTypes = [
    'Performance bonus',
    'Commission pay',
    'Yearly bonus',
    'Bonus pay',
    'Quarterly bonus',
  ];

  final List<String> _benefitTypes = [
    'Cell phone reimbursement',
    'Provident Fund',
    'Health insurance',
    'Internet reimbursement',
    'Commuter assistance',
    'Paid sick time',
    'Flexible schedule',
    'Leave encashment',
    'Paid time off',
    'Work from home',
    'Food provided',
    'Life insurance',
  ];

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  void _loadJobData() {
    if (widget.jobData != null) {
      _minSalaryController.text =
          widget.jobData?['minSalary']?.toString() ?? '';
      _maxSalaryController.text =
          widget.jobData?['maxSalary']?.toString() ?? '';
      _selectedCompensation.clear();
      _selectedCompensation
          .addAll(List<String>.from(widget.jobData?['compensation'] ?? []));
      _selectedBenefits.clear();
      _selectedBenefits
          .addAll(List<String>.from(widget.jobData?['benefits'] ?? []));
    }
  }

  Future<void> savePayBenefits() async {
    try {
      final jobDetails = {
        'minSalary': double.tryParse(_minSalaryController.text),
        'maxSalary': double.tryParse(_maxSalaryController.text),
        'compensation': _selectedCompensation,
        'benefits': _selectedBenefits,
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update(jobDetails);
      if (widget.isEdit != null) {
        // Edit flow
        Navigator.pop(context, true);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDescriptionScreen(jobId: widget.jobId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving pay and benefits: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pay & Benefits'),
      ),
      body: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(bottom: 80), // Leave space for buttons
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Specify Pay & Benefits',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedTextField(
                            controller: _minSalaryController,
                            label: 'Minimum Salary',
                            hint: 'Enter amount',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnimatedTextField(
                            controller: _maxSalaryController,
                            label: 'Maximum Salary',
                            hint: 'Enter amount',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              final min =
                                  double.tryParse(_minSalaryController.text);
                              final max = double.tryParse(value!);
                              if (min != null && max != null && max < min) {
                                return 'Must be > min';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Compensation',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _compensationTypes.map((comp) {
                        final isSelected = _selectedCompensation.contains(comp);
                        return FilterChip(
                          label: Text(comp),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCompensation.add(comp);
                              } else {
                                _selectedCompensation.remove(comp);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Benefits',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _benefitTypes.map((benefit) {
                        final isSelected = _selectedBenefits.contains(benefit);
                        return FilterChip(
                          label: Text(benefit),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedBenefits.add(benefit);
                              } else {
                                _selectedBenefits.remove(benefit);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          savePayBenefits();
                        }
                      },
                      child: Text(widget.isEdit != null
                          ? 'Save & Close'
                          : 'Save & Continue'),
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

  @override
  void dispose() {
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }
}
