import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// handles fetching of the image path using image_picker
class UserPfpProvider extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  XFile? _imagePath;

  XFile? get imagePath => _imagePath;

  Future<void> fetchUserPfpFromGallery() async {
    final XFile? selectedImagePath =
        await _picker.pickImage(source: ImageSource.gallery);

    _imagePath = selectedImagePath;

    notifyListeners();
  }
}
