import 'package:hive_flutter/hive_flutter.dart';
import 'package:innovator/screens/Profile/UserProfileAdapter.dart';
import 'package:innovator/screens/Profile/profile_page.dart';
import 'package:path_provider/path_provider.dart';

class ProfileCacheManager {
  static const String profileBoxName = 'user_profile_cache';
  static const String followersBoxName = 'followers_cache';
  static const String followingBoxName = 'following_cache';

  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    
    await Hive.openBox<UserProfile>(profileBoxName);
    await Hive.openBox<List<dynamic>>(followersBoxName);
    await Hive.openBox<List<dynamic>>(followingBoxName);
  }

  static Future<void> cacheUserProfile(UserProfile profile) async {
    final box = await Hive.openBox<UserProfile>(profileBoxName);
    await box.put('current_profile', profile);
  }

  static Future<UserProfile?> getCachedProfile() async {
    final box = await Hive.openBox<UserProfile>(profileBoxName);
    return box.get('current_profile');
  }

  static Future<void> cacheFollowers(List<FollowerFollowing> followers) async {
    final box = await Hive.openBox<List<dynamic>>(followersBoxName);
    final followerMaps = followers.map((f) => {
      'id': f.id,
      'name': f.name,
      'email': f.email,
      'picture': f.picture,
    }).toList();
    await box.put('followers', followerMaps);
  }

  static Future<List<FollowerFollowing>> getCachedFollowers() async {
    final box = await Hive.openBox<List<dynamic>>(followersBoxName);
    final followerMaps = box.get('followers', defaultValue: []);
    return followerMaps!.map((map) => FollowerFollowing(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      picture: map['picture'],
    )).toList();
  }

  static Future<void> cacheFollowing(List<FollowerFollowing> following) async {
    final box = await Hive.openBox<List<dynamic>>(followingBoxName);
    final followingMaps = following.map((f) => {
      'id': f.id,
      'name': f.name,
      'email': f.email,
      'picture': f.picture,
    }).toList();
    await box.put('following', followingMaps);
  }

  static Future<List<FollowerFollowing>> getCachedFollowing() async {
    final box = await Hive.openBox<List<dynamic>>(followingBoxName);
    final followingMaps = box.get('following', defaultValue: []);
    return followingMaps!.map((map) => FollowerFollowing(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      picture: map['picture'],
    )).toList();
  }

  static Future<void> clearCache() async {
    final profileBox = await Hive.openBox<UserProfile>(profileBoxName);
    final followersBox = await Hive.openBox<List<dynamic>>(followersBoxName);
    final followingBox = await Hive.openBox<List<dynamic>>(followingBoxName);
    
    await profileBox.clear();
    await followersBox.clear();
    await followingBox.clear();
  }
}