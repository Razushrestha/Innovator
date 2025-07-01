// Add these classes and methods to your AppData class

// Model classes for blocked users
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';

class BlockedUser {
  final String id;
  final String email;
  final String name;
  final String picture;
  final String blockReason;
  final String blockType;
  final DateTime blockedAt;
  final PreviousInteractions previousInteractions;

  const BlockedUser({
    required this.id,
    required this.email,
    required this.name,
    required this.picture,
    required this.blockReason,
    required this.blockType,
    required this.blockedAt,
    required this.previousInteractions,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? 'Unknown',
      picture: json['picture'] ?? '',
      blockReason: json['blockReason'] ?? '',
      blockType: json['blockType'] ?? 'full',
      blockedAt: DateTime.parse(json['blockedAt'] ?? DateTime.now().toIso8601String()),
      previousInteractions: PreviousInteractions.fromJson(
        json['previousInteractions'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'picture': picture,
      'blockReason': blockReason,
      'blockType': blockType,
      'blockedAt': blockedAt.toIso8601String(),
      'previousInteractions': previousInteractions.toJson(),
    };
  }

  // Helper method to get full picture URL
  String get fullPictureUrl {
    if (picture.isEmpty) return '';
    if (picture.startsWith('http')) return picture;
    return 'http://182.93.94.210:3066$picture';
  }
}

class PreviousInteractions {
  final bool followedEachOther;
  final bool hadConversations;
  final bool sharedContent;

  const PreviousInteractions({
    required this.followedEachOther,
    required this.hadConversations,
    required this.sharedContent,
  });

  factory PreviousInteractions.fromJson(Map<String, dynamic> json) {
    return PreviousInteractions(
      followedEachOther: json['followedEachOther'] ?? false,
      hadConversations: json['hadConversations'] ?? false,
      sharedContent: json['sharedContent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followedEachOther': followedEachOther,
      'hadConversations': hadConversations,
      'sharedContent': sharedContent,
    };
  }
}

class BlockedUsersPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasMore;

  const BlockedUsersPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasMore,
  });

  factory BlockedUsersPagination.fromJson(Map<String, dynamic> json) {
    return BlockedUsersPagination(
      page: json['page'] ?? 0,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'pages': pages,
      'hasMore': hasMore,
    };
  }
}

class BlockedUsersResponse {
  final int status;
  final List<BlockedUser> blockedUsers;
  final BlockedUsersPagination pagination;
  final String? error;
  final String message;

  const BlockedUsersResponse({
    required this.status,
    required this.blockedUsers,
    required this.pagination,
    this.error,
    required this.message,
  });

  factory BlockedUsersResponse.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['data'] as Map<String, dynamic>? ?? {};
      final blockedUsersList = data['blockedUsers'] as List<dynamic>? ?? [];
      
      return BlockedUsersResponse(
        status: json['status'] ?? 200,
        blockedUsers: blockedUsersList
            .map((user) => BlockedUser.fromJson(user as Map<String, dynamic>))
            .toList(),
        pagination: BlockedUsersPagination.fromJson(
          data['pagination'] ?? {},
        ),
        error: json['error'],
        message: json['message'] ?? '',
      );
    } catch (e) {
      developer.log('Error parsing BlockedUsersResponse: $e');
      return BlockedUsersResponse(
        status: json['status'] ?? 500,
        blockedUsers: [],
        pagination: BlockedUsersPagination.fromJson({}),
        error: 'Parsing error: $e',
        message: json['message'] ?? 'Failed to parse response',
      );
    }
  }
}

// Add these methods to your existing AppData class:

// Fetch blocked users with pagination
