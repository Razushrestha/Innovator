import 'package:hive_flutter/hive_flutter.dart';
import 'package:innovator/screens/Feed/Services/Feed_cached.g.dart';
import 'package:innovator/screens/Feed/Inner_Homepage.dart';
import 'package:path_provider/path_provider.dart';

class CacheManager {
  static const String feedBoxName = 'feed_cache';
  static const int maxCachedItems = 20;

  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);
   if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FeedContentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AuthorAdapter());
    }
    await Hive.openBox<FeedContent>(feedBoxName);
  }

  static Future<void> cacheFeedContent(List<FeedContent> contents) async {
    final box = await Hive.openBox<FeedContent>(feedBoxName);
    
    // Keep only the most recent items within maxCachedItems limit
    if (box.length > maxCachedItems) {
      final itemsToRemove = box.length - maxCachedItems;
      for (int i = 0; i < itemsToRemove; i++) {
        await box.deleteAt(0);
      }
    }

    // Add new items
    for (var content in contents) {
      await box.add(content);
    }
  }

  static Future<List<FeedContent>> getCachedFeed() async {
    final box = await Hive.openBox<FeedContent>(feedBoxName);
    return box.values.toList();
  }

  static Future<void> clearCache() async {
    final box = await Hive.openBox<FeedContent>(feedBoxName);
    await box.clear();
  }
}