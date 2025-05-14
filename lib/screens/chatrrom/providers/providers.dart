import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/screens/chatrrom/repository/chat_repository.dart';

// Provider for the chat repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// Provider for chat rooms (async)
final chatRoomsProvider = FutureProvider<List<ChatRoom>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatRooms();
});

// Provider for chat messages (async with parameter)
final chatMessagesProvider = FutureProvider.family<List<Message>, String>((ref, chatId) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatMessages(chatId);
});

// Provider to track the currently selected chat room
final selectedChatRoomProvider = StateProvider<ChatRoom?>((ref) => null);

// Provider for real-time chat state within a specific room
final chatStateProvider = StateNotifierProvider.family<ChatStateNotifier, ChatState, String>(
  (ref, chatId) => ChatStateNotifier(ref.watch(chatRepositoryProvider), chatId),
);

// Chat state class
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Chat state notifier
class ChatStateNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final String _chatId;

  ChatStateNotifier(this._repository, this._chatId) : super(ChatState(messages: [])) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final messages = await _repository.getChatMessages(_chatId);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> sendMessage(String content) async {
    try {
      final message = await _repository.sendMessage(_chatId, content);
      
      // Add the new message to the state
      final updatedMessages = [...state.messages, message];
      
      // Sort by timestamp
      updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}