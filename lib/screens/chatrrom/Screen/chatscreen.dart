import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/helper/dialogs.dart'; 
import 'package:innovator/screens/chatrrom/Model/chatMessage.dart';
import 'package:innovator/screens/chatrrom/Services/mqtt_services.dart';
import 'package:innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:innovator/screens/chatrrom/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserPicture;
  final String currentUserEmail;
  final String receiverId;
  final String receiverName;
  final String receiverPicture;
  final String receiverEmail;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserPicture,
    required this.currentUserEmail,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPicture,
    required this.receiverEmail,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final MQTTService _mqttService = MQTTService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isInitialized = false;
  String? _chatTopic;
  bool _isSendingMessage = false;
  bool _mqttInitialized = false;

  @override
  void initState() {
    super.initState();
    log('ChatScreen: Initializing with currentUserId=${widget.currentUserId}, receiverId=${widget.receiverId}');
    _loadCachedMessages();
    _fetchMessages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _validateAndSetupMQTT();
      _isInitialized = true;
    }
  }

  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${widget.currentUserId}_${widget.receiverId}';
      final cachedMessages = prefs.getString(cacheKey);
      if (cachedMessages != null) {
        final List<dynamic> jsonMessages = jsonDecode(cachedMessages);
        setState(() {
          _messages.addAll(jsonMessages.map((m) => ChatMessage.fromJson(m)));
        });
        _scrollToBottom();
        log('ChatScreen: Loaded ${_messages.length} cached messages');
      }
    } catch (e) {
      log('ChatScreen: Error loading cached messages: $e');
    }
  }

  Future<void> _cacheMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${widget.currentUserId}_${widget.receiverId}';
      final jsonMessages = _messages.map((m) => m.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonMessages));
      log('ChatScreen: Cached ${_messages.length} messages');
    } catch (e) {
      log('ChatScreen: Error caching messages: $e');
    }
  }

  Future<void> _validateAndSetupMQTT() async {
    if (_mqttInitialized) {
      log('ChatScreen: MQTT already initialized, skipping setup');
      return;
    }

    try {
      if (widget.currentUserId.isEmpty) {
        log('ChatScreen: Cannot setup MQTT: currentUserId is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user ID. Please log in again.')),
        );
        Get.offAll(() => const LoginPage());
        return;
      }

      final token = AppData().authToken;
      if (token == null) {
        log('ChatScreen: Cannot setup MQTT: No auth token available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No auth token. Please log in again.')),
        );
        Get.offAll(() => const LoginPage());
        return;
      }

      await _mqttService.connect(token, widget.currentUserId);
      _chatTopic = _mqttService.getChatTopic(widget.currentUserId, widget.receiverId);
      log('ChatScreen: Initialized chat topic: $_chatTopic');

      _mqttService.initiateChat(
        widget.receiverId,
        {
          'senderName': widget.currentUserName,
          'senderPicture': widget.currentUserPicture,
          'senderEmail': widget.currentUserEmail,
          'receiverName': widget.receiverName,
          'receiverPicture': widget.receiverPicture,
          'receiverEmail': widget.receiverEmail,
        },
        (String payload) {
          try {
            log('ChatScreen: Received MQTT message on chat topic: $payload');
            final message = ChatMessage.fromJson(jsonDecode(payload));
            log('ChatScreen: Parsed message: senderId=${message.senderId}, receiverId=${message.receiverId}, content=${message.content}');
            if ((message.senderId == widget.currentUserId && message.receiverId == widget.receiverId) ||
                (message.senderId == widget.receiverId && message.receiverId == widget.currentUserId)) {
              bool isDuplicate = _messages.any((m) => m.id == message.id);
              if (!isDuplicate) {
                setState(() {
                  _messages.add(message);
                  log('ChatScreen: Added new message to UI: ${message.content}');
                });
                _cacheMessages();
                _scrollToBottom();
                // Mark message as read if received from the other user
                if (message.senderId == widget.receiverId && !message.read) {
                  _markMessageAsRead(message.id);
                }
              } else {
                log('ChatScreen: Ignored duplicate message with id: ${message.id}');
              }
            } else {
              log('ChatScreen: Ignored message with mismatched sender/receiver IDs');
            }
          } catch (e) {
            log('ChatScreen: Error processing MQTT message: $e');
          }
        },
      );

      // Subscribe to user messages topic for additional message updates
      _mqttService.subscribe('user/${widget.currentUserId}/messages', (String payload) {
        try {
          log('ChatScreen: Received MQTT message on user messages topic: $payload');
          final data = jsonDecode(payload);
          if (data['type'] == 'new_message') {
            final message = ChatMessage.fromJson(data['message']);
            if ((message.senderId == widget.currentUserId && message.receiverId == widget.receiverId) ||
                (message.senderId == widget.receiverId && message.receiverId == widget.currentUserId)) {
              bool isDuplicate = _messages.any((m) => m.id == message.id);
              if (!isDuplicate) {
                setState(() {
                  // Replace temporary message if sent by current user
                  final tempIndex = _messages.indexWhere((m) =>
                      m.id.startsWith('temp_') &&
                      m.senderId == message.senderId &&
                      m.content == message.content &&
                      m.timestamp.difference(message.timestamp).inSeconds.abs() < 5);
                  if (tempIndex != -1) {
                    _messages[tempIndex] = message;
                    log('ChatScreen: Replaced temporary message with server message: ${message.id}');
                  } else {
                    _messages.add(message);
                    log('ChatScreen: Added new message from user topic: ${message.content}');
                  }
                });
                _cacheMessages();
                _scrollToBottom();
                if (message.senderId == widget.receiverId && !message.read) {
                  _markMessageAsRead(message.id);
                }
              }
            }
          } else if (data['type'] == 'read_receipt') {
            setState(() {
              final messageId = data['messageId'] as String?;
              if (messageId != null) {
                final messageIndex = _messages.indexWhere((m) => m.id == messageId);
                if (messageIndex != -1) {
                  final message = _messages[messageIndex];
                  message.read = true;
                  message.readAt = DateTime.now();
                  log('ChatScreen: Updated read receipt for message: $messageId');
                } else {
                  log('ChatScreen: No message found for read receipt: $messageId');
                }
              } else {
                log('ChatScreen: Invalid read receipt: messageId is null');
              }
            });
            _cacheMessages();
          }
        } catch (e) {
          log('ChatScreen: Error processing user messages: $e');
        }
      });

      _mqttService.subscribe('user/${widget.currentUserId}/notifications', (String payload) {
        try {
          final notification = jsonDecode(payload);
          log('ChatScreen: Received notification: $notification');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(notification['content'] ?? 'New notification')),
          );
        } catch (e) {
          log('ChatScreen: Error processing notification: $e');
        }
      });

      _mqttInitialized = true;
      log('ChatScreen: MQTT setup completed');
    } catch (e) {
      log('ChatScreen: Error setting up MQTT: $e');
      setState(() {
        _errorMessage = 'Failed to connect to chat service. Please try again.';
      });
    }
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = AppData().authToken;
      if (token == null) {
        log('ChatScreen: No auth token, redirecting to login');
        Get.offAll(() => const LoginPage());
        throw Exception('No auth token available');
      }

      const String baseUrl = 'http://182.93.94.210:3064/api/v1';
      final url = '$baseUrl/messages/${widget.receiverId}';
      log('ChatScreen: Fetching messages from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      log('ChatScreen: Messages API response status: ${response.statusCode}');
      if (response.statusCode == 401) {
        log('ChatScreen: Unauthorized, redirecting to login');
        Get.offAll(() => const LoginPage());
        throw Exception('Session expired. Please log in again.');
      }

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          log('ChatScreen: Empty response body');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final responseData = jsonDecode(response.body);
        log('ChatScreen: Decoded response data: $responseData');

        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final messagesList = responseData['data'];
          if (messagesList is List) {
            setState(() {
              _messages.clear();
              for (var item in messagesList) {
                try {
                  final message = ChatMessage.fromJson(item);
                  if ((message.senderId == widget.currentUserId && message.receiverId == widget.receiverId) ||
                      (message.senderId == widget.receiverId && message.receiverId == widget.currentUserId)) {
                    _messages.add(message);
                  }
                } catch (e) {
                  log('ChatScreen: Error processing message item: $e');
                }
              }
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              _isLoading = false;
            });
            _cacheMessages();
            _scrollToBottom();
            log('ChatScreen: Loaded ${_messages.length} messages from server');
            // Mark unread messages as read
            for (var message in _messages) {
              if (message.senderId == widget.receiverId && !message.read) {
                _markMessageAsRead(message.id);
              }
            }
          } else {
            throw Exception('Invalid response format: data not a list');
          }
        } else {
          throw Exception('Invalid response format: data not found');
        }
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      log('ChatScreen: Error fetching messages: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load messages. Showing cached messages.';
      });
      if (_messages.isNotEmpty) {
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _markMessageAsRead(String messageId) async {
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
      );

      if (response.statusCode == 200) {
        setState(() {
          final messageIndex = _messages.indexWhere((m) => m.id == messageId);
          if (messageIndex != -1) {
            final message = _messages[messageIndex];
            message.read = true;
            message.readAt = DateTime.now();
            log('ChatScreen: Marked message as read: $messageId');
          }
        });
        _cacheMessages();
        _mqttService.publish('user/${widget.receiverId}/messages', {
          'type': 'read_receipt',
          'messageId': messageId,
          'chatTopic': _chatTopic,
        });
      } else {
        log('ChatScreen: Failed to mark message as read, status: ${response.statusCode}');
      }
    } catch (e) {
      log('ChatScreen: Error marking message as read: $e');
    }
  }

  Future<bool> _deleteMessageForMe(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        Get.offAll(() => const LoginPage());
        return false;
      }

      final url = 'http://182.93.94.210:3064/api/v1/message/$messageId/me';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _messages.removeWhere((msg) => msg.id == messageId);
        });
        await _cacheMessages();
        log('ChatScreen: Deleted message for me: $messageId');
        return true;
      }
      return false;
    } catch (e) {
      log('ChatScreen: Error deleting message for me: $e');
      return false;
    }
  }

  Future<bool> _deleteMessageForEveryone(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        Get.offAll(() => const LoginPage());
        return false;
      }

      final url = 'http://182.93.94.210:3064/api/v1/message/$messageId/everyone';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _messages.removeWhere((msg) => msg.id == messageId);
        });
        await _cacheMessages();
        log('ChatScreen: Deleted message for everyone: $messageId');
        return true;
      }
      return false;
    } catch (e) {
      log('ChatScreen: Error deleting message for everyone: $e');
      return false;
    }
  }

  Future<bool> _deleteConversation() async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        Get.offAll(() => const LoginPage());
        return false;
      }

      final url =
          'http://182.93.94.210:3064/api/v1/conversation/${widget.currentUserId}?otherUserId=${widget.receiverId}';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _messages.clear();
        });
        await _cacheMessages();
        log('ChatScreen: Deleted conversation');
        return true;
      }
      return false;
    } catch (e) {
      log('ChatScreen: Error deleting conversation: $e');
      return false;
    }
  }

  void _showDeleteOptions(BuildContext context, ChatMessage message) {
    final isMe = message.senderId == widget.currentUserId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete for me'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await _showConfirmationDialog(
                  context,
                  'Delete Message',
                  'Are you sure you want to delete this message for yourself?',
                );
                if (confirmed) {
                  final success = await _deleteMessageForMe(message.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Message deleted successfully' : 'Failed to delete message'),
                    ),
                  );
                }
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete for everyone'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _showConfirmationDialog(
                    context,
                    'Delete Message',
                    'Are you sure you want to delete this message for everyone?',
                  );
                  if (confirmed) {
                    final success = await _deleteMessageForEveryone(message.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Message deleted for everyone' : 'Failed to delete message'),
                      ),
                    );
                  }
                },
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _sendMessage() async {
    if (_isSendingMessage || _messageController.text.trim().isEmpty || _chatTopic == null) {
      log('ChatScreen: Cannot send message: ' +
          (_isSendingMessage
              ? 'Already sending'
              : _messageController.text.trim().isEmpty
                  ? 'Empty message'
                  : 'Null chat topic'));
      return;
    }

    _isSendingMessage = true;
    try {
      final messageContent = _messageController.text.trim();
      _messageController.clear();

      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${widget.currentUserId}';
      final message = ChatMessage(
        id: tempId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        senderPicture: widget.currentUserPicture,
        senderEmail: widget.currentUserEmail,
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        receiverPicture: widget.receiverPicture,
        receiverEmail: widget.receiverEmail,
        content: messageContent,
        timestamp: DateTime.now(),
        read: false,
        readAt: null,
      );

      setState(() {
        _messages.add(message);
        log('ChatScreen: Added temporary message to UI: $tempId');
      });
      _cacheMessages();
      _scrollToBottom();

      final payload = {
        'sender': {
          '_id': widget.currentUserId,
          'email': widget.currentUserEmail,
          'name': widget.currentUserName,
          'picture': widget.currentUserPicture,
        },
        'receiver': {
          '_id': widget.receiverId,
          'email': widget.receiverEmail,
          'name': widget.receiverName,
          'picture': widget.receiverPicture,
        },
        'message': messageContent,
        'timestamp': message.timestamp.toIso8601String(),
      };

      log('ChatScreen: Sending message to topic: $_chatTopic');
      await _mqttService.publish(_chatTopic!, payload);
      SoundPlayer().playSound();
    } catch (e) {
      log('ChatScreen: Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message. Please try again.')),
      );
      setState(() {
        _messages.removeWhere((m) => m.id.startsWith('temp_'));
      });
      _cacheMessages();
    } finally {
      _isSendingMessage = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        log('ChatScreen: Scrolled to bottom');
      }
    });
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.receiverName.isNotEmpty ? widget.receiverName : 'Unknown';
    final profilePicture = _isValidImageUrl(widget.receiverPicture) ? widget.receiverPicture : '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
        elevation: 0,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 2),
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[200],
              child: Utils.isValidImageUrl(profilePicture)
                  ? ClipOval(
                      child: Image.network(
                        Utils.getImageUrl(profilePicture),
                        fit: BoxFit.cover,
                        width: 28,
                        height: 28,
                        errorBuilder: (context, error, stackTrace) => Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                  : Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    ),
            ),
          ],
        ),
        leadingWidth: 80,
        title: Text(
          displayName,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: () async {
              final confirmed = await _showConfirmationDialog(
                context,
                'Delete Conversation',
                'Are you sure you want to delete this entire conversation? This action cannot be undone.',
              );
              if (confirmed) {
                final success = await _deleteConversation();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Conversation deleted successfully' : 'Failed to delete conversation'),
                  ),
                );
              }
            },
            tooltip: 'Delete conversation',
          ),
        ],
      ),
      body: Container(
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
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.amber[100],
                width: double.infinity,
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.amber[900]),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet. Start the conversation!',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.senderId == widget.currentUserId;
                            final messageTime =
                                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

                            return GestureDetector(
                              onLongPress: () => _showDeleteOptions(context, message),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? const Color.fromRGBO(220, 248, 198, 1)
                                              : Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomLeft: Radius.circular(isMe ? 12 : 0),
                                            bottomRight: Radius.circular(isMe ? 0 : 12),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(12, 15, 60, 15),
                                              child: Text(
                                                message.content,
                                                style: const TextStyle(color: Colors.black, fontSize: 16),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              right: 8,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    messageTime,
                                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                                  ),
                                                  if (isMe) ...[
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      message.read ? Icons.done_all : Icons.done,
                                                      size: 16,
                                                      color: message.read ? Colors.blue : Colors.grey,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) {
                                if (!_isSendingMessage) _sendMessage();
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Colors.grey),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSendingMessage ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _mqttService.disconnect();
    super.dispose();
  }
}