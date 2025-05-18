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

      await _mqttService.connect(token, widget.currentUserId);
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

                for (var item in messagesList) {
                  try {
                    final String senderId = item['sender']['_id'] ?? '';
                    final String receiverId = item['receiver']['_id'] ?? '';

                    if ((senderId == widget.currentUserId &&
                            receiverId == widget.receiverId) ||
                        (senderId == widget.receiverId &&
                            receiverId == widget.currentUserId)) {
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
                  }
                }

                _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                _isLoading = false;
              });
              _cacheMessages();
              _scrollToBottom();
              log('Successfully loaded ${_messages.length} messages');
              return;
            }
          }

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

  // Delete message for me
  Future<bool> _deleteMessageForMe(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        Get.offAll(() => const LoginPage());
        return false;
      }

      final url =
          'https://grok.com/share/bGVnYWN5_fab67b61-97a9-4478-9205-61b5d5ae66d9';
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
        return true;
      }
      return false;
    } catch (e) {
      log('Error deleting message for me: $e');
      return false;
    }
  }

  // Delete message for everyone
  Future<bool> _deleteMessageForEveryone(String messageId) async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        Get.offAll(() => const LoginPage());
        return false;
      }

      final url =
          'http://182.93.94.210:3064/api/v1/message/$messageId/everyone';
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
        return true;
      }
      return false;
    } catch (e) {
      log('Error deleting message for everyone: $e');
      return false;
    }
  }

  // Delete entire conversation
  Future<bool> _deleteConversation() async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        log('No auth token available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
          ),
        );
        Get.offAll(() => const LoginPage());
        return false;
      }

      final url =
          'http://182.93.94.210:3065/api/v1/conversation/${widget.currentUserId}?otherUserId=${widget.receiverId}';
      log('Deleting conversation at URL: $url');
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      log(
        'Delete response: Status ${response.statusCode}, Body: ${response.body}',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _messages.clear();
        });
        await _cacheMessages();
        return true;
      } else {
        log('Failed to delete: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('Error deleting conversation: $e');
      return false;
    }
  }

  // Show delete options dialog
  void _showDeleteOptions(BuildContext context, ChatMessage message) {
    final isMe = message.senderId == widget.currentUserId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
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
                          content: Text(
                            success
                                ? 'Message deleted successfully'
                                : 'Failed to delete message',
                          ),
                        ),
                      );
                    }
                  },
                ),
                if (isMe)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text('Delete for everyone'),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirmed = await _showConfirmationDialog(
                        context,
                        'Delete Message',
                        'Are you sure you want to delete this message for everyone?',
                      );
                      if (confirmed) {
                        final success = await _deleteMessageForEveryone(
                          message.id,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Message deleted for everyone'
                                  : 'Failed to delete message',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Show confirmation dialog
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(title),
                content: Text(content),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  int min(int a, int b) => a < b ? a : b;

  Future<void> _sendMessage() async {
    _fetchMessages();

    if (_isSendingMessage ||
        _messageController.text.trim().isEmpty ||
        _chatTopic == null) {
      log(
        'Cannot send message: ' +
            (_isSendingMessage
                ? 'Already sending message'
                : _messageController.text.trim().isEmpty
                ? 'Empty message'
                : 'Null chat topic'),
      );
      return;
    }

    if (widget.currentUserId.isEmpty ||
        widget.currentUserEmail.isEmpty ||
        widget.currentUserName.isEmpty ||
        widget.receiverId.isEmpty ||
        widget.receiverEmail.isEmpty ||
        widget.receiverName.isEmpty) {
      log('Invalid user data: One or more required fields are empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid user data. Please log in again.'),
        ),
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
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
        ),
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
      backgroundColor: Colors.grey[100], // Light base for WhatsApp-like feel
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(244, 135, 6, 1),
        elevation: 0,
        leading: Row(
          mainAxisSize: MainAxisSize.min, // Ensure Row takes only needed space
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero, // Minimize padding
              constraints: const BoxConstraints(), // Remove default constraints
            ),
            const SizedBox(width: 2), // Reduced from 4 to 2
            CircleAvatar(
              radius: 14, // Reduced from 16 to 14
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      )
                      : null,
            ),
          ],
        ),
        leadingWidth: 80, // Kept to accommodate content
        title: Text(
          displayName,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMessages,
            tooltip: 'Refresh messages',
          ),
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

                if (success) {
                  Dialogs.showSnackbar(
                    context,
                    "Message Deleted Successfully 👋",
                  );
                } else {
                  Dialogs.showSnackbar(
                    context,
                    "Message Cannot Be Deleted Due to Sever Problem 😔",
                  );
                }
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
                ),
              ),
            Expanded(
              child:
                  _isLoading
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == widget.currentUserId;
                          final messageTime =
                              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

                          return GestureDetector(
                            onLongPress:
                                () => _showDeleteOptions(context, message),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    isMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.75,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isMe
                                                ? const Color.fromRGBO(
                                                  220,
                                                  248,
                                                  198,
                                                  1,
                                                )
                                                : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(12),
                                          topRight: const Radius.circular(12),
                                          bottomLeft: Radius.circular(
                                            isMe ? 12 : 0,
                                          ),
                                          bottomRight: Radius.circular(
                                            isMe ? 0 : 12,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              12,
                                              15,
                                              60,
                                              15,
                                            ),
                                            child: Text(
                                              message.content,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            right: 8,
                                            child: Row(
                                              children: [
                                                Text(
                                                  messageTime,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                if (isMe) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    message.read
                                                        ? Icons.done_all
                                                        : Icons.done,
                                                    size: 16,
                                                    color:
                                                        message.read
                                                            ? Colors.blue
                                                            : Colors.grey,
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
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
                          IconButton(
                            icon: const Icon(
                              Icons.emoji_emotions_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.attach_file,
                              color: Colors.grey,
                            ),
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
                      icon: Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: () async{
                        if (!_isSendingMessage){
                          _sendMessage();
                          await _fetchMessages();
                        }
                      },
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
