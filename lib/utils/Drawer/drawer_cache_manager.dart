import 'package:hive_flutter/hive_flutter.dart';
import 'package:innovator/utils/Drawer/Drawer_Hivetype.dart';

class DrawerProfileCache {
  static const String boxName = 'drawer_profile_cache';
  static Box<DrawerProfile>? _box;

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(DrawerProfileAdapter());
      }
      _box = await Hive.openBox<DrawerProfile>(boxName);
    } catch (e) {
      print('Error initializing Hive: $e');
    }
  }

  static Future<Box<DrawerProfile>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      await initialize();
    }
    return _box!;
  }

  static Future<void> cacheProfile({
    required String name,
    required String email,
    String? picturePath,
  }) async {
    try {
      final box = await _getBox();
      final profile = DrawerProfile(
        name: name,
        email: email,
        picturePath: picturePath,
      );
      await box.put('current_profile', profile);
    } catch (e) {
      print('Error caching profile: $e');
    }
  }

  static Future<DrawerProfile?> getCachedProfile() async {
    try {
      final box = await _getBox();
      return box.get('current_profile');
    } catch (e) {
      print('Error getting cached profile: $e');
      return null;
    }
  }

  static Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}