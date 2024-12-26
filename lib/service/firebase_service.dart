import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');

  /// Updates a user's data in Firestore.
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
       print('befoere update of user ');
      await _userCollection.doc(userId).update(data);
        print('No Error while updating hte user ');
    } catch (e) {
       print('Error while updating hte user ${e.toString()}');
      if (e is FirebaseException && e.code == 'not-found') {
        // If the document doesn't exist, create it
        await _userCollection.doc(userId).set(data);
      } else {
        print('Error while updating hte user ${e.toString()}');
        rethrow;
      }
    }
  }

  /// Fetches a user's data from Firestore.
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await _userCollection.doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  /// Updates a specific field in the user's document.
  Future<void> updateUserField(
      String userId, String fieldName, dynamic value) async {
    try {
      await _userCollection.doc(userId).update({fieldName: value});
    } catch (e) {
      throw Exception('Failed to update $fieldName: $e');
    }
  }

  /// Deletes a specific field from the user's document.
  Future<void> deleteUserField(String userId, String fieldName) async {
    try {
      await _userCollection.doc(userId).update({fieldName: FieldValue.delete()});
    } catch (e) {
      throw Exception('Failed to delete $fieldName: $e');
    }
  }

  /// Uploads a profile picture to Firebase Storage and returns its URL.
  Future<String> uploadProfilePicture(String userId, File file) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final profilePicRef =
          storageRef.child('profile_pictures/$userId/${file.path.split('/').last}');

      // Upload the file to Firebase Storage
      final uploadTask = profilePicRef.putFile(file);

      // Await the upload and get the download URL
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }
}
