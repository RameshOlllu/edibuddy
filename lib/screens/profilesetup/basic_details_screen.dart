import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../home/otp_verification_page.dart';
import '../../service/firebase_service.dart';

class BasicDetailsScreen extends StatefulWidget {
  final String userId;
  final void Function(bool isEarned) onNext;

  const BasicDetailsScreen(
      {Key? key, required this.userId, required this.onNext})
      : super(key: key);

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

  // Mobile verification fields
  bool _isMobileVerified = false;
  bool _isVerifyButtonEnabled = false;
  String? _verificationId;

String? _existingMobileNumber; // Stores the existing mobile number


  @override
  void initState() {
    super.initState();
    _fetchData();
  }

 Future<void> _fetchData() async {
  try {
    final userData = await _firebaseService.getUser(widget.userId);
    if (userData != null && mounted) {
      setState(() {
        basicDetails = userData['basicDetails'] ?? {};

        // Ensure 'dob' is converted to DateTime if it's a Timestamp
        if (basicDetails['dob'] is Timestamp) {
          basicDetails['dob'] = (basicDetails['dob'] as Timestamp).toDate();
        }

        photoURL = userData['photoURL'];

        // Normalize existing mobile number for display
        _existingMobileNumber = basicDetails['mobileNumber']
            ?.replaceFirst('+91', ''); // Remove prefix for user input field
        _isMobileVerified = userData['isMobileVerified'] ?? false;
      });
    }
  } catch (e) {
    debugPrint('Error fetching basic details: $e');
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => isUploadingProfileImage = true);
        final file = File(pickedFile.path);
        final imageUrl =
            await _firebaseService.uploadProfilePicture(widget.userId, file);

        await _firebaseService.updateUserField(
            widget.userId, 'photoURL', imageUrl);

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

Future<void> _checkAndVerifyMobileNumber(String mobileNumber) async {
  final normalizedMobileNumber = '+91$mobileNumber';

  try {
    // Check if mobile number exists in normalized format
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('basicDetails.mobileNumber', isEqualTo: normalizedMobileNumber)
        .get();

    if (query.docs.isNotEmpty) {
      // Mobile number already registered
      setState(() => _isVerifyButtonEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This mobile number is already registered.')),
      );
      return;
    }

    // Navigate to OTP Verification Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationPage(
          phoneNumber: normalizedMobileNumber,
          onVerificationComplete: (isVerified, isMerged, otp) async {
            if (isVerified) {
              // Update Firestore with verification status
              await _firebaseService.updateUser(widget.userId, {
                'basicDetails.mobileNumber': normalizedMobileNumber,
                'isMobileVerified': true,
              });

              setState(() {
                _isMobileVerified = true;
                _existingMobileNumber = mobileNumber;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Mobile number verified successfully.')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Mobile verification failed.')),
              );
            }
          },
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error verifying mobile: $e')),
    );
  }
}

 Future<void> _saveAndNext() async {
  if (isButtonDisabled ||
      !(_formKey.currentState?.saveAndValidate() ?? false)) return;

  setState(() => isButtonDisabled = true);

  try {
    // Normalize the mobile number with +91 prefix
    final mobileNumber = _formKey.currentState?.fields['mobileNumber']?.value;
    final normalizedMobileNumber =
        mobileNumber != null ? '+91$mobileNumber' : null;

    final updatedDetails = {
      ..._formKey.currentState!.value,
      'mobileNumber': normalizedMobileNumber,
    };

    await _firebaseService.updateUser(widget.userId, {
      'basicDetails': updatedDetails,
      'badges.basicdetails': {
        'earned': true,
        'earnedAt': FieldValue.serverTimestamp(),
      },
      'profileComplete': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    widget.onNext(true);
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
                      backgroundImage:
                          photoURL != null ? NetworkImage(photoURL!) : null,
                      child: photoURL == null
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: const Icon(Icons.person,
                                  size: 50, color: Colors.white),
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // Mobile Number and Verification
                  Row(
  children: [
    Expanded(
      child: FormBuilderTextField(
        name: 'mobileNumber',
        initialValue: _existingMobileNumber?.replaceFirst('+91', ''),
        decoration: InputDecoration(
          labelText: 'Mobile Number',
          prefixText: '+91 ',
          prefixStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color),
          prefixIcon: const Icon(Icons.phone),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.phone,
        onChanged: (value) {
          setState(() {
            _isVerifyButtonEnabled = RegExp(r'^[6-9]\d{9}$')
                .hasMatch(value ?? '');
          });
        },
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
          FormBuilderValidators.match(
            RegExp(r'^[6-9]\d{9}$'),
            errorText: 'Enter a valid mobile number',
          ),
        ]),
      ),
    ),
    const SizedBox(width: 8),
    ElevatedButton(
      onPressed: _isVerifyButtonEnabled
          ? () {
              final mobileNumber =
                  _formKey.currentState?.fields['mobileNumber']?.value;
              if (mobileNumber != null) {
                _checkAndVerifyMobileNumber(mobileNumber);
              }
            }
          : null,
      child: const Text('Verify'),
    ),
  ],
),
if (_isMobileVerified)
  Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
        const SizedBox(width: 8),
        Text(
          'Mobile number verified!',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    ),
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
