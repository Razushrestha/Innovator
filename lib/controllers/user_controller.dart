import 'package:get/get.dart';
import 'package:innovator/App_data/App_data.dart';

class UserController extends GetxController {
  static UserController get to => Get.find();
  
  final Rx<String?> profilePicture = Rx<String?>(null);
  final Rx<String?> userName = Rx<String?>(null);
  
  @override
  void onInit() {
    super.onInit();
    // Initialize from AppData
    final user = AppData().currentUser;
    if (user != null) {
      profilePicture.value = user['picture'];
      userName.value = user['name'];
    }
  }
  
    RxInt profilePictureVersion = 0.obs; // Add this for cache busting
  
  void updateProfilePicture(String newPath) {
    profilePicture?.value = newPath;
    profilePictureVersion.value++; // Increment to force refresh
    update(); // Trigger GetX update
  }

  
  void updateUserName(String? newName) {
    userName.value = newName;
    // Also update in AppData
    if (AppData().currentUser != null) {
      AppData().updateCurrentUserField('name', newName);
    }
  }
  
  String? getFullProfilePicturePath() {
    return profilePicture.value != null 
        ? 'http://182.93.94.210:3064${profilePicture.value}'
        : null;
  }
} 