import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../service/firebase_service.dart';

class BasicDetailsScreen extends StatefulWidget {
  final String userId;
final void Function(bool isEarned) onNext;


  const BasicDetailsScreen({Key? key, required this.userId, required this.onNext}) : super(key: key);

  @override
  _BasicDetailsScreenState createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic> basicDetails = {};
  bool isLoading = true;
  bool isButtonDisabled = false;
  String? photoURL;
  bool isUploadingProfileImage = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

Future<void> _fetchData() async {
  try {
    final userData = await _firebaseService.getUser(widget.userId);
    if (userData != null) {
      setState(() {
        basicDetails = userData['basicDetails'] ?? {};

        // Ensure 'dob' is converted to DateTime if it's a Timestamp
        if (basicDetails['dob'] is Timestamp) {
          basicDetails['dob'] = (basicDetails['dob'] as Timestamp).toDate();
        }

        photoURL = userData['photoURL'];
      });
    }
  } catch (e) {
    debugPrint('Error fetching basic details: $e');
  } finally {
    setState(() => isLoading = false);
  }
}


  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => isUploadingProfileImage = true);
        final file = File(pickedFile.path);
        final imageUrl = await _firebaseService.uploadProfilePicture(widget.userId, file);

        await _firebaseService.updateUserField(widget.userId, 'photoURL', imageUrl);

        setState(() {
          photoURL = imageUrl;
          isUploadingProfileImage = false;
        });
      }
    } catch (e) {
      setState(() => isUploadingProfileImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

Future<void> _saveAndNext() async {
  if (isButtonDisabled || !(_formKey.currentState?.saveAndValidate() ?? false)) return;

  setState(() => isButtonDisabled = true);

 try {
      await _firebaseService.updateUser(widget.userId, {
        'basicDetails': _formKey.currentState!.value,
        'badges.basicdetails': {
          'earned': true,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'profileComplete':false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Before next');
      widget.onNext(true);
       print('aftrer on  next');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() => isButtonDisabled = false);
  }
}

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        children: [
          // Profile Picture Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
                      child: photoURL == null
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: const Icon(Icons.person, size: 50, color: Colors.white),
                            )
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera),
                                  title: const Text('Take a photo'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.camera);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Choose from gallery'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.gallery);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (isUploadingProfileImage)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),

          // Form Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FormBuilder(
                key: _formKey,
                initialValue: basicDetails,
                child: Column(
                  children: [
                    // Full Name
                    FormBuilderTextField(
                      name: 'fullName',
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    // Date of Birth
                    FormBuilderDateTimePicker(
                      name: 'dob',
                      inputType: InputType.date,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    // Gender
                    FormBuilderDropdown(
                      name: 'gender',
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.transgender),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    // Email
                    FormBuilderTextField(
                      name: 'email',
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isButtonDisabled ? null : _saveAndNext,
                  child: const Text("Next"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
