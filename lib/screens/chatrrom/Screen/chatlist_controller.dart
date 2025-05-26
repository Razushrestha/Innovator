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
  final RxString searchText = ''.obs; // Make search text reactive
  final Set<String> processedMessageIds = {};

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
    fetchChats();
    _initializeMQTT();
    
    // Set up reactive search listener
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

  Future<void> _initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await notificationsPlugin.initialize(initSettings);
    log('Notifications initialized');
  }

  Future<void> showNotification(String chatId, String senderName, String message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const platformDetails = NotificationDetails(android: androidDetails);
    await notificationsPlugin.show(
      chatId.hashCode,
      'New Message from $senderName',
      message,
      platformDetails,
      payload: chatId,
    );
    log('Notification shown for chatId: $chatId, sender: $senderName');
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

  Future<void> fetchChats() async {
    try {
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
          
          // Update observable lists properly
          chats.assignAll(rawChats);
          
          // Process chat IDs and unread counts
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
              final currentUnreadCount = unreadMessageCounts[chatId] ?? 0;
              unreadMessageCounts[chatId] = currentUnreadCount > apiUnreadCount ? currentUnreadCount : apiUnreadCount;
            }
          }
          
          // Apply current search filter
          _onSearchChanged();
          _subscribeToChatTopics();
        } else {
          throw Exception('Invalid chat list format');
        }
      } else {
        throw Exception('Failed to fetch chats: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching chats: $e');
      Get.snackbar('Error', 'Failed to fetch chats: $e');
    }
  }

  Future<void> _initializeMQTT() async {
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No auth token available for MQTT');
      
      await mqttService.connect(token, AppData().currentUserId ?? '');
      isMqttConnected.value = true;
      
      mqttService.subscribe('user/${AppData().currentUserId}/messages', (payload) {
        log('Received message on user topic: $payload');
      });

      mqttService.messageStream.listen(_handleMqttMessage, onError: (e) {
        log('Error in message stream: $e');
        isMqttConnected.value = false;
      });
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
          fetchChats().then((_) {
            chatIndex = chats.indexWhere((chat) {
              final user = chat['user'] as Map<String, dynamic>? ?? {};
              final userId = user['_id']?.toString() ?? '';
              return (senderId == AppData().currentUserId && userId == receiverId) ||
                  (receiverId == AppData().currentUserId && userId == senderId);
            });
            if (chatIndex != -1) {
              _updateChat(chatIndex, senderId, messageText, messageData, senderName);
            } else {
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
              if (!isRead) showNotification(tempChatId, senderName, messageText);
            }
          });
          return;
        }
        _updateChat(chatIndex, senderId, messageText, messageData, senderName);
      } else if (data['type'] == 'read_receipt') {
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
              }
            }
          }
        }
      }
    } catch (e) {
      log('Error processing MQTT message: $e');
    }
  }

  void _updateChat(int chatIndex, String senderId, String messageText, Map<String, dynamic> messageData, String senderName) {
    // Update the chat data directly in the observable list
    final updatedChat = Map<String, dynamic>.from(chats[chatIndex]);
    updatedChat['lastMessage'] = {
      'message': messageText,
      'timestamp': messageData['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    };
    
    final isRead = messageData['read'] == true;
    final chatId = updatedChat['_id']?.toString() ?? '';
    
    if (senderId != AppData().currentUserId && !isRead) {
      unreadMessageCounts[chatId] = (unreadMessageCounts[chatId] ?? 0) + 1;
      newMessageTimestamps[chatId] = DateTime.now().add(const Duration(seconds: 5));
      showNotification(chatId, senderName, messageText);
    }
    
    // Move chat to top if not already there
    if (chatIndex > 0) {
      chats.removeAt(chatIndex);
      chats.insert(0, updatedChat);
    } else {
      chats[0] = updatedChat;
    }
    
    // Update filtered chats
    _onSearchChanged();
  }

  void markChatAsRead(String chatId) {
    unreadMessageCounts[chatId] = 0;
    newMessageTimestamps.remove(chatId);
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

  String formatMessageTime(String timestamp) {
    try {
      final messageTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      if (now.difference(messageTime).inDays > 0) {
        return _getDayName(messageTime);
      } else {
        return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      log('Error parsing timestamp: $e');
      return '';
    }
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }
  }
}