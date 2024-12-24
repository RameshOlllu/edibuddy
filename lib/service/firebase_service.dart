import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');

  /// Updates a user's data in Firestore.
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _userCollection.doc(userId).update(data);
    } catch (e) {
      if (e is FirebaseException && e.code == 'not-found') {
        // If the document doesn't exist, create it
        await _userCollection.doc(userId).set(data);
      } else {
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
}
