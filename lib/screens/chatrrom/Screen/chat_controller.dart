import 'dart:async';
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
  final isInitialized = false.obs;
  final isAppInBackground = false.obs; // Track app state

  final Set<String> _processedMessageIds = <String>{};

  
  // Controllers
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  // Services
  final MQTTService _mqttService = MQTTService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
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
    _setupAppLifecycleListener();
    _initializeNotifications();
  }

Future<void> _initializeNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  // Setup app lifecycle listener to track when app goes to background
  void _setupAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  // Method to update app background state
  void updateAppState(bool inBackground) {
    isAppInBackground.value = inBackground;
    log('ChatController: App state changed - inBackground: $inBackground');
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
    if (isInitialized.value) {
      log('ChatController: Already initialized, skipping');
      return;
    }

    _processedMessageIds.clear();

    this.currentUserId = currentUserId;
    this.currentUserName = currentUserName;
    this.currentUserPicture = currentUserPicture;
    this.currentUserEmail = currentUserEmail;
    this.receiverId = receiverId;
    this.receiverName = receiverName;
    this.receiverPicture = receiverPicture;
    this.receiverEmail = receiverEmail;
    
    log('ChatController: Initializing chat with currentUserId=$currentUserId, receiverId=$receiverId');
    
    isInitialized.value = true;
    
    _loadCachedMessages().then((_) {
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

      _mqttService.subscribe('user/$currentUserId/notifications', (String payload) {
        _handleNotification(payload);
      });

      // Subscribe to notifications
      // _mqttService.subscribe('user/$currentUserId/notifications', (String payload) {
      //   _handleNotification(payload);
      // });

      mqttInitialized.value = true;
      log('ChatController: MQTT setup completed');
    } catch (e) {
      log('ChatController: Error setting up MQTT: $e');
      errorMessage.value = 'Failed to connect to chat service. Please try again.';
    }
  }

  void _handleNotification(String payload) {
    try {
      log('ChatController: Received MQTT notification: $payload');
      final data = jsonDecode(payload);
      final message = ChatMessage.fromJson(data['message'] ?? data);
      if (_isValidMessage(message) && message.senderId == receiverId && !_processedMessageIds.contains(message.id)) {
        _showLocalNotification(message);
      }
    } catch (e) {
      log('ChatController: Error processing notification: $e');
    }
  }

  Future<void> _showLocalNotification(ChatMessage message) async {
    if (_processedMessageIds.contains(message.id)) return;
    _processedMessageIds.add(message.id);

    try {
      await _notificationsPlugin.show(
        message.id.hashCode,
        message.senderName,
        message.content,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode({
          'screen': 'chat',
          'receiverId': message.senderId,
          'receiverName': message.senderName,
          'receiverPicture': message.senderPicture,
          'receiverEmail': message.senderEmail,
        }),
      );
      log('ChatController: Notification shown for message: ${message.id}');
    } catch (e) {
      log('ChatController: Error showing notification: $e');
    }
  }

  // Handle incoming chat messages
  Future<void> _handleChatMessage(String payload) async {
    try {
      log('ChatController: Received MQTT message on chat topic: $payload');
      final data = jsonDecode(payload);
      
      // Handle different message formats
      ChatMessage? message;
      if (data.containsKey('message') && data['message'] is Map) {
        // Message wrapped in 'message' field
        message = ChatMessage.fromJson(data['message']);
      } else if (data.containsKey('sender') && data.containsKey('receiver')) {
        // Direct message format - convert to ChatMessage format
        message = ChatMessage(
          id: data['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: data['sender']['_id'],
          senderName: data['sender']['name'] ?? 'Unknown',
          senderPicture: data['sender']['picture'] ?? '',
          senderEmail: data['sender']['email'] ?? '',
          receiverId: data['receiver']['_id'],
          receiverName: data['receiver']['name'] ?? 'Unknown',
          receiverPicture: data['receiver']['picture'] ?? '',
          receiverEmail: data['receiver']['email'] ?? '',
          content: data['message'],
          timestamp: DateTime.parse(data['timestamp']),
          read: data['read'] ?? false,
          readAt: data['readAt'] != null ? DateTime.parse(data['readAt']) : null,
        );
      } else {
        // Try to parse as direct ChatMessage
        message = ChatMessage.fromJson(data);
      }
      
      if (message != null) {
        log('ChatController: Parsed message: senderId=${message.senderId}, receiverId=${message.receiverId}');
        
        if (_isValidMessage(message)) {
          await _processIncomingMessage(message);
        } else {
          log('ChatController: Invalid message for current chat, ignoring');
        }
      }
    } catch (e) {
      log('ChatController: Error processing MQTT chat message: $e');
    }
  }

  // Handle user-specific messages
 Future<void> _handleUserMessage(String payload) async {
    try {
      log('ChatController: Received MQTT message on user messages topic: $payload');
      final data = jsonDecode(payload);
      
      if (data['type'] == 'new_message') {
        // Only process if it's not from the chat topic (to avoid duplicates)
        final message = ChatMessage.fromJson(data['message']);
        if (_isValidMessage(message)) {
          // Add a small delay to let chat topic handler process first
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Check if message was already processed by chat topic handler
          if (!_processedMessageIds.contains(message.id)) {
            await _processIncomingMessage(message);
          } else {
            log('ChatController: Message already processed by chat topic handler, skipping');
          }
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
  

  // Validate if message is for current chat
  bool _isValidMessage(ChatMessage message) {
    return (message.senderId == currentUserId && message.receiverId == receiverId) ||
           (message.senderId == receiverId && message.receiverId == currentUserId);
  }

  // Process incoming message
  Future<void> _processIncomingMessage(ChatMessage message) async {
    bool isDuplicate = messages.any((m) => m.id == message.id);
    if (_processedMessageIds.contains(message.id)) {
      log('ChatController: Skipping duplicate message: ${message.id}');
      return;
    }
    if (!isDuplicate) {
      // Check for temporary message to replace
      final tempIndex = messages.indexWhere((m) =>
          m.id.startsWith('temp_') &&
          m.senderId == message.senderId &&
          m.content == message.content &&
          m.timestamp.difference(message.timestamp).inSeconds.abs() < 30);
      
      if (tempIndex != -1) {
        final tempMessage = messages[tempIndex];
        messages[tempIndex] = message;
        log('ChatController: Replaced temporary message with server message: ${message.id}');
      } else {
        // Check if this exact message already exists (additional safety)
        bool messageExists = messages.any((m) => 
            m.id == message.id || 
            (m.senderId == message.senderId && 
             m.receiverId == message.receiverId &&
             m.content.trim() == message.content.trim() &&
             m.timestamp.difference(message.timestamp).inSeconds.abs() < 5));

        if (!messageExists) {
          messages.add(message);
          log('ChatController: Added new message to UI: ${message.content}');
          
          // Show notification for messages from receiver
          if (message.senderId == receiverId && !message.read) {
            if (isAppInBackground.value) {
              _showLocalNotification(message);
            } else {
              // If app is in foreground and message is from receiver, mark as read immediately
              Future.microtask(() async {
                await markMessageAsRead(message.id);
              });
            }
          }
        }
      }
      _processedMessageIds.add(message.id);
      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      await _cacheMessages();
      
      // Schedule scroll after frame completion to avoid build-time changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
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
        
        // Force UI update immediately
        messages[messageIndex] = ChatMessage(
          id: message.id,
          senderId: message.senderId,
          senderName: message.senderName,
          senderPicture: message.senderPicture,
          senderEmail: message.senderEmail,
          receiverId: message.receiverId,
          receiverName: message.receiverName,
          receiverPicture: message.receiverPicture,
          receiverEmail: message.receiverEmail,
          content: message.content,
          timestamp: message.timestamp,
          read: true,
          readAt: message.readAt,
        );
        
        messages.refresh();
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
    // Clean up any existing temporary messages with the same content
    messages.removeWhere((m) => m.id.startsWith('temp_') && m.content.trim() == messageContent);

    isSendingMessage.value = true;
        messageController.clear(); // Clear immediately to prevent double sending

    try {
     // final messageContent = messageController.text.trim();
     // messageController.clear();

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
                'tempId': tempId, // Include temp ID for better tracking

      };

      log('ChatController: Sending message to topic: $chatTopic');
      await _mqttService.publish(chatTopic!, payload);
      SoundPlayer().playSound();

      // Set a timeout to remove temporary message if not replaced
      Timer(const Duration(seconds: 3), () {
        final stillExists = messages.any((m) => m.id == tempId);
        if (stillExists) {
          log('ChatController: Removing unconfirmed temporary message: $tempId');
          messages.removeWhere((m) => m.id == tempId);
          _cacheMessages();
        }
      });

    } catch (e) {
      log('ChatController: Error sending message: $e');
      Get.snackbar('Error', 'Failed to send message. Please try again.');
      messages.removeWhere((m) => m.id.startsWith('temp_') && m.senderId == currentUserId );
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
        
        // Publish MQTT message for instant read receipt
        if (_mqttService.isConnected()) {
          final readReceiptPayload = {
            'type': 'read_receipt',
            'messageId': messageId,
            'readBy': currentUserId,
            'readAt': DateTime.now().toIso8601String(),
            'chatId': '${currentUserId}_$receiverId'
          };
          
          // Send to both user-specific topics to ensure delivery
          await _mqttService.publish('user/$receiverId/messages', readReceiptPayload);
          await _mqttService.publish(chatTopic!, readReceiptPayload);
          
          // Update local message state
          final messageIndex = messages.indexWhere((m) => m.id == messageId);
          if (messageIndex != -1) {
            messages[messageIndex].read = true;
            messages[messageIndex].readAt = DateTime.now();
            messages.refresh();
          }
        }
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
    _processedMessageIds.clear();
    
    WidgetsBinding.instance.removeObserver(_AppLifecycleObserver(this));
    
    try {
      _mqttService.disconnect();
    } catch (e) {
      log('ChatController: Error disconnecting MQTT: $e');
    }
    
    messageController.dispose();
    scrollController.dispose();
    
    super.onClose();
  }
}

// App lifecycle observer to track when app goes to background
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final ChatController _controller;

  _AppLifecycleObserver(this._controller);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.updateAppState(false);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _controller.updateAppState(true);
        break;
    }
  }
}