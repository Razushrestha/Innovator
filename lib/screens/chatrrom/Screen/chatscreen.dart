// screens/chatrrom/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/chatrrom/Model/chatMessage.dart';
import 'package:innovator/screens/chatrrom/Screen/chat_controller.dart';
import 'package:innovator/screens/chatrrom/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ChatController controller = Get.put(ChatController(
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      currentUserPicture: currentUserPicture,
      currentUserEmail: currentUserEmail,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverPicture: receiverPicture,
      receiverEmail: receiverEmail,
    ));

    final displayName = receiverName.isNotEmpty ? receiverName : 'Unknown';
    final profilePicture = Utils.isValidImageUrl(receiverPicture) ? receiverPicture : '';

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
              onPressed: () => Get.back(),
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
            onPressed: () => _showDeleteConversationDialog(controller),
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
            Obx(() => controller.errorMessage.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.amber[100],
                    width: double.infinity,
                    child: Text(
                      controller.errorMessage.value,
                      style: TextStyle(color: Colors.amber[900]),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink()),
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
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    final isMe = message.senderId == currentUserId;
                    final messageTime =
                        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

                    return GestureDetector(
                      onLongPress: () => _showDeleteOptions(context, controller, message),
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
                );
              }),
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
                              controller: controller.messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) {
                                if (!controller.isSendingMessage.value) {
                                  controller.sendMessage();
                                }
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
                  Obx(() => CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: controller.isSendingMessage.value ? null : () => controller.sendMessage(),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteOptions(BuildContext context, ChatController controller, ChatMessage message) {
    final isMe = message.senderId == controller.currentUserId;

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
                  final success = await controller.deleteMessageForMe(message.id);
                  Get.snackbar(
                    success ? 'Success' : 'Error',
                    success ? 'Message deleted successfully' : 'Failed to delete message',
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
                    final success = await controller.deleteMessageForEveryone(message.id);
                    Get.snackbar(
                      success ? 'Success' : 'Error',
                      success ? 'Message deleted for everyone' : 'Failed to delete message',
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

  Future<void> _showDeleteConversationDialog(ChatController controller) async {
    final confirmed = await _showConfirmationDialog(
      Get.context!,
      'Delete Conversation',
      'Are you sure you want to delete this entire conversation? This action cannot be undone.',
    );
    if (confirmed) {
      final success = await controller.deleteConversation();
      Get.snackbar(
        success ? 'Success' : 'Error',
        success ? 'Conversation deleted successfully' : 'Failed to delete conversation',
      );
      if (success) {
        Get.back();
      }
    }
  }
}