import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/chatrrom/chat_screen.dart';
import 'package:innovator/screens/chatrrom/providers/providers.dart';
import 'package:innovator/screens/chatrrom/repository/chat_repository.dart';
import 'package:intl/intl.dart';

// Add a User model if not already defined elsewhere
class User {
  final String id;
  final String name;
  final String? avatarUrl;

  User({required this.id, required this.name, this.avatarUrl});
}

// Add a provider for users
final usersProvider = FutureProvider<List<User>>((ref) async {
  // Replace this with your actual user fetching logic
  final userRepository = ref.read(userRepositoryProvider);
  return await userRepository.getUsers();
});

// Add a user repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Simple User Repository
class UserRepository {
  Future<List<User>> getUsers() async {
    // Replace with actual API call to get users
    // This is just a mock implementation
    await Future.delayed(const Duration(seconds: 1));
    
    // Don't include current user in this list
    final currentUserId = AppData().currentUserId;
    
    // Mock data - replace with actual user data from your backend
    return [
      User(id: 'user1', name: 'Alice Johnson'),
      User(id: 'user2', name: 'Bob Smith'),
      User(id: 'user3', name: 'Carol White'),
      User(id: 'user4', name: 'David Brown'),
      User(id: 'user5', name: 'Emma Davis'),
    ].where((user) => user.id != currentUserId).toList();
  }
}

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chats (${AppData().currentUserName ?? ''})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateChatDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(chatRoomsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AppData().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: chatRoomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading chats',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                onPressed: () => ref.refresh(chatRoomsProvider),
              ),
            ],
          ),
        ),
        data: (chatRooms) => chatRooms.isEmpty
            ? _buildEmptyState(context)
            : ListView.separated(
                itemCount: chatRooms.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final room = chatRooms[index];
                  return _buildChatRoomTile(context, room);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a new conversation by tapping the + button',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomTile(BuildContext context, ChatRoom room) {
    final hasLastMessage = room.lastMessage != null;
    final lastMessageTime = hasLastMessage
        ? DateFormat('HH:mm').format(room.lastMessage!.timestamp)
        : '';
    
    // Determine if the last message was sent by the current user
    final isSentByMe = hasLastMessage && 
        AppData().isCurrentUser(room.lastMessage!.senderId);
    
    final lastMessagePrefix = hasLastMessage && isSentByMe ? 'You: ' : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade300,
        child: Text(
          room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        room.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: hasLastMessage
          ? Text(
              '$lastMessagePrefix${room.lastMessage!.content}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const Text(
              'No messages yet',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (hasLastMessage)
            Text(
              lastMessageTime,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          const SizedBox(height: 4),
          // Add notification indicator if needed here
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatRoom: room),
          ),
        );
      },
    );
  }

  void _showCreateChatDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return CreateChatDialog(
          nameController: nameController,
          ref: ref,
        );
      },
    );
  }
}

class CreateChatDialog extends ConsumerStatefulWidget {
  final TextEditingController nameController;
  final WidgetRef ref;

  const CreateChatDialog({
    super.key,
    required this.nameController,
    required this.ref,
  });

  @override
  ConsumerState<CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends ConsumerState<CreateChatDialog> {
  final List<User> selectedUsers = [];
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return AlertDialog(
      title: const Text('Create New Chat'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                labelText: 'Chat Name',
                hintText: 'Enter chat name',
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Participants:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 8),
            // Selected users chips
            if (selectedUsers.isNotEmpty)
              Wrap(
                spacing: 8,
                children: selectedUsers
                    .map(
                      (user) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.blue.shade300,
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        label: Text(user.name),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            selectedUsers.remove(user);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 8),
            // User list
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Error loading users: $error'),
                ),
                data: (users) {
                  // Filter users based on search query
                  final filteredUsers = users
                      .where((user) => 
                          user.name.toLowerCase().contains(searchQuery) &&
                          !selectedUsers.contains(user))
                      .toList();
                  
                  return filteredUsers.isEmpty
                      ? const Center(
                          child: Text('No users found'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade300,
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(user.name),
                              trailing: const Icon(Icons.add),
                              onTap: () {
                                setState(() {
                                  selectedUsers.add(user);
                                });
                              },
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final name = widget.nameController.text.trim();
            final participantIds = selectedUsers.map((u) => u.id).toList();

            // Add current user to participants
            final currentUserId = AppData().currentUserId;
            if (currentUserId != null && 
                !participantIds.contains(currentUserId)) {
              participantIds.add(currentUserId);
            }

            if (name.isNotEmpty && participantIds.length > 1) {
              try {
                Navigator.pop(context);
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Creating chat room...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                // Create the chat room
                await widget.ref.read(chatRepositoryProvider).createChatRoom(
                      name,
                      participantIds,
                    );

                // Refresh the chat rooms list
                widget.ref.refresh(chatRoomsProvider);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please enter a chat name and select at least one participant',
                  ),
                ),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}