import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/chatrrom/Screen/chatscreen.dart';
import 'package:innovator/screens/chatrrom/Services/mqtt_services.dart';
import 'package:innovator/screens/chatrrom/utils.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'package:badges/badges.dart' as badges;

class ChatListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserPicture;
  final String currentUserEmail;

  const ChatListScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserPicture,
    required this.currentUserEmail,
  }) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  final TextEditingController _searchController = TextEditingController();
  final MQTTService _mqttService = MQTTService();
  bool _isMqttConnected = false;
  final Map<String, int> _unreadMessageCounts = {};
  final Map<String, DateTime> _newMessageTimestamps = {};
  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  final Set<String> _processedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchChats();
    _initializeMQTT();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mqttService.disconnect();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _notificationsPlugin!.initialize(initSettings);
    log('Notifications initialized');
  }

  Future<void> _showNotification(String chatId, String senderName, String message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin!.show(
      chatId.hashCode,
      'New Message from $senderName',
      message,
      platformDetails,
      payload: chatId,
    );
    log('Notification shown for chatId: $chatId, sender: $senderName');
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChats = _chats.where((chat) {
        final user = chat['user'] as Map<String, dynamic>? ?? {};
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
      log('Filtered chats updated: ${_filteredChats.length} chats');
    });
  }

  Future<void> _fetchChats() async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        throw Exception('No auth token available');
      }

      final response = await http.get(
        Uri.parse('${Utils.baseUrl}/api/v1/chats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      log('Chat API Response: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200 && response.headers['content-type']?.contains('application/json') == true) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> && responseData['data'] is List) {
          setState(() {
            _chats = List<Map<String, dynamic>>.from(responseData['data']);
            for (var chat in _chats) {
              final chatId = chat['_id']?.toString();
              if (chatId != null) {
                final apiUnreadCount = (chat['unreadCount'] as int?) ?? 0;
                _unreadMessageCounts[chatId] = (_unreadMessageCounts[chatId] ?? 0) > apiUnreadCount
                    ? _unreadMessageCounts[chatId]!
                    : apiUnreadCount;
                log('Initialized unread count for chatId: $chatId, API count: $apiUnreadCount, final count: ${_unreadMessageCounts[chatId]}');
              }
            }
            _filteredChats = List.from(_chats);
            log('Chats fetched: ${_chats.length} chats, IDs: ${_chats.map((c) => c['_id']).toList()}');
            log('Unread counts after fetch: $_unreadMessageCounts');
            _subscribeToChatTopics();
          });
        } else {
          throw Exception('Invalid chat list format');
        }
      } else {
        throw Exception('Failed to fetch chats: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching chats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching chats: $e')),
        );
      }
    }
  }

  Future<void> _initializeMQTT() async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        throw Exception('No auth token available for MQTT');
      }
      await _mqttService.connect(token, widget.currentUserId);
      setState(() {
        _isMqttConnected = true;
      });
      log('MQTTService: Initialized and connected');

      _mqttService.subscribe('user/${widget.currentUserId}/messages', (payload) {
        log('Received message on user topic: $payload');
      });

      _mqttService.messageStream.listen((data) {
        log('Stream received message: $data');
        _handleMqttMessage(data);
      }, onError: (e) {
        log('Error in message stream: $e');
        if (mounted) {
          setState(() {
            _isMqttConnected = false;
          });
        }
      });
    } catch (e) {
      log('Error initializing MQTT: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to MQTT: $e')),
        );
      }
      setState(() {
        _isMqttConnected = false;
      });
    }
  }

  void _subscribeToChatTopics() {
    if (!_isMqttConnected) {
      log('Cannot subscribe to chat topics: MQTT not connected');
      return;
    }
    for (var chat in _chats) {
      final user = chat['user'] as Map<String, dynamic>? ?? {};
      final receiverId = user['_id']?.toString() ?? '';
      if (receiverId.isNotEmpty) {
        final chatTopic = _mqttService.getChatTopic(widget.currentUserId, receiverId);
        log('Subscribing to chat topic: $chatTopic');
        _mqttService.subscribe(chatTopic, (payload) {
          log('Received message on chat topic: $chatTopic, payload: $payload');
        });
      }
    }
  }

  String? findChatId(String senderId, String receiverId) {
  for (var chat in _chats) {
    final user = chat['user'] as Map<String, dynamic>? ?? {};
    final userId = user['_id']?.toString() ?? '';
    if ((senderId == widget.currentUserId && userId == receiverId) ||
        (receiverId == widget.currentUserId && userId == senderId)) {
      return chat['_id']?.toString();
    }
  }
  return null;
}

  void _handleMqttMessage(Map<String, dynamic> data) {
    if (!mounted) {
      log('ChatListScreen not mounted, skipping message processing');
      return;
    }
    try {
      log('Handling MQTT message: $data');
      if (data['type'] == 'new_message' && data['message'] != null) {
        final messageData = data['message'] as Map<String, dynamic>;
        final senderInfo = messageData['sender'] as Map<String, dynamic>? ?? {};
        final senderId = senderInfo['_id']?.toString() ?? '';
        final receiverId = (messageData['receiver'] as Map<String, dynamic>?)?['_id']?.toString() ?? '';
        final senderName = senderInfo['name']?.toString() ?? 'Unknown';
        final messageText = messageData['decryptedMessage']?.toString() ?? messageData['message']?.toString() ?? '';
        final messageId = messageData['id']?.toString() ?? '';
        final isRead = messageData['read'] == true;

        log('Processing MQTT message for messageId: $messageId, senderId: $senderId, receiverId: $receiverId, message: $messageText, read: $isRead');

        if (_processedMessageIds.contains(messageId)) {
          log('Message already processed: $messageId');
          return;
        }
        _processedMessageIds.add(messageId);

        String? chatId;
        int chatIndex = -1;
        for (var i = 0; i < _chats.length; i++) {
          final chat = _chats[i];
          final user = chat['user'] as Map<String, dynamic>? ?? {};
          final userId = user['_id']?.toString() ?? '';
          if ((senderId == widget.currentUserId && userId == receiverId) ||
              (receiverId == widget.currentUserId && userId == senderId)) {
            chatId = chat['_id']?.toString();
            chatIndex = i;
            break;
          }
        }

        if (chatId == null || chatIndex == -1) {
          log('Chat not found for senderId: $senderId, receiverId: $receiverId, fetching chats');
          _fetchChats().then((_) {
            setState(() {
              for (var i = 0; i < _chats.length; i++) {
                final chat = _chats[i];
                final user = chat['user'] as Map<String, dynamic>? ?? {};
                final userId = user['_id']?.toString() ?? '';
                if ((senderId == widget.currentUserId && userId == receiverId) ||
                    (receiverId == widget.currentUserId && userId == senderId)) {
                  chatId = chat['_id']?.toString();
                  chatIndex = i;
                  log('Found chat after fetch: chatId: $chatId');
                  _updateChat(chatId!, chatIndex, senderId, messageText, messageData, senderName);
                  return;
                }
              }
              log('Chat still not found after fetch for messageId: $messageId');
              final tempChat = {
                '_id': 'temp_${senderId}_$receiverId' as String,
                'user': {
                  '_id': senderId as String,
                  'name': senderName as String,
                  'email': (senderInfo['email'] ?? '') as String,
                  'picture': (senderInfo['picture'] ?? '') as String,
                },
                'lastMessage': {
                  'message': messageText as String,
                  'timestamp': (messageData['createdAt']?.toString() ?? DateTime.now().toIso8601String()) as String,
                },
                'unreadCount': isRead ? 0 : 1 as int,
              };
              _chats.insert(0, tempChat);
              _unreadMessageCounts[tempChat['_id'] as String] = isRead ? 0 : 1;
              _newMessageTimestamps[tempChat['_id'] as String] = DateTime.now().add(const Duration(seconds: 5));
              _filteredChats = List.from(_chats);
              _onSearchChanged();
              if (!isRead) {
                _showNotification(tempChat['_id'] as String, senderName, messageText);
              }
              log('Created temporary chat for senderId: $senderId, tempChatId: ${tempChat['_id']}, unread: ${_unreadMessageCounts[tempChat['_id']]}');
            });
          });
          return;
        }

        _updateChat(chatId, chatIndex, senderId, messageText, messageData, senderName);
      } else if (data['type'] == 'read_receipt') {
        final messageId = data['messageId']?.toString();
        final chatTopic = data['chatTopic']?.toString();
        if (messageId != null && chatTopic != null) {
          log('Received read receipt for messageId: $messageId, chatTopic: $chatTopic');
          setState(() {
            for (var chat in _chats) {
              final user = chat['user'] as Map<String, dynamic>? ?? {};
              final userId = user['_id']?.toString() ?? '';
              final expectedTopic = _mqttService.getChatTopic(widget.currentUserId, userId);
              if (expectedTopic == chatTopic) {
                final chatId = chat['_id']?.toString();
                if (chatId != null && _unreadMessageCounts[chatId] != null && _unreadMessageCounts[chatId]! > 0) {
                  _unreadMessageCounts[chatId] = _unreadMessageCounts[chatId]! - 1;
                  log('Decremented unread count for chatId: $chatId to ${_unreadMessageCounts[chatId]} due to read receipt');
                }
              }
            }
            log('Unread counts after read receipt: $_unreadMessageCounts');
          });
        } else {
          log('Invalid read receipt: messageId or chatTopic missing');
        }
      } else {
        log('Invalid MQTT message format: $data');
      }
    } catch (e) {
      log('Error processing MQTT message: $e');
    }
  }

  void _updateChat(
  String chatId,
  int chatIndex,
  String senderId,
  String messageText,
  Map<String, dynamic> messageData,
  String senderName,
) {
  setState(() {
    _chats[chatIndex]['lastMessage'] = {
      'message': messageText,
      'timestamp': messageData['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    };
    final isRead = messageData['read'] == true;
    if (senderId != widget.currentUserId && !isRead) {
      _unreadMessageCounts[chatId] = (_unreadMessageCounts[chatId] ?? 0) + 1;
      // Set highlight for 5 seconds
      _newMessageTimestamps[chatId] = DateTime.now().add(const Duration(seconds: 5));
      _showNotification(chatId, senderName, messageText);
      log('Incremented unread count for chatId: $chatId to ${_unreadMessageCounts[chatId]}');
    }
    // Move to top regardless of read status
    if (chatIndex > 0) {
      final chat = _chats.removeAt(chatIndex);
      _chats.insert(0, chat);
      log('Moved chatId: $chatId to top of list');
    }
    _filteredChats = List.from(_chats);
    _onSearchChanged();
    log('Unread counts after update: $_unreadMessageCounts');
  });
}

  void _markChatAsRead(String chatId) {
    setState(() {
      _unreadMessageCounts[chatId] = 0;
      _newMessageTimestamps.remove(chatId);
      log('Marked chatId: $chatId as read, unread count reset to 0');
      log('Unread counts after mark as read: $_unreadMessageCounts');
    });
  }

  bool _isRecentMessage(String chatId) {
    final timestamp = _newMessageTimestamps[chatId];
    if (timestamp == null) return false;

    final now = DateTime.now();
    if (now.isAfter(timestamp)) {
      setState(() {
        _newMessageTimestamps.remove(chatId);
      });
      return false;
    }
    return true;
  }

  Future<void> _logout() async {
    try {
      await AppData().logout();
      _mqttService.disconnect();
      Get.offAll(() => const LoginPage());
    } catch (e) {
      log('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(244, 135, 6, 0.2),
                  Color.fromRGBO(244, 135, 6, 0.1),
                  Colors.grey,
                ],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(30),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        prefixIcon: const Icon(Icons.search, color: Color.fromRGBO(244, 135, 6, 1)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _isMqttConnected ? Icons.wifi : Icons.wifi_off,
                        color: _isMqttConnected ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isMqttConnected ? 'Connected to real-time updates' : 'Disconnected from real-time updates',
                        style: TextStyle(
                          color: _isMqttConnected ? Colors.green : Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredChats.isEmpty
                      ? const Center(child: Text('No chats available'))
                      : ListView.builder(
                          itemCount: _filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = _filteredChats[index];
                            final chatId = chat['_id']?.toString() ?? '';
                            final unreadCount = _unreadMessageCounts[chatId] ?? 0;
                            final hasUnread = unreadCount > 0;

                            final user = chat['user'] as Map<String, dynamic>? ?? {'_id': '', 'name': 'Unknown', 'email': ''};
                            final userId = user['_id']?.toString() ?? '';
                            final profilePicture = user['picture']?.toString() ?? '';
                            final displayName = user['name']?.toString() ?? 'Unknown';
                            final email = user['email']?.toString() ?? '';

                            log('Rendering chat for user: $displayName, chatId: $chatId, unread: $unreadCount, hasUnread: $hasUnread');
                            if (hasUnread) {
                              log('Showing badge for chatId: $chatId, count: $unreadCount');
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: _isRecentMessage(chatId) ? Colors.orange.withOpacity(0.15) : hasUnread ? Colors.orange.withOpacity(0.15) : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: hasUnread
                                    ? BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.withOpacity(0.3),
                                            Colors.orange.withOpacity(0.1),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                    : null,
                                child: ListTile(
                                  leading: badges.Badge(
                                    showBadge: unreadCount > 0 || hasUnread == false,
                                    badgeContent: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    badgeStyle: const badges.BadgeStyle(
                                      badgeColor: Color.fromRGBO(244, 135, 6, 1),
                                      padding: EdgeInsets.all(6),
                                      borderSide: BorderSide(color: Colors.white, width: 2),
                                    ),
                                    position: badges.BadgePosition.topEnd(top: -8, end: -8),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.grey[200],
                                      radius: 24,
                                      child: Utils.isValidImageUrl(profilePicture)
                                          ? ClipOval(
                                              child: Image.network(
                                                Utils.getImageUrl(profilePicture),
                                                fit: BoxFit.cover,
                                                width: 48,
                                                height: 48,
                                                errorBuilder: (context, error, stackTrace) => Text(
                                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                                  style: const TextStyle(fontSize: 20),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: TextStyle(
                                            fontWeight: hasUnread || _isRecentMessage(chatId) ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (chat['lastMessage']?['timestamp'] != null)
                                        Text(
                                          _formatMessageTime(chat['lastMessage']['timestamp']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hasUnread || _isRecentMessage(chatId) ? Colors.black87 : Colors.grey,
                                            fontWeight: hasUnread || _isRecentMessage(chatId) ?  FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    chat['lastMessage']?['message']?.toString() ?? 'No messages yet',
                                    style: TextStyle(
                                      fontWeight: hasUnread || _isRecentMessage(chatId) ? FontWeight.bold : FontWeight.normal,
                                      color: hasUnread || _isRecentMessage(chatId) ? Colors.black87 : Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    log('Tapped chatId: $chatId, resetting unread count');
                                    _markChatAsRead(chatId);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          currentUserId: widget.currentUserId,
                                          currentUserName: widget.currentUserName,
                                          currentUserPicture: widget.currentUserPicture,
                                          currentUserEmail: widget.currentUserEmail,
                                          receiverId: userId,
                                          receiverName: displayName,
                                          receiverPicture: profilePicture,
                                          receiverEmail: email,
                                        ),
                                      ),
                                    ).then((_) {
                                      log('Returned from ChatScreen, refreshing chats');
                                      _fetchChats();
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          FloatingMenuWidget(scaffoldKey: _scaffoldKey),
        ],
      ),
    );
  }

  String _formatMessageTime(String timestamp) {
    try {
      final messageTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      if (now.difference(messageTime).inDays > 0) {
        return '${_getDayName(messageTime)}';
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