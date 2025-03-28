import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'applicant_details_page.dart';

class ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final VoidCallback? onStatusChanged;
  final String jobId;
  const ApplicantCard({Key? key, required this.application, this.onStatusChanged, required this.jobId})
      : super(key: key);

  Future<DocumentSnapshot> _fetchUserData() async {
    final employeeId = application['employeeId'];
    return await FirebaseFirestore.instance.collection('users').doc(employeeId).get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircleAvatar(child: CircularProgressIndicator()),
            title: Text('Loading...'),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const ListTile(
            leading: CircleAvatar(child: Icon(Icons.error)),
            title: Text('User data not found'),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final fullName = userData['basicDetails']?['fullName'] ?? 'Unknown';
        final photoUrl = userData['photoURL'] ?? '';
        final stars = userData['stars'] ?? 0;
        final hearts = userData['hearts'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: photoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
              child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text(fullName),
            // Instead of showing the employee ID, show stars and hearts
            subtitle: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('$stars'),
                const SizedBox(width: 8),
                Icon(Icons.favorite, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text('$hearts'),
              ],
            ),
            trailing: Chip(
              label: Text(application['status'] ?? 'No Status'),
              backgroundColor: Colors.blue.shade100,
            ),
            onTap: () {
              // Navigate to the detailed applicant page.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApplicantDetailsPage(
                    userData: userData,
                    application: application,
                    jobId: jobId,
                  ),
                ),
              ).then((result) {
                // If the status was updated, trigger the callback to refresh data.
                if (result == true && onStatusChanged != null) {
                  onStatusChanged!();
                }
              });
            },
          ),
        );
      },
    );
  }
}
