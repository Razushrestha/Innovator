// controllers/chat_controller.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/chatrrom/Model/chatMessage.dart';
import 'package:innovator/screens/chatrrom/Services/mqtt_services.dart';
import 'package:innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatController extends GetxController {
  final MQTTService _mqttService = MQTTService();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  final String currentUserId;
  final String currentUserName;
  final String currentUserPicture;
  final String currentUserEmail;
  final String receiverId;
  final String receiverName;
  final String receiverPicture;
  final String receiverEmail;

  RxBool isLoading = true.obs;
  RxString errorMessage = ''.obs;
  RxBool isSendingMessage = false.obs;
  String? chatTopic;

  ChatController({
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserPicture,
    required this.currentUserEmail,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPicture,
    required this.receiverEmail,
  });

  @override
  void onInit() {
    super.onInit();
    log('ChatController: Initializing with currentUserId=$currentUserId, receiverId=$receiverId');
    fetchMessages();
    validateAndSetupMQTT();
  }

  Future<void> fetchMessages() async {
    try {
      isLoading(true);
      errorMessage('');

      final token = AppData().authToken;
      if (token == null) {
        log('ChatController: No auth token, redirecting to login');
        Get.offAll(() => const LoginPage());
        throw Exception('No auth token available');
      }

      const String baseUrl = 'http://182.93.94.210:3064/api/v1';
      final url = '$baseUrl/messages/$receiverId';
      log('ChatController: Fetching messages from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      log('ChatController: Messages API response status: ${response.statusCode}');
      if (response.statusCode == 401) {
        log('ChatController: Unauthorized, redirecting to login');
        Get.offAll(() => const LoginPage());
        throw Exception('Session expired. Please log in again.');
      }

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          log('ChatController: Empty response body');
          isLoading(false);
          return;
        }

        final responseData = jsonDecode(response.body);
        log('ChatController: Decoded response data: $responseData');

        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final messagesList = responseData['data'];
          if (messagesList is List) {
            messages.clear();
            for (var item in messagesList) {
              try {
                final message = ChatMessage.fromJson(item);
                if ((message.senderId == currentUserId && message.receiverId == receiverId) ||
                    (message.senderId == receiverId && message.receiverId == currentUserId)) {
                  messages.add(message);
                }
              } catch (e) {
                log('ChatController: Error processing message item: $e');
              }
            }
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            isLoading(false);
          }
          await cacheMessages();
          scrollToBottom();
          // Mark unread messages as read if screen is active
          for (var message in messages) {
            if (message.senderId == receiverId && !message.read) {
              await markMessageAsRead(message.id);
            }
          }
        }
      }
    } catch (e) {
      log('ChatController: Error fetching messages: $e');
      errorMessage('Failed to load messages. Showing cached messages.');
      isLoading(false);
    }
  }

  Future<void> validateAndSetupMQTT() async {
    try {
      if (currentUserId.isEmpty) {
        developer.log('ChatController: Cannot setup MQTT: currentUserId is empty');
        Get.snackbar('Error', 'Invalid user ID. Please log in again.');
        Get.offAll(() => const LoginPage());
        return;
      }

      final token = AppData().authToken;
      if (token == null) {
        developer.log('ChatController: Cannot setup MQTT: No auth token available');
        Get.snackbar('Error', 'No auth token. Please log in again.');
        Get.offAll(() => const LoginPage());
        return;
      }

      await _mqttService.connect(token, currentUserId);
      chatTopic = _mqttService.getChatTopic(currentUserId, receiverId);
      developer.log('ChatController: Initialized chat topic: $chatTopic');

      // Subscribe to chat topic for real-time messages
      _mqttService.subscribe(chatTopic!, (String payload) async {
        try {
          developer.log('ChatController: Received MQTT message on chat topic: $payload');
          final message = ChatMessage.fromJson(jsonDecode(payload));
          if ((message.senderId == currentUserId && message.receiverId == receiverId) ||
              (message.senderId == receiverId && message.receiverId == currentUserId)) {
            bool isDuplicate = messages.any((m) => m.id == message.id);
            if (!isDuplicate) {
              final tempIndex = messages.indexWhere((m) =>
                  m.id.startsWith('temp_') &&
                  m.senderId == message.senderId &&
                  m.content == message.content &&
                  m.timestamp.difference(message.timestamp).inSeconds.abs() < 5);
              if (tempIndex != -1) {
                messages[tempIndex] = message;
              } else {
                messages.add(message);
              }
              await cacheMessages();
              scrollToBottom();
              if (message.senderId == receiverId && !message.read) {
                await markMessageAsRead(message.id);
              }
            }
          }
        } catch (e) {
          developer.log('ChatController: Error processing MQTT message: $e');
        }
      });

      // Subscribe to user-specific messages topic
      _mqttService.subscribe('user/$currentUserId/messages', (String payload) async {
        try {
          final data = jsonDecode(payload);
          if (data['type'] == 'new_message') {
            final message = ChatMessage.fromJson(data['message']);
            if ((message.senderId == currentUserId && message.receiverId == receiverId) ||
                (message.senderId == receiverId && message.receiverId == currentUserId)) {
              bool isDuplicate = messages.any((m) => m.id == message.id);
              if (!isDuplicate) {
                final tempIndex = messages.indexWhere((m) =>
                    m.id.startsWith('temp_') &&
                    m.senderId == message.senderId &&
                    m.content == message.content &&
                    m.timestamp.difference(message.timestamp).inSeconds.abs() < 5);
                if (tempIndex != -1) {
                  messages[tempIndex] = message;
                } else {
                  messages.add(message);
                }
                await cacheMessages();
                scrollToBottom();
                if (message.senderId == receiverId && !message.read) {
                  await markMessageAsRead(message.id);
                }
              }
            }
          } else if (data['type'] == 'read_receipt') {
            final messageId = data['messageId'] as String?;
            if (messageId != null) {
              final messageIndex = messages.indexWhere((m) => m.id == messageId);
              if (messageIndex != -1) {
                final message = messages[messageIndex];
                message.read = true;
                message.readAt = DateTime.parse(data['readAt'] ?? DateTime.now().toIso8601String());
                messages.refresh();
                await cacheMessages();
              }
            }
          } else if (data['type'] == 'message_deleted') {
            final messageId = data['messageId'] as String?;
            if (messageId != null) {
              messages.removeWhere((m) => m.id == messageId);
              await cacheMessages();
            }
          }
        } catch (e) {
          developer.log('ChatController: Error processing user messages: $e');
        }
      });
    } catch (e) {
      developer.log('ChatController: Error setting up MQTT: $e');
      errorMessage('Failed to connect to chat service. Please try again.');
    }
  }

  Future<void> sendMessage() async {
    if (isSendingMessage.value || messageController.text.trim().isEmpty || chatTopic == null) {
      return;
    }

    isSendingMessage(true);
    try {
      final messageContent = messageController.text.trim();
      messageController.clear();

      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_$currentUserId';
      final message = ChatMessage(
        id: tempId,
        senderId: currentUserId,
        senderName: currentUserName,
        senderPicture: currentUserPicture,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverPicture: receiverPicture,
        receiverEmail: receiverEmail,
        content: messageContent,
        timestamp: DateTime.now(),
        read: false,
        readAt: null,
      );

      messages.add(message);
      await cacheMessages();
      scrollToBottom();

      // Use the old payload structure
      final payload = {
        'sender': {
          '_id': currentUserId,
          'email': currentUserEmail,
          'name': currentUserName.isNotEmpty ? currentUserName : 'Unknown',
          'picture': currentUserPicture,
        },
        'receiver': {
          '_id': receiverId,
          'email': receiverEmail,
          'name': receiverName.isNotEmpty ? receiverName : 'Unknown',
          'picture': receiverPicture,
        },
        'message': messageContent,
        'timestamp': message.timestamp.toIso8601String(),
      };

      await _mqttService.publish(chatTopic!, payload);
      SoundPlayer().playSound();
    } catch (e) {
      log('ChatController: Error sending message: $e');
      Get.snackbar('Error', 'Failed to send message. Please try again.');
      messages.removeWhere((m) => m.id.startsWith('temp_'));
      await cacheMessages();
    } finally {
      isSendingMessage(false);
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) return;

      final url = 'http://182.93.94.210:3064/api/v1/message/$messageId/read';
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'readAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final messageIndex = messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          final message = messages[messageIndex];
          message.read = true;
          message.readAt = DateTime.now();
          messages.refresh();
          await cacheMessages();
          await _mqttService.publish('user/$receiverId/messages', {
            'type': 'read_receipt',
            'messageId': messageId,
            'chatTopic': chatTopic,
            'readAt': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      log('ChatController: Error marking message as read: $e');
    }
  }

  /// Delete a message for the current user only (local deletion)
  Future<bool> deleteMessageForMe(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        log('ChatController: No auth token available for deleteMessageForMe');
        return false;
      }

      const String baseUrl = 'http://182.93.94.210:3064/api/v1';
      final url = '$baseUrl/message/$messageId/me';
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      log('ChatController: Delete message for me response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove message from local list
        messages.removeWhere((message) => message.id == messageId);
        await cacheMessages();
        return true;
      } else {
        log('ChatController: Failed to delete message for me: ${response.body}');
        return false;
      }
    } catch (e) {
      log('ChatController: Error deleting message for me: $e');
      return false;
    }
  }

  /// Delete a message for everyone (server-side deletion)
  Future<bool> deleteMessageForEveryone(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        log('ChatController: No auth token available for deleteMessageForEveryone');
        return false;
      }

      const String baseUrl = 'http://182.93.94.210:3064/api/v1';
      final url = '$baseUrl/message/$messageId/everyone';
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      log('ChatController: Delete message for everyone response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove message from local list
        messages.removeWhere((message) => message.id == messageId);
        await cacheMessages();

        // Notify the other user via MQTT
        if (chatTopic != null) {
          await _mqttService.publish('user/$receiverId/messages', {
            'type': 'message_deleted',
            'messageId': messageId,
            'chatTopic': chatTopic,
            'deletedBy': currentUserId,
            'deletedAt': DateTime.now().toIso8601String(),
          });
        }

        return true;
      } else {
        log('ChatController: Failed to delete message for everyone: ${response.body}');
        return false;
      }
    } catch (e) {
      log('ChatController: Error deleting message for everyone: $e');
      return false;
    }
  }

  /// Delete the entire conversation
  Future<bool> deleteConversation() async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        log('ChatController: No auth token available for deleteConversation');
        return false;
      }

      const String baseUrl = 'http://182.93.94.210:3064/api/v1';
      final url = '$baseUrl/conversation/${currentUserId}?otherUserId=${receiverId}';
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      log('ChatController: Delete conversation response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Clear all messages
        messages.clear();
        await cacheMessages();

        // Clear cached messages from SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          final cacheKey = 'messages_${currentUserId}_$receiverId';
          await prefs.remove(cacheKey);
        } catch (e) {
          log('ChatController: Error clearing cached messages: $e');
        }

        return true;
      } else {
        log('ChatController: Failed to delete conversation: ${response.body}');
        return false;
      }
    } catch (e) {
      log('ChatController: Error deleting conversation: $e');
      return false;
    }
  }

  Future<void> cacheMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${currentUserId}_$receiverId';
      final jsonMessages = messages.map((m) => m.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonMessages));
    } catch (e) {
      log('ChatController: Error caching messages: $e');
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    _mqttService.disconnect();
    super.onClose();
  }
}