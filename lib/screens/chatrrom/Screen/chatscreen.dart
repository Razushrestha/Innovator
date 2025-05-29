import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/chatrrom/Model/chatMessage.dart';
import 'package:innovator/screens/chatrrom/utils.dart';
import 'package:intl/intl.dart';
import 'chat_controller.dart'; // Import the controller

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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
    Timer? _debounceTimer;

  @override
  Widget build(BuildContext context) {
    // Initialize controller with proper tag
    final controllerTag = '${widget.currentUserId}_${widget.receiverId}';

    // Get or create controller without initializing data in build
    final ChatController controller = Get.put(
      ChatController(),
      tag: controllerTag,
    );

    // Initialize chat data only once, not during every build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isInitialized.value) {
        controller.initializeChat(
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
          currentUserPicture: widget.currentUserPicture,
          currentUserEmail: widget.currentUserEmail,
          receiverId: widget.receiverId,
          receiverName: widget.receiverName,
          receiverPicture: widget.receiverPicture,
          receiverEmail: widget.receiverEmail,
        );
      }
    });

    final displayName = widget.receiverName.isNotEmpty ? widget.receiverName : 'Unknown';
    final profilePicture =
        _isValidImageUrl(widget.receiverPicture) ? widget.receiverPicture : '';

    return PopScope(
      canPop: false, // Prevents default pop unless explicitly allowed
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          _handleBackPress(controller);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
          elevation: 0,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => _handleBackPress(controller),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 2),
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[200],
                child:
                    Utils.isValidImageUrl(profilePicture)
                        ? ClipOval(
                          child: Image.network(
                            Utils.getImageUrl(profilePicture),
                            fit: BoxFit.cover,
                            width: 28,
                            height: 28,
                            errorBuilder:
                                (context, error, stackTrace) => Text(
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
              onPressed: () => _handleDeleteConversation(context, controller),
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
              // Error message banner
              Obx(() {
                final errorMsg = controller.errorMessage.value;
                if (errorMsg.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.amber[100],
                    width: double.infinity,
                    child: Text(
                      errorMsg,
                      style: TextStyle(color: Colors.amber[900]),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Messages list
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller.scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      return _buildMessageBubble(context, message, controller);
                    },
                  );
                }),
              ),

              // Input field
              _buildInputField(controller),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildMessageBubble(
  BuildContext context,
  ChatMessage message,
  ChatController controller,
) {
  final isMe = message.senderId == widget.currentUserId;
  final messageTime = DateFormat('HH:mm').format(message.timestamp.toLocal());

  return GestureDetector(
    key: ValueKey(message.id), // Add unique key
    onLongPress: () => _showDeleteOptions(context, message, controller),
    child: Container(
      margin: EdgeInsets.only(
        left: isMe ? 64 : 8,
        right: isMe ? 8 : 64,
        top: 2,
        bottom: 2,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: isMe 
                ? const Color(0xFFDCF8C6) // WhatsApp sent green
                : Colors.white, // WhatsApp received white
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(7.5),
              topRight: const Radius.circular(7.5),
              bottomLeft: Radius.circular(isMe ? 7.5 : 2),
              bottomRight: Radius.circular(isMe ? 2 : 7.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                offset: const Offset(0, 1),
                blurRadius: 0.5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Message text
              Container(
                padding: EdgeInsets.fromLTRB(
                  7,
                  6,
                  7 + (messageTime.length * 4.2) + (isMe ? 20 : 0),
                  17,
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF303030),
                    height: 1.19,
                    letterSpacing: -0.078,
                  ),
                ),
              ),
              
              // Time and status
              Positioned(
                bottom: 4,
                right: 7,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      messageTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.45),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(
                        message.read ? Icons.done_all : Icons.done,
                        size: 16,
                        color: message.read 
                            ? const Color(0xFF4FC3F7)
                            : const Color(0xFF92A3A3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildInputField(ChatController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: controller.messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(244, 135, 6, 1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon:
                      controller.isSendingMessage.value
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(Icons.send, color: Colors.white),
                  onPressed:
                      controller.isSendingMessage.value
                          ? null
                          : () => _debounceSend(controller),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

void _debounceSend(ChatController controller) {
  if (_debounceTimer?.isActive ?? false) return;
  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
    controller.sendMessage();
  });
}

  void _handleDeleteConversation(
    BuildContext context,
    ChatController controller,
  ) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Conversation',
      'Are you sure you want to delete this entire conversation? This action cannot be undone.',
    );
    if (confirmed) {
      final success = await controller.deleteConversation();
      if (context.mounted) {
        Get.snackbar(
          success ? 'Success' : 'Error',
          success
              ? 'Conversation deleted successfully'
              : 'Failed to delete conversation',
          backgroundColor: success ? Colors.green : Colors.red,
          colorText: Colors.white,
        );
        if (success) {
          _handleBackPress(controller);
        }
      }
    }
  }

  void _showDeleteOptions(
    BuildContext context,
    ChatMessage message,
    ChatController controller,
  ) {
    if (message.senderId != widget.currentUserId)
      return; // Only allow deleting own messages

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Message',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.orange,
                  ),
                  title: const Text('Delete for me'),
                  subtitle: const Text('Message will be deleted only for you'),
                  onTap: () => _handleDeleteForMe(context, message, controller),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete for everyone'),
                  subtitle: const Text(
                    'Message will be deleted for both of you',
                  ),
                  onTap:
                      () => _handleDeleteForEveryone(
                        context,
                        message,
                        controller,
                      ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _handleDeleteForMe(
    BuildContext context,
    ChatMessage message,
    ChatController controller,
  ) async {
    Navigator.pop(context);
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Message',
      'Delete this message for you only?',
    );
    if (confirmed) {
      final success = await controller.deleteMessageForMe(message.id);
      if (context.mounted) {
        Get.snackbar(
          success ? 'Success' : 'Error',
          success ? 'Message deleted for you' : 'Failed to delete message',
          backgroundColor: success ? Colors.green : Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _handleDeleteForEveryone(
    BuildContext context,
    ChatMessage message,
    ChatController controller,
  ) async {
    Navigator.pop(context);
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Message',
      'Delete this message for everyone? This action cannot be undone.',
    );
    if (confirmed) {
      final success = await controller.deleteMessageForEveryone(message.id);
      if (context.mounted) {
        Get.snackbar(
          success ? 'Success' : 'Error',
          success ? 'Message deleted for everyone' : 'Failed to delete message',
          backgroundColor: success ? Colors.green : Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

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
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return Uri.tryParse(url) != null;
  }

  void _handleBackPress(ChatController controller) {
    final controllerTag = '${widget.currentUserId}_${widget.receiverId}';

    // Navigate back first
    if (Get.context != null) {
      Navigator.pop(Get.context!);
    }

    // Then clean up controller after navigation
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.delete<ChatController>(tag: controllerTag, force: true);
    });
  }
}


// // Custom painter for WhatsApp message tails
// class MessageTailPainter extends CustomPainter {
//   final Color color;
//   final bool isMe;

//   MessageTailPainter({required this.color, required this.isMe});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.fill;

//     final path = Path();
    
//     if (isMe) {
//       // Tail for sent messages (right side)
//       path.moveTo(0, 0);
//       path.lineTo(0, 10);
//       path.quadraticBezierTo(0, 15, 6, 15);
//       path.quadraticBezierTo(12, 15, 12, 8);
//       path.quadraticBezierTo(12, 0, 6, 0);
//       path.close();
//     } else {
//       // Tail for received messages (left side)
//       path.moveTo(12, 0);
//       path.lineTo(12, 10);
//       path.quadraticBezierTo(12, 15, 6, 15);
//       path.quadraticBezierTo(0, 15, 0, 8);
//       path.quadraticBezierTo(0, 0, 6, 0);
//       path.close();
//     }

//     canvas.drawPath(path, paint);
    
//     // Add shadow to tail
//     final shadowPaint = Paint()
//       ..color = Colors.black.withOpacity(0.13)
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    
//     canvas.drawPath(path, shadowPaint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
