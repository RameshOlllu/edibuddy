import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/job_card_for_recent_jobs.dart';

class RecentlyViewedJobsPage extends StatelessWidget {
  const RecentlyViewedJobsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Recently Viewed Jobs")),
      body: userId == null
          ? Center(child: Text("Please log in to view recently viewed jobs."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('recentlyViewedJobs')
                  .orderBy('viewedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No recently viewed jobs."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final jobData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return JobCard(jobData: jobData);
                  },
                );
              },
            ),
    );
  }
}
