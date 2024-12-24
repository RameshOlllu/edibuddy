import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ResumeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> fetchResumeUrl(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['resumeUrl'] as String?;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteResume(String fileUrl, String userId) async {
    try {
      // Delete from storage
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();

      // Delete from Firestore
      await _firestore.collection('users').doc(userId).update({
        'resumeUrl': FieldValue.delete(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadResume(String userId, String filePath, String fileName) async {
    try {
      final ref = _storage.ref('resumes/$fileName');
      final uploadTask = ref.putFile(
        File(filePath),
        SettableMetadata(contentType: 'application/pdf'),
      );

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateResumeUrl(String userId, String fileUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'resumeUrl': fileUrl,
        'badges.resume': {
          'earned': true,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

   Future<void> updateUserProfileStatus(String userId, bool status) async {
    try {
      // Update the user's profileComplete status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'profileComplete': status});
    } catch (e) {
      throw Exception("Failed to update profile status");
    }
  }
}
