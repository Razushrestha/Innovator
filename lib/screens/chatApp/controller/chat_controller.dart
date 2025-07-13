import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:innovator/Authorization/firebase_services.dart';
import 'package:innovator/App_data/App_data.dart';

class FireChatController extends GetxController {
  // Reactive variables
  final RxList<Map<String, dynamic>> allUsers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> chatList = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  
  final RxBool isLoadingUsers = false.obs;
  final RxBool isLoadingChats = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxBool isTyping = false.obs;
  
  final RxString searchQuery = ''.obs;
  final RxString currentChatId = ''.obs;
  final RxString typingIndicator = ''.obs;
  
  final Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);
  final RxString currentUserId = ''.obs;
  
  // Cache for user data
  final RxMap<String, Map<String, dynamic>> userCache = <String, Map<String, dynamic>>{}.obs;
  final RxMap<String, int> unreadCounts = <String, int>{}.obs;
  final RxMap<String, RxInt> badgeCounts = <String, RxInt>{}.obs; // New: Badge counts
  
  // Real-time message status tracking
  final RxMap<String, String> messageStatuses = <String, String>{}.obs; // messageId -> status
  final RxMap<String, DateTime> lastMessageTimes = <String, DateTime>{}.obs; // chatId -> timestamp
  
  // UI state
  final RxInt selectedBottomIndex = 0.obs;
  final RxBool isDarkMode = false.obs;
  
  // Animation controllers
  final RxDouble fabScale = 1.0.obs;
  final RxBool showScrollToBottom = false.obs;
  
  // Stream subscriptions for real-time updates
  final Map<String, Stream<QuerySnapshot>> _activeStreams = {};

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
    _setupReactiveListeners();
    _startGlobalMessageListener(); // New: Global message listener
  }

  void _initializeUser() {
    try {
      final userData = AppData().currentUser;
      if (userData != null && userData.isNotEmpty) {
        currentUser.value = Map<String, dynamic>.from(userData);
        currentUserId.value = userData['_id']?.toString() ?? 
                              userData['uid']?.toString() ?? '';
        developer.log('ChatController initialized with user: ${currentUserId.value}');
        
        if (currentUserId.value.isNotEmpty) {
          updateUserStatus(true);
          loadAllUsers();
          loadUserChats();
        }
      } else {
        developer.log('No current user data available');
        currentUser.value = null;
        currentUserId.value = '';
      }
    } catch (e) {
      developer.log('Error initializing user: $e');
      currentUser.value = null;
      currentUserId.value = '';
    }
  }

  void _setupReactiveListeners() {
    // Listen to search query changes with debouncing
    ever(searchQuery, (String query) {
      if (query.isEmpty) {
        searchResults.clear();
      } else {
        _debounceSearch(query);
      }
    });
    
    // Listen to current chat changes
    ever(currentChatId, (String chatId) {
      if (chatId.isNotEmpty) {
        loadMessages(chatId);
        markMessagesAsRead(chatId);
      }
    });
  }

  // NEW: Global message listener for real-time updates
  void _startGlobalMessageListener() {
    if (currentUserId.value.isEmpty) return;
    
    try {
      // Listen to all messages where current user is participant
      FirebaseFirestore.instance
          .collection('messages')
          .where('participants', arrayContains: currentUserId.value)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        
        for (var change in snapshot.docChanges) {
          final messageData = change.doc.data() as Map<String, dynamic>?;
          if (messageData == null) continue;
          
          final chatId = messageData['chatId']?.toString() ?? '';
          final senderId = messageData['senderId']?.toString() ?? '';
          final isMyMessage = senderId == currentUserId.value;
          
          switch (change.type) {
            case DocumentChangeType.added:
              if (!isMyMessage) {
                _handleNewMessage(chatId, messageData);
              }
              break;
            case DocumentChangeType.modified:
              _handleMessageUpdate(change.doc.id, messageData);
              break;
            default:
              break;
          }
        }
      });
    } catch (e) {
      developer.log('Error setting up global message listener: $e');
    }
  }

  // NEW: Handle new incoming messages
  void _handleNewMessage(String chatId, Map<String, dynamic> messageData) {
    // Update chat list position (move to top)
    _moveChatToTop(chatId);
    
    // Update unread count
    if (currentChatId.value != chatId) {
      final currentCount = unreadCounts[chatId] ?? 0;
      unreadCounts[chatId] = currentCount + 1;
      
      // Update badge count
      if (!badgeCounts.containsKey(chatId)) {
        badgeCounts[chatId] = 0.obs;
      }
      badgeCounts[chatId]!.value = unreadCounts[chatId] ?? 0;
      
      // Show notification badge animation
      _animateBadge(chatId);
    }
    
    // Update last message time
    final timestamp = messageData['timestamp'] as Timestamp?;
    if (timestamp != null) {
      lastMessageTimes[chatId] = timestamp.toDate();
    }
  }

  // NEW: Handle message status updates (read receipts)
  void _handleMessageUpdate(String messageId, Map<String, dynamic> messageData) {
    final isRead = messageData['isRead'] ?? false;
    final senderId = messageData['senderId']?.toString() ?? '';
    
    // Update message status for blue tick
    if (senderId == currentUserId.value) {
      messageStatuses[messageId] = isRead ? 'read' : 'delivered';
      
      // Update message in current chat if viewing
      final messageIndex = messages.indexWhere((msg) => msg['id'] == messageId);
      if (messageIndex != -1) {
        messages[messageIndex]['isRead'] = isRead;
        messages.refresh(); // Trigger UI update
      }
    }
  }

  // NEW: Move chat to top of list
  void _moveChatToTop(String chatId) {
    final chatIndex = chatList.indexWhere((chat) => chat['chatId'] == chatId);
    if (chatIndex > 0) {
      final chat = chatList.removeAt(chatIndex);
      chatList.insert(0, chat);
    }
  }

  // NEW: Animate badge for new messages
  void _animateBadge(String chatId) {
    // Trigger badge animation (can be used in UI)
    Future.delayed(const Duration(milliseconds: 100), () {
      // Badge animation logic
    });
  }

  // Debounced search to prevent excessive API calls
  void _debounceSearch(String query) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery.value == query) {
        searchUsers(query);
      }
    });
  }

  // User Management
  Future<void> updateUserStatus(bool isOnline) async {
    try {
      if (currentUserId.value.isNotEmpty) {
        await FirebaseService.updateUserStatus(currentUserId.value, isOnline);
      }
    } catch (e) {
      developer.log('Error updating user status: $e');
    }
  }

  // Load all users with caching
  Future<void> loadAllUsers() async {
    if (isLoadingUsers.value) return;
    
    isLoadingUsers.value = true;
    try {
      FirebaseService.getAllUsers().listen((snapshot) {
        final users = <Map<String, dynamic>>[];
        for (var doc in snapshot.docs) {
          if (doc.id != currentUserId.value) {
            final userData = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
            userData['id'] = doc.id;
            users.add(userData);
            userCache[doc.id] = userData;
          }
        }
        allUsers.assignAll(users);
        isLoadingUsers.value = false;
      });
    } catch (e) {
      isLoadingUsers.value = false;
      developer.log('Error loading users: $e');
    }
  }

  // ENHANCED: Load user chats with real-time updates and sorting
  Future<void> loadUserChats() async {
    if (isLoadingChats.value || currentUserId.value.isEmpty) return;
    
    isLoadingChats.value = true;
    try {
      FirebaseService.getUserChats(currentUserId.value).listen((snapshot) async {
        final chats = <Map<String, dynamic>>[];
        
        for (var doc in snapshot.docs) {
          final chatData = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          chatData['id'] = doc.id;
          
          final participants = List<String>.from(chatData['participants'] ?? []);
          final otherUserId = participants.firstWhere(
            (id) => id != currentUserId.value,
            orElse: () => '',
          );
          
          if (otherUserId.isNotEmpty) {
            Map<String, dynamic>? otherUser = userCache[otherUserId];
            if (otherUser == null) {
              try {
                final userDoc = await FirebaseService.getUserById(otherUserId);
                if (userDoc.exists) {
                  otherUser = Map<String, dynamic>.from(userDoc.data() as Map<String, dynamic>);
                  otherUser['id'] = otherUserId;
                  userCache[otherUserId] = otherUser;
                }
              } catch (e) {
                developer.log('Error loading user $otherUserId: $e');
                continue;
              }
            }
            
            if (otherUser != null) {
              chatData['otherUser'] = otherUser;
              chats.add(chatData);
              
              final chatId = chatData['chatId'] ?? '';
              _updateUnreadCount(chatId, otherUserId);
              
              // Initialize badge count
              if (!badgeCounts.containsKey(chatId)) {
                badgeCounts[chatId] = 0.obs;
              }
            }
          }
        }
        
        // Sort chats by last message time (newest first)
        chats.sort((a, b) {
          final aTime = a['lastMessageTime'] as Timestamp?;
          final bTime = b['lastMessageTime'] as Timestamp?;
          
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          
          return bTime.compareTo(aTime);
        });
        
        chatList.assignAll(chats);
        isLoadingChats.value = false;
      });
    } catch (e) {
      isLoadingChats.value = false;
      developer.log('Error loading chats: $e');
    }
  }

  void _updateUnreadCount(String chatId, String otherUserId) {
    if (chatId.isEmpty) return;
    
    try {
      FirebaseService.getUnreadMessageCount(chatId, currentUserId.value).listen((snapshot) {
        final count = snapshot.docs.length;
        unreadCounts[chatId] = count;
        
        // Update badge count
        if (!badgeCounts.containsKey(chatId)) {
          badgeCounts[chatId] = 0.obs;
        }
        badgeCounts[chatId]!.value = count;
      });
    } catch (e) {
      developer.log('Error updating unread count: $e');
    }
  }

  // Search users with optimized performance
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    
    isSearching.value = true;
    try {
      final results = await FirebaseService.searchUsers(query.trim());
      final users = <Map<String, dynamic>>[];
      
      for (var doc in results.docs) {
        if (doc.id != currentUserId.value) {
          final userData = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          userData['id'] = doc.id;
          users.add(userData);
          userCache[doc.id] = userData;
        }
      }
      
      searchResults.assignAll(users);
    } catch (e) {
      developer.log('Error searching users: $e');
      Get.snackbar(
        'Error',
        'Failed to search users',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // ENHANCED: Load messages with instant read receipt updates
  void loadMessages(String chatId) {
    if (chatId.isEmpty) return;
    
    currentChatId.value = chatId;
    isLoadingMessages.value = true;
    
    try {
      FirebaseService.getMessages(chatId).listen((snapshot) {
        final messageList = <Map<String, dynamic>>[];
        
        for (var doc in snapshot.docs) {
          final messageData = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          messageData['id'] = doc.id;
          
          // Track message status for blue tick
          final senderId = messageData['senderId']?.toString() ?? '';
          if (senderId == currentUserId.value) {
            final isRead = messageData['isRead'] ?? false;
            messageStatuses[doc.id] = isRead ? 'read' : 'delivered';
          }
          
          messageList.add(messageData);
        }
        
        messages.assignAll(messageList);
        isLoadingMessages.value = false;
        
        if (messageList.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 100), () {
            scrollToBottom();
          });
        }
      });
    } catch (e) {
      isLoadingMessages.value = false;
      developer.log('Error loading messages: $e');
    }
  }

  // ENHANCED: Send message with instant status updates
  Future<void> sendMessage({
    required String receiverId,
    required String message,
    String? replyToId,
  }) async {
    if (message.trim().isEmpty || currentUserId.value.isEmpty) return;
    
    final chatId = FirebaseService.generateChatId(currentUserId.value, receiverId);
    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Optimistic update with sending status
    final tempMessage = {
      'id': tempMessageId,
      'chatId': chatId,
      'senderId': currentUserId.value,
      'receiverId': receiverId,
      'message': message.trim(),
      'senderName': currentUser.value?['name']?.toString() ?? 'User',
      'timestamp': Timestamp.now(),
      'isRead': false,
      'messageType': 'text',
      'isSending': true,
    };
    
    messages.insert(0, tempMessage);
    messageStatuses[tempMessageId] = 'sending';
    
    isSendingMessage.value = true;
    
    try {
      // Send message to Firebase
      final sentMessageRef = await FirebaseService.sendMessage(
        chatId: chatId,
        senderId: currentUserId.value,
        receiverId: receiverId,
        message: message.trim(),
        senderName: currentUser.value?['name']?.toString() ?? 'User',
      );
      
      // Update message status to delivered
      messageStatuses[tempMessageId] = 'delivered';
      
      // Remove temp message (real one will come through stream)
      messages.removeWhere((msg) => msg['id'] == tempMessageId);
      
      // Update chat list - move this chat to top
      _moveChatToTop(chatId);
      
      animateFab();
      
    } catch (e) {
      // Remove failed message
      messages.removeWhere((msg) => msg['id'] == tempMessageId);
      messageStatuses.remove(tempMessageId);
      
      Get.snackbar(
        'Error',
        'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      developer.log('Error sending message: $e');
    } finally {
      isSendingMessage.value = false;
    }
  }

  // ENHANCED: Mark messages as read with instant update
  Future<void> markMessagesAsRead(String chatId) async {
    if (chatId.isEmpty) return;
    
    try {
      await FirebaseService.markMessagesAsRead(chatId, currentUserId.value);
      
      // Instantly update local state
      unreadCounts[chatId] = 0;
      if (badgeCounts.containsKey(chatId)) {
        badgeCounts[chatId]!.value = 0;
      }
      
      // Update messages in current chat
      for (var message in messages) {
        if (message['chatId'] == chatId && message['senderId'] != currentUserId.value) {
          message['isRead'] = true;
        }
      }
      messages.refresh();
      
    } catch (e) {
      developer.log('Error marking messages as read: $e');
    }
  }

  // NEW: Get message status for blue tick display
  String getMessageStatus(String messageId) {
    return messageStatuses[messageId] ?? 'sending';
  }

  // NEW: Get badge count for chat
  RxInt getBadgeCount(String chatId) {
    if (!badgeCounts.containsKey(chatId)) {
      badgeCounts[chatId] = 0.obs;
    }
    return badgeCounts[chatId]!;
  }

  // NEW: Clear badge for specific chat
  void clearBadge(String chatId) {
    if (badgeCounts.containsKey(chatId)) {
      badgeCounts[chatId]!.value = 0;
    }
    unreadCounts[chatId] = 0;
  }

  // UI Animations
  void animateFab() {
    fabScale.value = 0.8;
    Future.delayed(const Duration(milliseconds: 150), () {
      fabScale.value = 1.0;
    });
  }

  void scrollToBottom() {
    showScrollToBottom.value = false;
  }

  void onScrollChanged(double pixels, double maxScrollExtent) {
    showScrollToBottom.value = pixels > 200;
  }

  // Navigation
  void changeBottomIndex(int index) {
    selectedBottomIndex.value = index;
  }

  void navigateToChat(Map<String, dynamic> user) {
    Get.toNamed('/chat', arguments: {
      'receiverUser': user,
      'currentUser': currentUser.value,
    });
  }

  void setTyping(bool typing) {
    isTyping.value = typing;
  }

  // Theme management
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Cleanup
  @override
  void onClose() {
    updateUserStatus(false);
    super.onClose();
  }

  // Utility methods
  String formatLastSeen(Timestamp? lastSeen) {
    if (lastSeen == null) return 'Never';
    
    final now = DateTime.now();
    final lastSeenDate = lastSeen.toDate();
    final difference = now.difference(lastSeenDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final messageTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inDays > 0) {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    } else {
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String formatChatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final chatTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(chatTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[chatTime.weekday - 1];
      } else {
        return '${chatTime.day}/${chatTime.month}/${chatTime.year}';
      }
    } else if (difference.inHours > 0) {
      return '${chatTime.hour.toString().padLeft(2, '0')}:${chatTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String truncateMessage(String message, int maxLength) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  int getUnreadCount(String chatId) {
    return unreadCounts[chatId] ?? 0;
  }

  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String getCurrentUserId() {
    return currentUser.value?['_id']?.toString() ?? 
           currentUser.value?['uid']?.toString() ?? '';
  }

  bool isUserOnline(Map<String, dynamic>? user) {
    return user?['isOnline'] == true;
  }

  String getUserName(Map<String, dynamic>? user) {
    return user?['name']?.toString() ?? 'Unknown User';
  }

  String? getUserPhotoUrl(Map<String, dynamic>? user)    {
    final photoUrl = user?['photoURL']?.toString();
    return (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null;
  }

  String getUserInitials(Map<String, dynamic>? user) {
    final name = getUserName(user);
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
  }
}