import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmployerSignUpPage extends StatefulWidget {
  @override
  _EmployerSignUpPageState createState() => _EmployerSignUpPageState();
}

class _EmployerSignUpPageState extends State<EmployerSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
final _confirmPasswordController = TextEditingController();

  String? _heardAboutUs;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Employer Sign Up'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildRoundedTextField(
                      _schoolNameController,
                      'School/Academy Name',
                      'Enter full legal name',
                      Icons.school,
                      true,
                    ),
                    SizedBox(height: 16),
                    _buildRoundedTextField(
                      _contactNameController,
                      'Contact Person\'s Name',
                      'Enter full name of the representative',
                      Icons.person,
                      true,
                    ),
                    SizedBox(height: 16),
                    _buildDropdownField(),
                    SizedBox(height: 16),
                    _buildRoundedTextField(
                      _phoneController,
                      'Contact Phone Number',
                      'Enter contact number',
                      Icons.phone,
                      true,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildRoundedTextField(
                      _emailController,
                      'Email',
                      'Enter your email address',
                      Icons.email,
                      true,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildRoundedTextField(
                      _passwordController,
                      'Password',
                      'Enter a strong password',
                      Icons.lock,
                      true,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
_buildRoundedTextField(
  _confirmPasswordController,
  'Confirm Password',
  'Re-enter your password',
  Icons.lock,
  true,
  obscureText: true,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  },
),
SizedBox(height: 16,),
                    _buildRichTextField(
                      _companyDescriptionController,
                      'Company Description',
                      'Provide a brief overview of your institution',
                      Icons.description,
                      false,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text('Register Now'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRoundedTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    bool isMandatory, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: validator ??
          (value) {
            if (isMandatory && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _heardAboutUs,
      items: [
        'Podcast',
        'TV',
        'Mail',
        'Radio',
        'Word of mouth',
        'Search engine',
        'Streaming audio',
        'Billboard',
        'Newspaper',
        'Online video',
        'Social media',
      ]
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (value) => setState(() => _heardAboutUs = value),
      decoration: InputDecoration(
        labelText: 'How Did You Hear About Us?',
        prefixIcon: Icon(Icons.info),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildRichTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    bool isMandatory,
  ) {
    return TextFormField(
      controller: controller,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: (value) {
        if (isMandatory && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw FirebaseAuthException(code: 'user-null');

      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'userType': 'employer',
        'profileComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
        'schoolName': _schoolNameController.text.trim(),
        'contactName': _contactNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'heardAboutUs': _heardAboutUs,
        'companyDescription': _companyDescriptionController.text.trim(),
      });

      Navigator.pushReplacementNamed(context, '/email-verification');
    } catch (e) {
      _showErrorDialog('Registration failed. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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
  _passwordController.dispose();
  _confirmPasswordController.dispose(); // Dispose Confirm Password controller
  _companyDescriptionController.dispose();
  super.dispose();
}

}
