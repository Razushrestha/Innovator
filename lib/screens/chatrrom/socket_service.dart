import 'package:innovator/App_data/App_data.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  io.Socket? get socket => _socket;
  bool get isConnected => _isConnected;

  void initializeSocket() {
    try {
      _socket = io.io(
        'http://182.93.94.210:3064',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setQuery({'token': AppData().authToken})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        print('Socket connected');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('Socket disconnected');
      });

      _socket!.onError((data) {
        print('Socket error: $data');
      });
    } catch (e) {
      print('Socket initialization error: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }

  void sendMessage(String roomId, String message) {
    if (_isConnected) {
      _socket?.emit('send_message', {
        'roomId': roomId,
        'message': message,
        'senderId': AppData().currentUserId,
      });
    }
  }

  void joinRoom(String roomId) {
    if (_isConnected) {
      _socket?.emit('join_room', roomId);
    }
  }

  void leaveRoom(String roomId) {
    if (_isConnected) {
      _socket?.emit('leave_room', roomId);
    }
  }
}