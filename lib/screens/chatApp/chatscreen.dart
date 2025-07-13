import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:lottie/lottie.dart';
import 'dart:developer' as developer;

class OptimizedChatScreen extends GetView<FireChatController> {
  final Map<String, dynamic> receiverUser;
  final Map<String, dynamic>? currentUser;

  const OptimizedChatScreen({
    Key? key,
    required this.receiverUser,
    this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController messageController = TextEditingController();
    final ScrollController scrollController = ScrollController();
    final FocusNode messageFocusNode = FocusNode();
    
    final safeCurrentUser = currentUser ?? controller.currentUser.value ?? {};
    
    final String chatId = controller.generateChatId(
      safeCurrentUser['_id']?.toString() ?? 
      safeCurrentUser['uid']?.toString() ?? '',
      receiverUser['userId']?.toString() ?? 
      receiverUser['_id']?.toString() ?? 
      receiverUser['uid']?.toString() ?? '',
    );
    
    if (chatId.isNotEmpty) {
      controller.loadMessages(chatId);
      // Mark messages as read when entering chat
      controller.markMessagesAsRead(chatId);
    }
    
    scrollController.addListener(() {
      controller.onScrollChanged(
        scrollController.position.pixels,
        scrollController.position.maxScrollExtent,
      );
    });

    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList(scrollController)),
          _buildMessageInput(messageController, messageFocusNode, chatId),
        ],
      ),
      floatingActionButton: _buildScrollToBottomFab(scrollController),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final receiverName = receiverUser['name']?.toString() ?? 'Unknown User';
    final receiverPhoto = receiverUser['photoURL']?.toString();
    final isOnline = receiverUser['isOnline'] == true;

    return AppBar(
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: InkWell(
        onTap: () => _showUserProfile(),
        child: Row(
          children: [
            Hero(
              tag: 'user_avatar_${receiverUser['id'] ?? receiverUser['userId'] ?? 'unknown'}',
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage: receiverPhoto != null && receiverPhoto.isNotEmpty
                          ? NetworkImage(receiverPhoto)
                          : null,
                      child: receiverPhoto == null || receiverPhoto.isEmpty
                          ? Text(
                              receiverName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Color.fromRGBO(244, 135, 6, 1),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(() {
                    if (controller.isTyping.value) {
                      return const Text(
                        'typing...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          onPressed: () => _showComingSoon('Video call'),
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          onPressed: () => _showComingSoon('Voice call'),
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear_chat',
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 20),
                  SizedBox(width: 8),
                  Text('Clear Chat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block_user',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Block User'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'clear_chat') {
              _showClearChatDialog();
            } else if (value == 'block_user') {
              _showBlockUserDialog();
            }
          },
        ),
      ],
    );
  }

  Widget _buildMessagesList(ScrollController scrollController) {
    return Obx(() {
      if (controller.isLoadingMessages.value && controller.messages.isEmpty) {
        return _buildLoadingMessages();
      }

      if (controller.messages.isEmpty) {
        return _buildEmptyChat();
      }

      return ListView.builder(
        controller: scrollController,
        reverse: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final message = controller.messages[index];
          final previousMessage = index < controller.messages.length - 1
              ? controller.messages[index + 1]
              : null;
          
          return _buildMessageBubble(message, previousMessage, index);
        },
      );
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, Map<String, dynamic>? previousMessage, int index) {
    final safeCurrentUser = currentUser ?? controller.currentUser.value ?? {};
    final currentUserId = safeCurrentUser['_id']?.toString() ?? 
                         safeCurrentUser['uid']?.toString() ?? '';
    
    final isMe = message['senderId']?.toString() == currentUserId;
    final timestamp = message['timestamp'] as Timestamp?;
    final messageTime = timestamp?.toDate();
    final isSending = message['isSending'] == true;
    final messageId = message['id']?.toString() ?? '';
    
    bool showDateSeparator = false;
    if (previousMessage != null) {
      final prevTimestamp = previousMessage['timestamp'] as Timestamp?;
      final prevMessageTime = prevTimestamp?.toDate();
      
      if (messageTime != null && prevMessageTime != null) {
        showDateSeparator = !_isSameDay(messageTime, prevMessageTime);
      }
    } else if (index == controller.messages.length - 1) {
      showDateSeparator = true;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            children: [
              if (showDateSeparator && messageTime != null)
                _buildDateSeparator(messageTime),
              
              Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe) ...[
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                        backgroundImage: receiverUser['photoURL']?.toString() != null &&
                                        receiverUser['photoURL'].toString().isNotEmpty
                            ? NetworkImage(receiverUser['photoURL'].toString())
                            : null,
                        child: receiverUser['photoURL']?.toString() == null ||
                               receiverUser['photoURL'].toString().isEmpty
                            ? Text(
                                (receiverUser['name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: Get.width * 0.75,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onLongPress: () => _showMessageOptions(message),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color.fromRGBO(244, 135, 6, 1)
                                    : Get.theme.cardColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['message']?.toString() ?? '',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Get.theme.textTheme.bodyLarge?.color,
                                      fontSize: 16,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        controller.formatMessageTime(timestamp),
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        // ENHANCED: Real-time blue tick with animation
                                        _buildMessageStatusIcon(messageId, isSending, message),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                        backgroundImage: safeCurrentUser['photoURL']?.toString() != null &&
                                        safeCurrentUser['photoURL'].toString().isNotEmpty
                            ? NetworkImage(safeCurrentUser['photoURL'].toString())
                            : null,
                        child: safeCurrentUser['photoURL']?.toString() == null ||
                               safeCurrentUser['photoURL'].toString().isEmpty
                            ? Text(
                                (safeCurrentUser['name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // NEW: Enhanced message status icon with real-time updates
  Widget _buildMessageStatusIcon(String messageId, bool isSending, Map<String, dynamic> message) {
    if (isSending) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1,
          color: Colors.white.withOpacity(0.7),
        ),
      );
    }

    return Obx(() {
      final status = controller.getMessageStatus(messageId);
      final isRead = message['isRead'] == true;
      
      // Real-time status based on message data and controller status
      if (isRead || status == 'read') {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, animValue, child) {
            return Transform.scale(
              scale: 0.8 + (0.4 * animValue),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Color.lerp(Colors.white.withOpacity(0.7), Colors.blue, animValue)!,
                    Color.lerp(Colors.white.withOpacity(0.7), Colors.lightBlue, animValue)!,
                  ],
                ).createShader(bounds),
                child: Icon(
                  Icons.done_all,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      } else if (status == 'delivered') {
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white.withOpacity(0.7),
        );
      } else {
        return Icon(
          Icons.done,
          size: 14,
          color: Colors.white.withOpacity(0.7),
        );
      }
    });
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String dateText;
    
    if (_isSameDay(date, now)) {
      dateText = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(TextEditingController messageController, FocusNode messageFocusNode, String chatId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Get.theme.cardColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: messageController,
                  focusNode: messageFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  maxLines: 5,
                  minLines: 1,
                  onChanged: (value) {
                    controller.setTyping(value.trim().isNotEmpty);
                  },
                  onSubmitted: (value) {
                    _sendMessage(messageController, chatId);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: controller.isTyping.value
                      ? const Color.fromRGBO(244, 135, 6, 1)
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (controller.isTyping.value
                              ? const Color.fromRGBO(244, 135, 6, 1)
                              : Colors.grey.shade400)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: controller.isTyping.value
                        ? () => _sendMessage(messageController, chatId)
                        : null,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Obx(() {
                        if (controller.isSendingMessage.value) {
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          );
                        }
                        return const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 24,
                        );
                      }),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollToBottomFab(ScrollController scrollController) {
    return Obx(() {
      if (!controller.showScrollToBottom.value) return const SizedBox.shrink();
      
      return Positioned(
        bottom: 100,
        right: 16,
        child: FloatingActionButton.small(
          onPressed: () {
            scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
          backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
          child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ),
      );
    });
  }

  Widget _buildLoadingMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(TextEditingController messageController, String chatId) {
    final message = messageController.text.trim();
    if (message.isEmpty || chatId.isEmpty) return;

    messageController.clear();
    controller.setTyping(false);
    
    HapticFeedback.lightImpact();

    final receiverId = receiverUser['userId']?.toString() ?? 
                      receiverUser['_id']?.toString() ?? 
                      receiverUser['uid']?.toString() ?? '';

    if (receiverId.isNotEmpty) {
      controller.sendMessage(
        receiverId: receiverId,
        message: message,
      );
    } else {
      Get.snackbar(
        'Error',
        'Unable to send message: Invalid receiver',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _showUserProfile() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
              backgroundImage: receiverUser['photoURL']?.toString() != null &&
                              receiverUser['photoURL'].toString().isNotEmpty
                  ? NetworkImage(receiverUser['photoURL'].toString())
                  : null,
              child: receiverUser['photoURL']?.toString() == null ||
                     receiverUser['photoURL'].toString().isEmpty
                  ? Text(
                      (receiverUser['name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              receiverUser['name']?.toString() ?? 'Unknown User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              receiverUser['email']?.toString() ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message['message']?.toString() ?? ''));
                Get.back();
                Get.snackbar('Copied', 'Message copied to clipboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Get.back();
                // Implement reply functionality
              },
            ),
            if (_isMyMessage(message))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  // Implement delete functionality
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _isMyMessage(Map<String, dynamic> message) {
    final safeCurrentUser = currentUser ?? controller.currentUser.value ?? {};
    final currentUserId = safeCurrentUser['_id']?.toString() ?? 
                         safeCurrentUser['uid']?.toString() ?? '';
    return message['senderId']?.toString() == currentUserId;
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      'Coming Soon',
      '$feature feature will be available soon!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      colorText: Colors.white,
    );
  }

  void _showClearChatDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear this chat?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Implement clear chat functionality
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${receiverUser['name']?.toString() ?? 'this user'}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Implement block user functionality
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}