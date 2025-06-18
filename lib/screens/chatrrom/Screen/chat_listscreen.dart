import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/Notification/FCM_Services.dart';
import 'package:innovator/screens/Eliza_ChatBot/Elizahomescreen.dart';
import 'package:innovator/screens/chatrrom/Screen/chatscreen.dart';
import 'package:innovator/screens/chatrrom/controller/chatlist_controller.dart';
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
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver, RouteAware, SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  ChatListController? controller;
  bool _isInitialized = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  void _initializeController() async {
    controller = Get.put(ChatListController());
    await controller!.fetchChats();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && controller != null) {
      // Refresh chat list when app comes back to foreground
      refreshChatList();
    }
  }

  // Add this method to handle when returning from another screen
  @override
  void didPopNext() {
    super.didPopNext();
    // This is called when returning from another route
    _handleReturnFromChat();
  }

  Future<void> _handleReturnFromChat() async {
    if (controller != null) {
      // Force refresh the chat list
      await controller!.fetchChats();

      // Ensure MQTT is connected
      if (!controller!.isMqttConnected.value) {
        await controller!.initializeMQTT();
      }

      // Force UI refresh
      controller!.forceRefreshUI();

      // Trigger a rebuild
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> refreshChatList() async {
    if (controller != null) {
      await controller!.fetchChats();
      // Reinitialize MQTT if disconnected
      if (!controller!.isMqttConnected.value) {
        await controller!.initializeMQTT();
      }
      // Force UI update
      controller!.forceRefreshUI();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || controller == null) {
      return Scaffold(
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
          child: const Center(
            child: CircularProgressIndicator(
              color: Color.fromRGBO(244, 135, 6, 1),
            ),
          ),
        ),
      );
    }

    return Scaffold(
  key: scaffoldKey,
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
        child: SafeArea(
          child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(30),
            child: TextField(
              controller: controller!.searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color.fromRGBO(244, 135, 6, 1),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Obx(
                  () =>
                      controller!.searchText.value.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller!.searchController.clear();
                              controller!.searchText.value = '';
                              FocusScope.of(context).unfocus();
                            },
                          )
                          : const SizedBox.shrink(),
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        // Connection Status
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        //   child: Obx(() {
        //     final isConnected = controller!.isMqttConnected.value;
        //     return Row(
        //       children: [
        //         Icon(
        //           isConnected ? Icons.wifi : Icons.wifi_off,
        //           color: isConnected ? Colors.green : Colors.red,
        //           size: 14,
        //         ),
        //         const SizedBox(width: 8),
        //         Text(
        //           isConnected
        //               ? 'Connected to real-time updates'
        //               : 'Disconnected from real-time updates',
        //           style: TextStyle(
        //             color: isConnected ? Colors.green : Colors.red,
        //             fontSize: 10,
        //           ),
        //         ),
        //       ],
        //     );
        //   }),
        // ),
        // Chat List
        Expanded(
          child: Obx(() {
            final filteredChats = controller!.filteredChats;
            return RefreshIndicator(
              onRefresh: () async {
                await refreshChatList();
              },
              child:
                  filteredChats.isEmpty
                      ? ListView(
                        children: const [
                          SizedBox(height: 200),
                          Center(child: Text('No chats available')),
                        ],
                      )
                      : ListView.builder(
                        itemCount:
                            filteredChats.length +
                            1, // Add 1 for the static section
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Static Chat Section with onTap
                            return GestureDetector(
                              onTap: () {
                                // Handle tap event for the static section
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ElizaChatScreen(),
                                  ),
                                );
                                // Add custom logic, e.g., navigate to AI chat or send a message
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Image.asset('animation/AI.gif', height: 50),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "ELIZA Innovator AI 👋",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "Ask our Innovator anything! Start exploring now.",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Existing dynamic chat items
                          final chat =
                              filteredChats[index -
                                  1]; // Adjust index for chats
                          final chatId = chat['_id']?.toString() ?? '';
                          final user =
                              chat['user'] as Map<String, dynamic>? ??
                              {'_id': '', 'name': 'Unknown', 'email': ''};
                          final userId = user['_id']?.toString() ?? '';
                          final profilePicture =
                              user['picture']?.toString() ?? '';
                          final displayName =
                              user['name']?.toString() ?? 'Unknown';
                          final email = user['email']?.toString() ?? '';

                          return Obx(() {
                            final unreadCount =
                                controller!.unreadMessageCounts[chatId] ?? 0;
                            final hasUnread = unreadCount > 0;
                            final isRecent = controller!.isRecentMessage(
                              chatId,
                            );

                            return Container(
                              decoration: BoxDecoration(
                                color:
                                    isRecent
                                        ? Colors.orange.withOpacity(0.15)
                                        : hasUnread
                                        ? Colors.orange.withOpacity(0.15)
                                        : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 1,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration:
                                    hasUnread
                                        ? BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange.withOpacity(0.3),
                                              Colors.orange.withOpacity(0.1),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        )
                                        : null,
                                child: ListTile(
                                  leading: badges.Badge(
                                    showBadge: unreadCount > 0,
                                    badgeContent: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    badgeStyle: const badges.BadgeStyle(
                                      badgeColor: Color.fromRGBO(
                                        244,
                                        135,
                                        6,
                                        1,
                                      ),
                                      padding: EdgeInsets.all(6),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    position: badges.BadgePosition.topEnd(
                                      top: -8,
                                      end: -8,
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.grey[200],
                                      radius: 24,
                                      child:
                                          Utils.isValidImageUrl(profilePicture)
                                              ? ClipOval(
                                                child: Image.network(
                                                  Utils.getImageUrl(
                                                    profilePicture,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  width: 48,
                                                  height: 48,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Text(
                                                        displayName.isNotEmpty
                                                            ? displayName[0]
                                                                .toUpperCase()
                                                            : '?',
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                ),
                                              )
                                              : Text(
                                                displayName.isNotEmpty
                                                    ? displayName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                ),
                                              ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: TextStyle(
                                            fontWeight:
                                                hasUnread || isRecent
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (chat['lastMessage']?['timestamp'] !=
                                          null)
                                        Text(
                                          controller!.formatMessageTime(
                                            chat['lastMessage']['timestamp'],
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                hasUnread || isRecent
                                                    ? Colors.black87
                                                    : Colors.grey,
                                            fontWeight:
                                                hasUnread || isRecent
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    chat['lastMessage']?['message']
                                            ?.toString() ??
                                        'No messages yet',
                                    style: TextStyle(
                                      fontWeight:
                                          hasUnread || isRecent
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          hasUnread || isRecent
                                              ? Colors.black87
                                              : Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap:
                                      () => _navigateToChat(
                                        chatId,
                                        userId,
                                        displayName,
                                        profilePicture,
                                        email,
                                      ),
                                ),
                              ),
                            );
                          });
                        },
                      ),
            );
          }),
        ),
      ],
    )
        ),
      ),
      FloatingMenuWidget(),
    ],
  ),
);
  }

  
  void _navigateToChat(
    String chatId,
    String userId,
    String displayName,
    String profilePicture,
    String email,
  ) async {
    // Mark chat as read before navigation
    controller!.markChatAsRead(chatId);

    // Navigate to chat screen and wait for result
    final result = await Get.to(
      () => ChatScreen(
        currentUserId: widget.currentUserId,
        currentUserName: widget.currentUserName,
        currentUserPicture: widget.currentUserPicture,
        currentUserEmail: widget.currentUserEmail,
        receiverId: userId,
        receiverName: displayName,
        receiverPicture: profilePicture,
        receiverEmail: email,
      ),
    );

    // Always refresh when returning from chat screen
    await _refreshChatListAfterChat();
  }

  Future<void> _refreshChatListAfterChat() async {
    if (controller != null) {
      // Show loading indicator briefly
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }

      // Fetch latest chats from API
      await controller!.fetchChats();

      // Reinitialize MQTT if needed
      if (!controller!.isMqttConnected.value) {
        await controller!.initializeMQTT();
      }

      // Force UI update
      controller!.forceRefreshUI();

      // Update state
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }
}