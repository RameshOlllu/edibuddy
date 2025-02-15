import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../model/location_model.dart';
import '../../widgets/location_selector.dart';


class EmployerProfileScreen extends StatefulWidget {
  @override
  _EmployerProfileScreenState createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = true;
  File? _imageFile;
  String? _currentImageUrl;
  LocationModel? _currentLocation;
  
  // Controllers for editable fields
  final _schoolNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _establishedYearController = TextEditingController();
  final _boardAffiliationController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadEmployerData();
  }

  Future<void> _loadEmployerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      
      setState(() {
        _schoolNameController.text = data['schoolName'] ?? '';
        _contactNameController.text = data['contactName'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _descriptionController.text = data['companyDescription'] ?? '';
        _websiteController.text = data['website'] ?? '';
        _establishedYearController.text = data['establishedYear']?.toString() ?? '';
        _boardAffiliationController.text = data['boardAffiliation'] ?? '';
        _currentImageUrl = data['profileImageUrl'];
        
        if (data['location'] != null) {
          _currentLocation = LocationModel(
            city: data['location']['city'] ?? '',
            state: data['location']['state'] ?? '',
            pincode: data['location']['pincode'] ?? 0,
            area: data['location']['area'] ?? '',
          );
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentImageUrl;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not found');

      String? imageUrl = await _uploadImage();

      final userData = {
        'schoolName': _schoolNameController.text,
        'contactName': _contactNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'companyDescription': _descriptionController.text,
        'website': _websiteController.text,
        'establishedYear': int.tryParse(_establishedYearController.text),
        'boardAffiliation': _boardAffiliationController.text,
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
        if (imageUrl != null) 'profileImageUrl': imageUrl,
        if (_currentLocation != null) 'location': {
          'city': _currentLocation!.city,
          'state': _currentLocation!.state,
          'pincode': _currentLocation!.pincode,
          'area': _currentLocation!.area,
        },
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(userData);

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile', style: TextStyle( color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,),)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Institution Profile',style: TextStyle( color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,),),
           flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationSection(),
                    _buildDivider('Basic Information'),
                    _buildBasicInfoSection(),
                    _buildDivider('Additional Information'),
                    _buildAdditionalInfoSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : _currentImageUrl != null
                            ? NetworkImage(_currentImageUrl!)
                            : null,
                    child: (_imageFile == null && _currentImageUrl == null)
                        ? Icon(Icons.school, size: 50)
                        : null,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _schoolNameController.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        LocationSelectorWidget(
          initialLocation: _currentLocation,
          onLocationChanged: (location) {
            setState(() => _currentLocation = location);
          },
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _schoolNameController,
          label: 'Institution Name',
          icon: Icons.school,
          enabled: _isEditing,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _contactNameController,
          label: 'Contact Person',
          icon: Icons.person,
          enabled: _isEditing,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          enabled: false, // Email should not be editable
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _websiteController,
          label: 'Website',
          icon: Icons.language,
          enabled: _isEditing,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _establishedYearController,
          label: 'Year Established',
          icon: Icons.calendar_today,
          enabled: _isEditing,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _boardAffiliationController,
          label: 'Board Affiliation',
          icon: Icons.verified,
          enabled: _isEditing,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'About Institution',
          icon: Icons.description,
          enabled: _isEditing,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.withOpacity(0.1),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildDivider(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Divider(thickness: 1),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _establishedYearController.dispose();
    _boardAffiliationController.dispose();
    super.dispose();
  }
}