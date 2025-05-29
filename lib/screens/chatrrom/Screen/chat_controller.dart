import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/chatrrom/Model/chatMessage.dart';
import 'package:innovator/screens/chatrrom/Services/mqtt_services.dart';
import 'package:innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatController extends GetxController {
  // Observable variables
  final messages = <ChatMessage>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final isSendingMessage = false.obs;
  final mqttInitialized = false.obs;
  final isInitialized = false.obs; // Add this to track initialization
  
  // Controllers
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  // Services
  final MQTTService _mqttService = MQTTService();
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  
  // Chat properties
  String? chatTopic;
  String currentUserId = '';
  String currentUserName = '';
  String currentUserPicture = '';
  String currentUserEmail = '';
  String receiverId = '';
  String receiverName = '';
  String receiverPicture = '';
  String receiverEmail = '';

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  // Initialize chat with user data
  void initializeChat({
    required String currentUserId,
    required String currentUserName,
    required String currentUserPicture,
    required String currentUserEmail,
    required String receiverId,
    required String receiverName,
    required String receiverPicture,
    required String receiverEmail,
  }) {
    // Prevent multiple initializations
    if (isInitialized.value) {
      log('ChatController: Already initialized, skipping');
      return;
    }

    this.currentUserId = currentUserId;
    this.currentUserName = currentUserName;
    this.currentUserPicture = currentUserPicture;
    this.currentUserEmail = currentUserEmail;
    this.receiverId = receiverId;
    this.receiverName = receiverName;
    this.receiverPicture = receiverPicture;
    this.receiverEmail = receiverEmail;
    
    log('ChatController: Initializing chat with currentUserId=$currentUserId, receiverId=$receiverId');
    
    // Mark as initialized immediately to prevent re-initialization
    isInitialized.value = true;
    
    // Load cached messages first for better UX
    _loadCachedMessages().then((_) {
      // Then fetch fresh messages
      fetchMessages();
      validateAndSetupMQTT();
    });
  }

  // Load cached messages
  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${currentUserId}_$receiverId';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> jsonMessages = jsonDecode(cachedData);
        final List<ChatMessage> cachedMessages = jsonMessages
            .map((json) => ChatMessage.fromJson(json))
            .where((msg) => _isValidMessage(msg))
            .toList();
        
        if (cachedMessages.isNotEmpty) {
          messages.assignAll(cachedMessages);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          isLoading.value = false;
          
          // Schedule scroll to bottom after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom();
          });
          
          log('ChatController: Loaded ${cachedMessages.length} cached messages');
        }
      }
    } catch (e) {
      log('ChatController: Error loading cached messages: $e');
    }
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Show system notification
  Future<void> _showSystemNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 10000,
      title,
      body,
      notificationDetails,
    );
  }

  // Setup MQTT connection and subscriptions
  Future<void> validateAndSetupMQTT() async {
    if (mqttInitialized.value) {
      log('ChatController: MQTT already initialized, skipping setup');
      return;
    }

    try {
      if (currentUserId.isEmpty) {
        log('ChatController: Cannot setup MQTT: currentUserId is empty');
        Get.snackbar('Error', 'Invalid user ID. Please log in again.');
        Get.offAll(() => const LoginPage());
        return;
      }

      final token = AppData().authToken;
      if (token == null) {
        log('ChatController: Cannot setup MQTT: No auth token available');
        Get.snackbar('Error', 'No auth token. Please log in again.');
        Get.offAll(() => const LoginPage());
        return;
      }

      await _mqttService.connect(token, currentUserId);
      chatTopic = _mqttService.getChatTopic(currentUserId, receiverId);
      log('ChatController: Initialized chat topic: $chatTopic');

      // Subscribe to chat topic for real-time messages
      _mqttService.subscribe(chatTopic!, (String payload) async {
        await _handleChatMessage(payload);
      });

      // Subscribe to user-specific messages topic
      _mqttService.subscribe('user/$currentUserId/messages', (String payload) async {
        await _handleUserMessage(payload);
      });

      // Subscribe to notifications
      _mqttService.subscribe('user/$currentUserId/notifications', (String payload) {
        _handleNotification(payload);
      });

      mqttInitialized.value = true;
      log('ChatController: MQTT setup completed');
    } catch (e) {
      log('ChatController: Error setting up MQTT: $e');
      errorMessage.value = 'Failed to connect to chat service. Please try again.';
    }
  }

  // Handle incoming chat messages
  Future<void> _handleChatMessage(String payload) async {
    try {
      log('ChatController: Received MQTT message on chat topic: $payload');
      final message = ChatMessage.fromJson(jsonDecode(payload));
      log('ChatController: Parsed message: senderId=${message.senderId}, receiverId=${message.receiverId}');
      
      if (_isValidMessage(message)) {
        await _processIncomingMessage(message);
      }
    } catch (e) {
      log('ChatController: Error processing MQTT message: $e');
    }
  }

  // Handle user-specific messages
  Future<void> _handleUserMessage(String payload) async {
    try {
      log('ChatController: Received MQTT message on user messages topic: $payload');
      final data = jsonDecode(payload);
      
      if (data['type'] == 'new_message') {
        final message = ChatMessage.fromJson(data['message']);
        if (_isValidMessage(message)) {
          await _processIncomingMessage(message);
        }
      } else if (data['type'] == 'read_receipt') {
        _handleReadReceipt(data);
      } else if (data['type'] == 'message_deleted') {
        _handleMessageDeletion(data['messageId']);
      } else if (data['type'] == 'conversation_deleted') {
        _handleConversationDeletion();
      }
    } catch (e) {
      log('ChatController: Error processing user messages: $e');
    }
  }

  // Handle notifications
  void _handleNotification(String payload) {
    try {
      final notification = jsonDecode(payload);
      log('ChatController: Received notification: $notification');
      _showSystemNotification(
        notification['title'] ?? 'New Notification',
        notification['content'] ?? 'You have a new notification',
      );
    } catch (e) {
      log('ChatController: Error processing notification: $e');
    }
  }

  // Validate if message is for current chat
  bool _isValidMessage(ChatMessage message) {
    return (message.senderId == currentUserId && message.receiverId == receiverId) ||
           (message.senderId == receiverId && message.receiverId == currentUserId);
  }

  // Process incoming message
  Future<void> _processIncomingMessage(ChatMessage message) async {
    bool isDuplicate = messages.any((m) => m.id == message.id);
    if (!isDuplicate) {
      // Check for temporary message to replace
      final tempIndex = messages.indexWhere((m) =>
          m.id.startsWith('temp_') &&
          m.senderId == message.senderId &&
          m.content == message.content &&
          m.timestamp.difference(message.timestamp).inSeconds.abs() < 10);
      
      if (tempIndex != -1) {
        messages[tempIndex] = message;
        log('ChatController: Replaced temporary message with server message: ${message.id}');
      } else {
        messages.add(message);
        log('ChatController: Added new message to UI: ${message.content}');
        
        // Show notification for messages from receiver
        if (message.senderId == receiverId && !message.read) {
          _showSystemNotification(
            'New Message from $receiverName',
            message.content,
          );
        }
      }
      
      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      await _cacheMessages();
      
      // Schedule scroll after frame completion to avoid build-time changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
      
      // Mark message as read if from receiver
      if (message.senderId == receiverId && !message.read) {
        // Delay this to avoid state changes during build
        Future.microtask(() async {
          await markMessageAsRead(message.id);
        });
      }
    }
  }

  // Handle read receipt
  void _handleReadReceipt(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String?;
    if (messageId != null) {
      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final message = messages[messageIndex];
        message.read = true;
        message.readAt = DateTime.parse(data['readAt'] ?? DateTime.now().toIso8601String());
        
        // Schedule UI update after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          messages.refresh(); // Trigger UI update
        });
        
        log('ChatController: Updated read receipt for message: $messageId');
        _cacheMessages();
      }
    }
  }

  // Handle message deletion
  void _handleMessageDeletion(String messageId) {
    messages.removeWhere((msg) => msg.id == messageId);
    _cacheMessages();
    log('ChatController: Message deleted: $messageId');
  }

  // Handle conversation deletion
  void _handleConversationDeletion() {
    messages.clear();
    _cacheMessages();
    log('ChatController: Conversation deleted');
  }

  // Fetch messages from API
  Future<void> fetchMessages() async {
    // Don't show loading if we already have cached messages
    if (messages.isEmpty) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
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
          messages.clear();
        } else {
          final responseData = jsonDecode(response.body);
          log('ChatController: Response data type: ${responseData.runtimeType}');
          log('ChatController: Response data: $responseData');
          
          List<ChatMessage> fetchedMessages = [];
          
          // Handle different response formats
          if (responseData is List) {
            // Direct list of messages
            log('ChatController: Received ${responseData.length} messages from API');
            for (var messageData in responseData) {
              try {
                final message = ChatMessage.fromJson(messageData);
                if (_isValidMessage(message)) {
                  fetchedMessages.add(message);
                }
              } catch (e) {
                log('ChatController: Error parsing message: $e');
              }
            }
          } else if (responseData is Map<String, dynamic>) {
            // Response wrapped in an object
            if (responseData.containsKey('messages') && responseData['messages'] is List) {
              // Messages in 'messages' field
              final messagesList = responseData['messages'] as List;
              log('ChatController: Received ${messagesList.length} messages from API (wrapped in messages field)');
              for (var messageData in messagesList) {
                try {
                  final message = ChatMessage.fromJson(messageData);
                  if (_isValidMessage(message)) {
                    fetchedMessages.add(message);
                  }
                } catch (e) {
                  log('ChatController: Error parsing message: $e');
                }
              }
            } else if (responseData.containsKey('data') && responseData['data'] is List) {
              // Messages in 'data' field
              final messagesList = responseData['data'] as List;
              log('ChatController: Received ${messagesList.length} messages from API (wrapped in data field)');
              for (var messageData in messagesList) {
                try {
                  final message = ChatMessage.fromJson(messageData);
                  if (_isValidMessage(message)) {
                    fetchedMessages.add(message);
                  }
                } catch (e) {
                  log('ChatController: Error parsing message: $e');
                }
              }
            } else {
              // Single message object or unknown format
              try {
                final message = ChatMessage.fromJson(responseData);
                if (_isValidMessage(message)) {
                  fetchedMessages.add(message);
                  log('ChatController: Received single message from API');
                }
              } catch (e) {
                log('ChatController: Could not parse response as single message: $e');
                log('ChatController: Unknown response format - available keys: ${responseData.keys}');
              }
            }
          }
          
          // Sort messages by timestamp
          fetchedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          // Update messages list
          messages.assignAll(fetchedMessages);
          
          // Cache the fetched messages
          await _cacheMessages();
          
          log('ChatController: Successfully loaded ${fetchedMessages.length} messages');
        }
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      log('ChatController: Error fetching messages: $e');
      errorMessage.value = 'Failed to load messages. Please try again.';
    } finally {
      isLoading.value = false;
      
      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    }
  }

  // Send message
  Future<void> sendMessage() async {
    if (isSendingMessage.value || messageController.text.trim().isEmpty || chatTopic == null) {
      log('ChatController: Cannot send message: ${isSendingMessage.value ? 'Already sending' : messageController.text.trim().isEmpty ? 'Empty message' : 'Null chat topic'}');
      return;
    }

    final messageContent = messageController.text.trim();
  messages.removeWhere((m) => m.id.startsWith('temp_') && m.content == messageContent);

    isSendingMessage.value = true;
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
      log('ChatController: Added temporary message to UI: $tempId');
      
      await _cacheMessages();
      scrollToBottom();

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

      log('ChatController: Sending message to topic: $chatTopic');
      await _mqttService.publish(chatTopic!, payload);
      SoundPlayer().playSound();
    } catch (e) {
      log('ChatController: Error sending message: $e');
      Get.snackbar('Error', 'Failed to send message. Please try again.');
      messages.removeWhere((m) => m.id.startsWith('temp_'));
      await _cacheMessages();
    } finally {
      isSendingMessage.value = false;
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) return;

      const String baseUrl = 'http://182.93.94.210:3064/api/v1';
      final url = '$baseUrl/message/$messageId/read';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        log('ChatController: Message marked as read: $messageId');
      }
    } catch (e) {
      log('ChatController: Error marking message as read: $e');
    }
  }

  // Delete message for me
  Future<bool> deleteMessageForMe(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) return false;

      const String baseUrl = 'http://182.93.94.210:3064/api/v1';
      final url = '$baseUrl/message/$messageId';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        messages.removeWhere((msg) => msg.id == messageId);
        await _cacheMessages();
        log('ChatController: Message deleted for me: $messageId');
        return true;
      }
      return false;
    } catch (e) {
      log('ChatController: Error deleting message for me: $e');
      return false;
    }
  }

  // Delete message for everyone
  Future<bool> deleteMessageForEveryone(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) return false;

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

      if (response.statusCode == 200) {
        messages.removeWhere((msg) => msg.id == messageId);
        await _cacheMessages();
        log('ChatController: Message deleted for everyone: $messageId');
        return true;
      }
      return false;
    } catch (e) {
      log('ChatController: Error deleting message for everyone: $e');
      return false;
    }
  }

  // Delete entire conversation
  Future<bool> deleteConversation() async {
    try {
      final token = AppData().authToken;
      if (token == null) return false;

      const String baseUrl = 'http://182.93.94.210:3064/api/v1';
      final url = '$baseUrl/conversation/$currentUserId?otherUserId=$receiverId';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        messages.clear();
        await _cacheMessages();
        log('ChatController: Conversation deleted');
        return true;
      }
      return false;
    } catch (e) {
      log('ChatController: Error deleting conversation: $e');
      return false;
    }
  }

  // Cache messages to local storage
  Future<void> _cacheMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${currentUserId}_$receiverId';
      final messagesJson = messages.map((msg) => msg.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(messagesJson));
      log('ChatController: Cached ${messages.length} messages');
    } catch (e) {
      log('ChatController: Error caching messages: $e');
    }
  }

  // Scroll to bottom of messages
  void scrollToBottom() {
    if (scrollController.hasClients && messages.isNotEmpty) {
      try {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        log('ChatController: Error scrolling to bottom: $e');
      }
    }
  }

  @override
  void onClose() {
    log('ChatController: Disposing controller');
    
    // Disconnect MQTT
    try {
      _mqttService.disconnect();
    } catch (e) {
      log('ChatController: Error disconnecting MQTT: $e');
    }
    
    // Dispose controllers
    messageController.dispose();
    scrollController.dispose();
    
    super.onClose();
  }
}