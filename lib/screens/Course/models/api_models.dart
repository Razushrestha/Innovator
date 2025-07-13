// models/app_models.dart - REPLACE ALL YOUR OLD MODEL FILES WITH THIS

import 'package:flutter/material.dart';

// Theme Colors
// models/category_model.dart
class ParentCategory {
  final String id;
  final String name;
  final String description;
  final String slug;
  final String icon;
  final String color;
  final List<Subcategory> subcategories;
  final Metadata metadata;
  final Statistics statistics;
  final bool isActive;
  final int sortOrder;

  ParentCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.slug,
    required this.icon,
    required this.color,
    required this.subcategories,
    required this.metadata,
    required this.statistics,
    required this.isActive,
    required this.sortOrder,
  });

  factory ParentCategory.fromJson(Map<String, dynamic> json) {
    return ParentCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#FF5733',
      subcategories: (json['subcategories'] as List?)
          ?.map((sub) => Subcategory.fromJson(sub))
          .toList() ?? [],
      metadata: Metadata.fromJson(json['metadata'] ?? {}),
      statistics: Statistics.fromJson(json['statistics'] ?? {}),
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class Subcategory {
  final String id;
  final String name;
  final String description;
  final String slug;
  final String icon;
  final String color;
  final String parentCategory;
  final Metadata metadata;
  final Statistics? statistics;
  final bool isActive;

  Subcategory({
    required this.id,
    required this.name,
    required this.description,
    required this.slug,
    required this.icon,
    required this.color,
    required this.parentCategory,
    required this.metadata,
    this.statistics,
    required this.isActive,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#F7DF1E',
      parentCategory: json['parentCategory'] ?? '',
      metadata: Metadata.fromJson(json['metadata'] ?? {}),
      statistics: json['statistics'] != null ? Statistics.fromJson(json['statistics']) : null,
      isActive: json['isActive'] ?? true,
    );
  }
}

class Metadata {
  final int totalCourses;
  final int totalSubcategories;
  final int totalLessons;
  final int totalNotes;
  final int totalVideos;
  final int totalDuration;
  final String lastUpdated;

  Metadata({
    required this.totalCourses,
    required this.totalSubcategories,
    required this.totalLessons,
    required this.totalNotes,
    required this.totalVideos,
    required this.totalDuration,
    required this.lastUpdated,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      totalCourses: json['totalCourses'] ?? 0,
      totalSubcategories: json['totalSubcategories'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      totalNotes: json['totalNotes'] ?? 0,
      totalVideos: json['totalVideos'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }
}

class Statistics {
  final int? subcategories;
  final int courses;
  final int notes;
  final int videos;
  final int? lessons;

  Statistics({
    this.subcategories,
    required this.courses,
    required this.notes,
    required this.videos,
    this.lessons,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      subcategories: json['subcategories'],
      courses: json['courses'] ?? 0,
      notes: json['notes'] ?? 0,
      videos: json['videos'] ?? 0,
      lessons: json['lessons'],
    );
  }
}

// models/course_model.dart
class Course {
  final String id;
  final String title;
  final String description;
  final Price price;
  final String thumbnail;
  final List<Lesson> lessons;
  final List<Note> notes;
  final List<Video> videos;
  final CategoryInfo parentCategory;
  final CategoryInfo subcategory;
  final Instructor instructor;
  final Author author;
  final String level;
  final String language;
  final List<String> tags;
  final Rating rating;
  final Settings settings;
  final ContentStructure contentStructure;
  final String? overviewVideo;
  final bool isPublished;
  final int enrollmentCount;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.thumbnail,
    required this.lessons,
    required this.notes,
    required this.videos,
    required this.parentCategory,
    required this.subcategory,
    required this.instructor,
    required this.author,
    required this.level,
    required this.language,
    required this.tags,
    required this.rating,
    required this.settings,
    required this.contentStructure,
    this.overviewVideo,
    required this.isPublished,
    required this.enrollmentCount,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: Price.fromJson(json['price'] ?? {}),
      thumbnail: json['thumbnail'] ?? '',
      lessons: (json['lessons'] as List?)
          ?.map((lesson) => Lesson.fromJson(lesson))
          .toList() ?? [],
      notes: (json['notes'] as List?)
          ?.map((note) => Note.fromJson(note))
          .toList() ?? [],
      videos: (json['videos'] as List?)
          ?.map((video) => Video.fromJson(video))
          .toList() ?? [],
      parentCategory: CategoryInfo.fromJson(json['parentCategory'] ?? {}),
      subcategory: CategoryInfo.fromJson(json['subcategory'] ?? {}),
      instructor: Instructor.fromJson(json['instructor'] ?? {}),
      author: Author.fromJson(json['author'] ?? {}),
      level: json['level'] ?? '',
      language: json['language'] ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      rating: Rating.fromJson(json['rating'] ?? {}),
      settings: Settings.fromJson(json['settings'] ?? {}),
      contentStructure: ContentStructure.fromJson(json['contentStructure'] ?? {}),
      overviewVideo: json['overviewVideo'],
      isPublished: json['isPublished'] ?? false,
      enrollmentCount: json['enrollmentCount'] ?? 0,
    );
  }
}

class Price {
  final double usd;
  final double npr;

  Price({required this.usd, required this.npr});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      usd: (json['usd'] ?? 0).toDouble(),
      npr: (json['npr'] ?? 0).toDouble(),
    );
  }
}

class CategoryInfo {
  final String id;
  final String name;
  final String slug;

  CategoryInfo({required this.id, required this.name, required this.slug});

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class Instructor {
  final String name;
  final String bio;
  final List<String> credentials;

  Instructor({required this.name, required this.bio, required this.credentials});

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      credentials: (json['credentials'] as List?)?.cast<String>() ?? [],
    );
  }
}

class Author {
  final String id;
  final String email;
  final String phone;

  Author({required this.id, required this.email, required this.phone});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? 'Not provided',
    );
  }
}

class Rating {
  final double average;
  final int count;

  Rating({required this.average, required this.count});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      average: (json['average'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class Settings {
  final bool allowDownloads;
  final bool certificateEnabled;
  final bool discussionEnabled;

  Settings({
    required this.allowDownloads,
    required this.certificateEnabled,
    required this.discussionEnabled,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      allowDownloads: json['allowDownloads'] ?? false,
      certificateEnabled: json['certificateEnabled'] ?? true,
      discussionEnabled: json['discussionEnabled'] ?? true,
    );
  }
}

class ContentStructure {
  final int totalLessons;
  final int totalNotes;
  final int totalVideos;
  final int? generalNotes;
  final int? generalVideos;

  ContentStructure({
    required this.totalLessons,
    required this.totalNotes,
    required this.totalVideos,
    this.generalNotes,
    this.generalVideos,
  });

  factory ContentStructure.fromJson(Map<String, dynamic> json) {
    return ContentStructure(
      totalLessons: json['totalLessons'] ?? 0,
      totalNotes: json['totalNotes'] ?? 0,
      totalVideos: json['totalVideos'] ?? 0,
      generalNotes: json['generalNotes'],
      generalVideos: json['generalVideos'],
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final int sortOrder;
  final bool isPublished;
  final LessonMetadata metadata;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.isPublished,
    required this.metadata,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      isPublished: json['isPublished'] ?? false,
      metadata: LessonMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class LessonMetadata {
  final String difficulty;
  final List<String> prerequisites;

  LessonMetadata({required this.difficulty, required this.prerequisites});

  factory LessonMetadata.fromJson(Map<String, dynamic> json) {
    return LessonMetadata(
      difficulty: json['difficulty'] ?? '',
      prerequisites: (json['prerequisites'] as List?)?.cast<String>() ?? [],
    );
  }
}

class Note {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType;
  final String lessonId;
  final bool premium;
  final int sortOrder;
  final NoteMetadata metadata;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    required this.lessonId,
    required this.premium,
    required this.sortOrder,
    required this.metadata,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? '',
      lessonId: json['lessonId'] ?? '',
      premium: json['premium'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      metadata: NoteMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class NoteMetadata {
  final int downloadCount;

  NoteMetadata({required this.downloadCount});

  factory NoteMetadata.fromJson(Map<String, dynamic> json) {
    return NoteMetadata(
      downloadCount: json['downloadCount'] ?? 0,
    );
  }
}

class Video {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String duration;
  final String lessonId;
  final bool premium;
  final int sortOrder;
  final VideoMetadata metadata;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.duration,
    required this.lessonId,
    required this.premium,
    required this.sortOrder,
    required this.metadata,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      duration: json['duration'] ?? '00:00:00',
      lessonId: json['lessonId'] ?? '',
      premium: json['premium'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      metadata: VideoMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class VideoMetadata {
  final int viewCount;

  VideoMetadata({required this.viewCount});

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      viewCount: json['viewCount'] ?? 0,
    );
  }
}

// models/pagination.dart
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasMore;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasMore,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 0,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
      hasMore: json['hasMore'] ?? false,
    );
  }
}