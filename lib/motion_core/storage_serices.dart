import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motion/motion_reusable/reuseable.dart';
import 'package:path/path.dart' as path;


class StorageServices {
  static Future<String?> uploadUserPfpToFirebaseStorage(
      {required String userId, required XFile? userPfpPath}) async {
    // If no profile picture file is provided, return null immediately
    if (userPfpPath == null) {
      return null;
    }

    // firebase storage instance
    FirebaseStorage firebaseStorage = FirebaseStorage.instance;

    // extract file extension
    String fileExtension = path.extension(userPfpPath.path);

    // create a reference to the file
    Reference ref = firebaseStorage
        .ref()
        .child("user_profile_pictures")
        .child("$userId$fileExtension");

    try {
      // upload the file
      await ref.putFile(File(userPfpPath.path));

      // get the download URL
      String downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      logger.e("Error: $e");
      rethrow; // rethrowing the caught exception
    }
  }
}
