import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/location_model.dart';
import '../../widgets/animated_text_field.dart';
import '../../widgets/location_search_widget.dart';
import '../../widgets/search_location_card.dart';
import 'add_job_details.dart';

class AddJobBasicsScreen extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? jobData;

  const AddJobBasicsScreen({Key? key, this.jobId, this.jobData}) : super(key: key);

  @override
  _AddJobBasicsScreenState createState() => _AddJobBasicsScreenState();
}

class _AddJobBasicsScreenState extends State<AddJobBasicsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isRemote = false;
  LocationModel? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  void _loadJobData() {
    if (widget.jobData != null) {
      _titleController.text = widget.jobData?['jobTitle'] ?? '';
      _descriptionController.text = widget.jobData?['companyDescription'] ?? '';
      _isRemote = widget.jobData?['jobLocation'] == 'Remote';
      
      // Load location data if available
      final locationData = widget.jobData?['locationDetails'];
      if (locationData != null) {
        _selectedLocation = LocationModel.fromJson(locationData);
      }
    }
  }

  Future<void> saveJobBasics() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isRemote && _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final jobData = {
        'jobTitle': _titleController.text,
        'companyDescription': _descriptionController.text,
        'isRemote': _isRemote,
        'jobLocation': _isRemote ? 'Remote' : _selectedLocation.toString(),
        'locationDetails': _isRemote ? null : _selectedLocation?.toJson(),
        'userId': user.uid,
        'updatedAt': Timestamp.now(),
      };

      if (widget.jobId != null) {
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .set({
              ...jobData,
              'lastUpdateDate': Timestamp.now(),
            }, SetOptions(merge: true));
        
        Navigator.pop(context, true);
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('jobs')
            .add({
              ...jobData,
              'creationDate': Timestamp.now(),
              'status': 'draft',
            });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(
              jobId: docRef.id,
              jobData: jobData,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving job basics: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobId != null ? 'Edit Job Basics' : 'Add Job Basics'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJobTitleSection(),
                    const SizedBox(height: 24),
                    _buildCompanyDescriptionSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
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

  Widget _buildJobTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   'Job Title',
        //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
        //         fontWeight: FontWeight.bold,
        //       ),
        // ),
        // const SizedBox(height: 8),
        AnimatedTextField(
          label: 'Job Title',
          controller: _titleController,
          hint: 'e.g., Math Teacher - High School',
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter a job title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCompanyDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   'Company Description',
        //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
        //         fontWeight: FontWeight.bold,
        //       ),
        // ),
        // const SizedBox(height: 8),
        AnimatedTextField(
          label: 'Company Description',
          controller: _descriptionController,
          hint: 'Brief overview of your institution...',
          maxLines: 3,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please provide a company description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('This is a remote position'),
          subtitle: const Text('Candidates can work from anywhere'),
          value: _isRemote,
          onChanged: (value) {
            setState(() => _isRemote = value);
          },
        ),
        if (!_isRemote) ...[
          const SizedBox(height: 16),
          LocationSearchWidget(
            onLocationSelected: (location) {
              setState(() => _selectedLocation = location);
            },
            initialLocation: _selectedLocation,
          ),
          if (_selectedLocation != null)
            SelectedLocationCard(
              location: _selectedLocation!,
              onDelete: () {
                setState(() => _selectedLocation = null);
              },
            ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
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
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : saveJobBasics,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.jobId != null ? 'Save Changes' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}