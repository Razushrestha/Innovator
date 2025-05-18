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

  // Added to track if a message is currently being sent
  bool _isSendingMessage = false;
  // Added to track if MQTT has been initialized
  bool _mqttInitialized = false;

  @override
  void initState() {
    super.initState();
    log(
      'ChatScreen init: currentUserId=${widget.currentUserId}, receiverId=${widget.receiverId}',
    );
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
      }
    } catch (e) {
      log('Error loading cached messages: $e');
    }
  }

  Future<void> _cacheMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${widget.currentUserId}_${widget.receiverId}';
      final jsonMessages = _messages.map((m) => m.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonMessages));
    } catch (e) {
      log('Error caching messages: $e');
    }
  }

  Future<void> _validateAndSetupMQTT() async {
    // Prevent multiple MQTT initializations
    if (_mqttInitialized) {
      log('MQTT already initialized, skipping setup');
      return;
    }

    try {
      if (widget.currentUserId.isEmpty) {
        log('Cannot setup MQTT: currentUserId is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid user ID. Please log in again.'),
          ),
        );
        Get.offAll(() => const LoginPage());
        return;
      }

      final token = AppData().authToken;
      if (token == null) {
        log('Cannot setup MQTT: No auth token available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No auth token. Please log in again.')),
        );
        Get.offAll(() => const LoginPage());
        return;
      }

      // Connect to MQTT
      await _mqttService.connect(token, widget.currentUserId);

      // Initiate chat
      _chatTopic = _mqttService.getChatTopic(
        widget.currentUserId,
        widget.receiverId,
      );
      log('Chat topic initialized: $_chatTopic');

      _mqttService.initiateChat(
        widget.receiverId,
        {
          'senderId': widget.currentUserId,
          'senderName': widget.currentUserName,
          'senderPicture': widget.currentUserPicture,
          'senderEmail': widget.currentUserEmail,
          'receiverId': widget.receiverId,
          'receiverName': widget.receiverName,
          'receiverPicture': widget.receiverPicture,
          'receiverEmail': widget.receiverEmail,
        },
        (String payload) {
          try {
            final message = ChatMessage.fromJson(jsonDecode(payload));
            if ((message.senderId == widget.receiverId &&
                    message.receiverId == widget.currentUserId) ||
                (message.senderId == widget.currentUserId &&
                    message.receiverId == widget.receiverId)) {
              // Check for duplicate messages (optional) by comparing the message ID
              bool isDuplicate = _messages.any((m) => m.id == message.id);
              if (!isDuplicate) {
                setState(() {
                  _messages.add(message);
                });
                _cacheMessages();
                _scrollToBottom();
              } else {
                log('Ignoring duplicate message with ID: ${message.id}');
              }
            }
          } catch (e) {
            log('Error processing MQTT message: $e');
          }
        },
      );

      // Subscribe to notifications
      _mqttService.subscribe('user/${widget.currentUserId}/notifications', (
        String payload,
      ) {
        try {
          final notification = jsonDecode(payload);
          log('Received notification: $notification');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(notification['content'])));
        } catch (e) {
          log('Error processing notification: $e');
        }
      });

      // Mark MQTT as initialized
      _mqttInitialized = true;
    } catch (e) {
      log('Error setting up MQTT: $e');
      setState(() {
        _errorMessage =
            'Failed to connect to chat service. Please restart the app.';
      });
    }
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.currentUserId.isEmpty || widget.receiverId.isEmpty) {
        throw Exception('Invalid user or receiver ID');
      }

      final token = AppData().authToken;
      if (token == null) {
        Get.offAll(() => const LoginPage());
        throw Exception('No auth token available');
      }

      const String baseUrl = 'http://182.93.94.210:3064/api/v1';

      // Update URL format -  API only requires the receiver ID
      final url = '$baseUrl/messages/${widget.receiverId}';

      log('Fetching messages from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      log('Messages API Response Status Code: ${response.statusCode}');

      // Print a small sample of the response body for debugging
      if (response.body.isNotEmpty) {
        log(
          'Response body sample: ${response.body.substring(0, min(100, response.body.length))}',
        );
      }

      if (response.statusCode == 401) {
        Get.offAll(() => const LoginPage());
        throw Exception('Session expired. Please log in again.');
      }

      if (response.statusCode == 200) {
        // Add explicit check for response body content
        if (response.body.isEmpty) {
          log('Response body is empty');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        try {
          final responseData = jsonDecode(response.body);
          log('Decoded response data: $responseData');

          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('data')) {
            final messagesList = responseData['data'];

            if (messagesList is List) {
              setState(() {
                _messages.clear();

                // Convert API response format to ChatMessage format
                for (var item in messagesList) {
                  try {
                    // Only process messages where either sender or receiver matches current user ID
                    final String senderId = item['sender']['_id'] ?? '';
                    final String receiverId = item['receiver']['_id'] ?? '';

                    // Filter messages that belong to this conversation
                    if ((senderId == widget.currentUserId &&
                            receiverId == widget.receiverId) ||
                        (senderId == widget.receiverId &&
                            receiverId == widget.currentUserId)) {
                      // Create a ChatMessage from the API response format
                      final message = ChatMessage(
                        id: item['_id'] ?? '',
                        senderId: senderId,
                        senderName: item['sender']['name'] ?? '',
                        senderPicture: item['sender']['picture'] ?? '',
                        senderEmail: item['sender']['email'] ?? '',
                        receiverId: receiverId,
                        receiverName: item['receiver']['name'] ?? '',
                        receiverPicture: item['receiver']['picture'] ?? '',
                        receiverEmail: item['receiver']['email'] ?? '',
                        content: item['message'] ?? '',
                        timestamp:
                            item['createdAt'] != null
                                ? DateTime.parse(item['createdAt'])
                                : DateTime.now(),
                        read: item['read'] ?? false,
                      );

                      _messages.add(message);
                    }
                  } catch (itemError) {
                    log('Error processing message item: $itemError');
                    // Continue processing other messages
                  }
                }

                // Sort messages by timestamp
                _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                _isLoading = false;
              });
              _cacheMessages();
              _scrollToBottom();

              // Log success message
              log('Successfully loaded ${_messages.length} messages');
              return;
            }
          }

          // If we reach here, the response format wasn't as expected
          throw Exception(
            'Invalid response format: data not found or not a list',
          );
        } catch (parseError) {
          log('Error parsing JSON response: $parseError');
          throw Exception('Failed to parse server response: $parseError');
        }
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching messages: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load messages. Showing cached messages.';
      });
      if (_messages.isNotEmpty) {
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }

  Future<void> _sendMessage() async {
  if (_isSendingMessage ||
      _messageController.text.trim().isEmpty ||
      _chatTopic == null) {
    log('Cannot send message: ' +
        (_isSendingMessage
            ? 'Already sending message'
            : _messageController.text.trim().isEmpty
                ? 'Empty message'
                : 'Null chat topic'));
    return;
  }

  // Validate required fields
  if (widget.currentUserId.isEmpty ||
      widget.currentUserEmail.isEmpty ||
      widget.currentUserName.isEmpty ||
      widget.receiverId.isEmpty ||
      widget.receiverEmail.isEmpty ||
      widget.receiverName.isEmpty) {
    log('Invalid user data: One or more required fields are empty');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid user data. Please log in again.')),
    );
    Get.offAll(() => const LoginPage());
    return;
  }

  _isSendingMessage = true;
  try {
    final messageContent = _messageController.text.trim();
    _messageController.clear();

    final uniqueId =
        DateTime.now().millisecondsSinceEpoch.toString() +
        '_${widget.currentUserId.substring(0, min(5, widget.currentUserId.length))}';

    final message = ChatMessage(
      id: uniqueId,
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
    );

    setState(() {
      _messages.add(message);
    });
    _cacheMessages();
    _scrollToBottom();

    final payload = {
      'sender': {
        '_id': widget.currentUserId,
        'email': widget.currentUserEmail,
        'name': widget.currentUserName,
        'picture': widget.currentUserPicture ?? '',
      },
      'receiver': {
        '_id': widget.receiverId,
        'email': widget.receiverEmail,
        'name': widget.receiverName,
        'picture': widget.receiverPicture ?? '',
      },
      'message': messageContent,
      'timestamp': message.timestamp.toIso8601String(),
    };

    log('Sending message to topic: $_chatTopic with payload: $payload');
    await _mqttService.publish(_chatTopic!, payload);
    await Future.delayed(const Duration(milliseconds: 300));
  } catch (e) {
    log('Error sending message: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to send message. Please try again.')),
    );
    setState(() {
      _messages.removeLast();
    });
    _cacheMessages();
  } finally {
    _isSendingMessage = false;
  }
  SoundPlayer player = SoundPlayer();
  player.playSound();
}

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        widget.receiverName.isNotEmpty ? widget.receiverName : 'Unknown';
    final profilePicture =
        _isValidImageUrl(widget.receiverPicture) ? widget.receiverPicture : '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : null,
              child:
                  profilePicture.isEmpty
                      ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 20),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
            Text(displayName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMessages,
            tooltip: 'Refresh messages',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.amber[100],
              width: double.infinity,
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.amber[900]),
              ),
            ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? const Center(
                      child: Text('No messages yet. Start the conversation!'),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == widget.currentUserId;
                        final messagePicture =
                            isMe
                                ? widget.currentUserPicture
                                : widget.receiverPicture;
                        final displayPicture =
                            _isValidImageUrl(messagePicture)
                                ? messagePicture
                                : '';

                        final messageTime =
                            '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        messageTime,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isMe
                                                  ? Colors.white70
                                                  : Colors.black54,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          message.read
                                              ? Icons.done_all
                                              : Icons.done,
                                          size: 14,
                                          color:
                                              message.read
                                                  ? Colors.white
                                                  : Colors.white70,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!_isSendingMessage) {
                        _sendMessage();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () {
                    if (!_isSendingMessage) {
                      _sendMessage();
                    }
                  },
                  child: Icon(
                    _isSendingMessage ? Icons.hourglass_empty : Icons.send,
                  ),
                  mini: true,
                ),
              ],
            ),
          ),
        ],
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
