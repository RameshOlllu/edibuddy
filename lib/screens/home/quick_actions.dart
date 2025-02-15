import 'package:edibuddy/screens/applyjob/applied_jobs_page.dart';
import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import '../quickactions/change_password_page.dart';

class QuickActionsTab extends StatelessWidget {
  const QuickActionsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Account Options
            Text(
              'Account Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            _buildAccountOption(
              context,
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () async {
                final user = authService.currentUser;
                if (user == null) {
                  // User not logged in, show error dialog
                  _showErrorDialog(context, "User is not logged in.");
                  return;
                }

                try {
                  // Fetch sign-in methods for the user's email
                  final signInMethods =
                      await authService.fetchSignInMethodsForEmail(user.email!);

                  // Navigate to the ChangePasswordPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordPage(
                        isGoogleSignIn: signInMethods.contains('google.com') &&
                            signInMethods.length == 1,
                        authService: authService,
                      ),
                    ),
                  );
                } catch (e) {
                  // Handle any errors during fetching sign-in methods
                  _showErrorDialog(context,
                      "Failed to fetch account details. Please try again.");
                }
              },
            ),

            _buildAccountOption(
              context,
              icon: Icons.file_copy,
              title: 'My Documents',
              onTap: () {
                // Navigate to My Documents Screen
              },
            ),
            _buildAccountOption(
              context,
              icon: Icons.bookmark,
              title: 'Saved Jobs',
              onTap: () {
                // Navigate to Saved Jobs Screen
              },
            ),
            _buildAccountOption(
              context,
              icon: Icons.work,
              title: 'Applied Jobs',
              onTap: () {
                Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AppliedJobsPage(
      ),
    ),
  );
              },
            ),
            _buildAccountOption(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => authService.logout(context),
              isDestructive: true,
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            _buildQuickAction(
              context,
              icon: Icons.upload_file,
              title: 'Update Resume',
              subtitle: 'Keep your resume updated to increase visibility.',
              onTap: () {
                // Navigate to Resume Upload Screen
              },
            ),
            _buildQuickAction(
              context,
              icon: Icons.assessment,
              title: 'Skill Tests',
              subtitle: 'Take skill tests to enhance your profile.',
              onTap: () {
                // Navigate to Skill Tests Screen
              },
            ),
            _buildQuickAction(
              context,
              icon: Icons.lightbulb,
              title: 'Career Advice',
              subtitle: 'Get personalized career tips and advice.',
              onTap: () {
                // Navigate to Career Advice Screen
              },
            ),
          ],
        ),
      ),
    );
  }




void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Error"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

  Widget _buildAccountOption(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? colorScheme.error : colorScheme.primary,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDestructive ? colorScheme.error : null,
                fontWeight: isDestructive ? FontWeight.bold : null,
              ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        onTap: onTap,
      ),
    );
  }
}
