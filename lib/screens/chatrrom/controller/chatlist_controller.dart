import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:innovator/screens/chatrrom/utils.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/chatrrom/Services/mqtt_services.dart';

class ChatListController extends GetxController {
  final MQTTService mqttService = MQTTService();
  final TextEditingController searchController = TextEditingController();
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  final RxList<Map<String, dynamic>> chats = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredChats = <Map<String, dynamic>>[].obs;
  final RxMap<String, int> unreadMessageCounts = <String, int>{}.obs;
  final RxMap<String, DateTime> newMessageTimestamps = <String, DateTime>{}.obs;
  final RxBool isMqttConnected = false.obs;
  final RxString searchText = ''.obs;
  final RxBool isLoading = false.obs;
  final Set<String> processedMessageIds = {};
  static ChatListController? _instance;
  
  static ChatListController get instance {
    _instance ??= Get.find<ChatListController>();
    return _instance!;
  }
  
  int get totalUnreadCount {
    return unreadMessageCounts.values.fold(0, (sum, count) => sum + count);
  }
  
  void resetAllUnreadCounts() {
    unreadMessageCounts.clear();
    newMessageTimestamps.clear();
  }
  
  @override
  void onInit() {
    super.onInit();
    fetchChats();
    initializeMQTT();
    
    searchController.addListener(() {
      searchText.value = searchController.text;
      _onSearchChanged();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    mqttService.disconnect();
    super.onClose();
  }

  
  void _onSearchChanged() {
    final query = searchText.value.toLowerCase();
    if (query.isEmpty) {
      filteredChats.assignAll(chats);
    } else {
      filteredChats.assignAll(chats.where((chat) {
        final user = chat['user'] as Map<String, dynamic>? ?? {};
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList());
    }
    log('Filtered chats updated: ${filteredChats.length} chats');
  }

  Future<void> fetchChats({bool showLoader = false}) async {
    try {
      if (showLoader) {
        isLoading.value = true;
      }
      
      final token = AppData().authToken;
      if (token == null) throw Exception('No auth token available');

      final response = await http.get(
        Uri.parse('${Utils.baseUrl}/api/v1/chats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      log('Chat API Response: ${response.statusCode}');
      if (response.statusCode == 200 && response.headers['content-type']?.contains('application/json') == true) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> && responseData['data'] is List) {
          final rawChats = List<Map<String, dynamic>>.from(responseData['data']);
          
          // Store current unread counts to preserve local updates
          Map<String, int> preservedUnreadCounts = Map.from(unreadMessageCounts);
          
          // Clear and update chats list
          chats.clear();
          chats.assignAll(rawChats);
          
          // Process chat IDs and merge unread counts
          for (var chat in chats) {
            String? chatId;
            final user = chat['user'] as Map<String, dynamic>? ?? {};
            if (chat.containsKey('_id') && chat['_id'] != null) {
              chatId = chat['_id'].toString();
            } else {
              final userId = user['_id']?.toString() ?? '';
              if (userId.isNotEmpty) {
                chatId = 'chat_${AppData().currentUserId}_$userId';
                chat['_id'] = chatId;
              }
            }
            
            if (chatId != null) {
              final apiUnreadCount = (chat['unreadCount'] as int?) ?? 0;
              final preservedCount = preservedUnreadCounts[chatId] ?? 0;
              // Use the higher value between API and preserved counts
              unreadMessageCounts[chatId] = preservedCount > apiUnreadCount ? preservedCount : apiUnreadCount;
            }
          }
          
          // Apply current search filter
          _onSearchChanged();
          _subscribeToChatTopics();
          
          // Force refresh all observables
          forceRefreshUI();
          
          log('Chats fetched successfully: ${chats.length} chats');
        } else {
          throw Exception('Invalid chat list format');
        }
      } else {
        throw Exception('Failed to fetch chats: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching chats: $e');
      Get.snackbar('Error', 'Failed to fetch chats: $e');
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }

  Future<void> initializeMQTT() async {
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No auth token available for MQTT');
      
      // Disconnect if already connected to ensure clean reconnection
      if (mqttService.isConnected()) {
        mqttService.disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      await mqttService.connect(token, AppData().currentUserId ?? '');
      isMqttConnected.value = mqttService.isConnected();
      
      mqttService.subscribe('user/${AppData().currentUserId}/messages', (payload) {
        log('Received message on user topic: $payload');
      });

      mqttService.messageStream.listen(_handleMqttMessage, onError: (e) {
        log('Error in message stream: $e');
        isMqttConnected.value = false;
      });
      _subscribeToChatTopics();
      log('MQTT initialized successfully');
    } catch (e) {
      log('Error initializing MQTT: $e');
      Get.snackbar('Error', 'Error connecting to MQTT: $e');
      isMqttConnected.value = false;
    }
  }

  void _subscribeToChatTopics() {
    if (!isMqttConnected.value) return;
    for (var chat in chats) {
      final user = chat['user'] as Map<String, dynamic>? ?? {};
      final receiverId = user['_id']?.toString() ?? '';
      if (receiverId.isNotEmpty) {
        final chatTopic = mqttService.getChatTopic(AppData().currentUserId ?? '', receiverId);
        mqttService.subscribe(chatTopic, (payload) {
          log('Received message on chat topic: $chatTopic, payload: $payload');
        });
      }
    }
  }

  void _handleMqttMessage(Map<String, dynamic> data) {
    try {
      if (data['type'] == 'new_message' && data['message'] != null) {
        final messageData = data['message'] as Map<String, dynamic>;
        final senderInfo = messageData['sender'] as Map<String, dynamic>? ?? {};
        final senderId = senderInfo['_id']?.toString() ?? '';
        final receiverId = (messageData['receiver'] as Map<String, dynamic>?)?['_id']?.toString() ?? '';
        final senderName = senderInfo['name']?.toString() ?? 'Unknown';
        final messageText = messageData['decryptedMessage']?.toString() ?? messageData['message']?.toString() ?? '';
        final messageId = messageData['id']?.toString() ?? '';
        final isRead = messageData['read'] == true;

        if (processedMessageIds.contains(messageId)) return;
        processedMessageIds.add(messageId);

        int chatIndex = chats.indexWhere((chat) {
          final user = chat['user'] as Map<String, dynamic>? ?? {};
          final userId = user['_id']?.toString() ?? '';
          return (senderId == AppData().currentUserId && userId == receiverId) ||
              (receiverId == AppData().currentUserId && userId == senderId);
        });

        if (chatIndex == -1) {
          // Create temporary chat and refresh from API
          _createTemporaryChat(senderId, receiverId, senderName, senderInfo, messageText, messageData, isRead);
          // Refresh after a short delay to get proper chat data
          Future.delayed(const Duration(milliseconds: 1000), () => fetchChats());
        } else {
          _updateExistingChat(chatIndex, senderId, messageText, messageData, senderName, isRead);
        }
      } else if (data['type'] == 'read_receipt') {
        _handleReadReceipt(data);
      }
    } catch (e) {
      log('Error processing MQTT message: $e');
    }
  }

  void _createTemporaryChat(String senderId, String receiverId, String senderName, 
      Map<String, dynamic> senderInfo, String messageText, Map<String, dynamic> messageData, bool isRead) {
    final tempChatId = 'temp_${senderId}_$receiverId';
    final tempChat = {
      '_id': tempChatId,
      'user': {
        '_id': senderId,
        'name': senderName,
        'email': senderInfo['email'] ?? '',
        'picture': senderInfo['picture'] ?? '',
      },
      'lastMessage': {
        'message': messageText,
        'timestamp': messageData['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      },
      'unreadCount': isRead ? 0 : 1,
    };
    
    chats.insert(0, tempChat);
    unreadMessageCounts[tempChatId] = isRead ? 0 : 1;
    newMessageTimestamps[tempChatId] = DateTime.now().add(const Duration(seconds: 5));
    _onSearchChanged(); // Update filtered chats
    forceRefreshUI();
    
    // if (!isRead && senderId != AppData().currentUserId) {
    //   showNotification(tempChatId, senderName, messageText);
    // }
  }

  void _updateExistingChat(int chatIndex, String senderId, String messageText, 
      Map<String, dynamic> messageData, String senderName, bool isRead) {
    // Create updated chat data
    final updatedChat = Map<String, dynamic>.from(chats[chatIndex]);
    updatedChat['lastMessage'] = {
      'message': messageText,
      'timestamp': messageData['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    };
    
    final chatId = updatedChat['_id']?.toString() ?? '';
    
    // Update unread count only for incoming messages
    if (senderId != AppData().currentUserId && !isRead) {
      unreadMessageCounts[chatId] = (unreadMessageCounts[chatId] ?? 0) + 1;
      newMessageTimestamps[chatId] = DateTime.now().add(const Duration(seconds: 5));
    }
    
    // Move chat to top and update
    chats.removeAt(chatIndex);
    chats.insert(0, updatedChat);
    
    // Force UI update
    _onSearchChanged();
    forceRefreshUI();
  }

  void _handleReadReceipt(Map<String, dynamic> data) {
    final messageId = data['messageId']?.toString();
    final chatTopic = data['chatTopic']?.toString();
    if (messageId != null && chatTopic != null) {
      for (var chat in chats) {
        final user = chat['user'] as Map<String, dynamic>? ?? {};
        final userId = user['_id']?.toString() ?? '';
        final expectedTopic = mqttService.getChatTopic(AppData().currentUserId ?? '', userId);
        if (expectedTopic == chatTopic) {
          final chatId = chat['_id']?.toString();
          if (chatId != null && unreadMessageCounts[chatId] != null && unreadMessageCounts[chatId]! > 0) {
            unreadMessageCounts[chatId] = unreadMessageCounts[chatId]! - 1;
            forceRefreshUI();
          }
        }
      }
    }
  }

  void markChatAsRead(String chatId) {
    unreadMessageCounts[chatId] = 0;
    newMessageTimestamps.remove(chatId);
    forceRefreshUI();
  }

  bool isRecentMessage(String chatId) {
    final timestamp = newMessageTimestamps[chatId];
    if (timestamp == null) return false;
    final now = DateTime.now();
    if (now.isAfter(timestamp)) {
      newMessageTimestamps.remove(chatId);
      return false;
    }
    return true;
  }

  // Enhanced method to force refresh UI
  void forceRefreshUI() {
    try {
      // Force update all reactive variables
      chats.refresh();
      filteredChats.refresh();
      unreadMessageCounts.refresh();
      newMessageTimestamps.refresh();
      isMqttConnected.refresh();
      searchText.refresh();
      isLoading.refresh();
      
      // Trigger a complete rebuild of dependent widgets
      update();
      
      log('UI force refreshed - Chats: ${chats.length}, Filtered: ${filteredChats.length}, Unread: ${unreadMessageCounts.length}');
    } catch (e) {
      log('Error in forceRefreshUI: $e');
    }
  }

  // Utility method to format message timestamps
  String formatMessageTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    
    try {
      final messageTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(messageTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        // Format as date for older messages
        return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
      }
    } catch (e) {
      log('Error formatting message time: $e');
      return '';
    }
  }

  // Method to handle connection status changes
  void onConnectionStatusChanged(bool isConnected) {
    isMqttConnected.value = isConnected;
    if (!isConnected) {
      // Attempt to reconnect after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (!isMqttConnected.value) {
          initializeMQTT();
        }
      });
    }
    log('MQTT connection status changed: $isConnected');
  }

  // Method to clear all processed message IDs (useful for cleanup)
  void clearProcessedMessages() {
    processedMessageIds.clear();
    log('Cleared processed message IDs');
  }

  // Method to get chat by ID
  Map<String, dynamic>? getChatById(String chatId) {
    try {
      return chats.firstWhere((chat) => chat['_id']?.toString() == chatId);
    } catch (e) {
      return null;
    }
  }

  // Method to remove a chat (if needed)
  void removeChat(String chatId) {
    chats.removeWhere((chat) => chat['_id']?.toString() == chatId);
    unreadMessageCounts.remove(chatId);
    newMessageTimestamps.remove(chatId);
    _onSearchChanged();
    forceRefreshUI();
    log('Chat removed: $chatId');
  }
}