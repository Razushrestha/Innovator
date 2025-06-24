import 'package:get/get.dart';

class UserController extends GetxController {
  var profilePicture = RxString('');
  var userName = RxString('');

  String? getFullProfilePicturePath() {
    return profilePicture.value.isNotEmpty 
      ? 'http://182.93.94.210:3066${profilePicture.value}'
      : null;
  }

  void updateProfilePicture(String newPicturePath) {
    profilePicture.value = newPicturePath;
    update(); // Notify listeners
  }

  void updateUserName(String newName) {
    userName.value = newName;
    update(); // Notify listeners
  }
}