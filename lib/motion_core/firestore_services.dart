import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motion/motion_reusable/reuseable.dart';

class FirestoreServices {
  // get the username of the current user
  static Future<String> getCurrentUserName(String userId) async {
    try {
      // reference of the current user document
      DocumentReference docRef =
          FirebaseFirestore.instance.collection("users").doc(userId);

      // fetch document from firestore
      DocumentSnapshot documentSnapshot = await docRef.get();

      // checking id the document exist
      if (documentSnapshot.exists) {
        // casting the fetched data as a Map for easy access
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;

        return data["user name"] ?? "username does not exist";
      } else {
        logger.i("The document you are looking for does not exist");
        return "No document";
      }
    } catch (e) {
      logger.e("The Following error occured");
      return "Error: ${e.toString()}";
    }
  }

  // get the user profile image URL
  static Future<String?> getUserProfile(String userId) async {
    try {
      DocumentReference documentReference =
          FirebaseFirestore.instance.collection("users").doc(userId);

      DocumentSnapshot docSnapshot = await documentReference.get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        return data["pfpPath"];
      } else {
        logger.i("The document you are looking for does not exist");
        return null;
      }
    } catch (e) {
      logger.e("The Following error occured: $e");
      return null;
    }
  }
}
