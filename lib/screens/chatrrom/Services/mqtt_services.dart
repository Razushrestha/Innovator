import 'package:innovator/screens/chatrrom/Model/chatMessage.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:developer';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  MqttServerClient? _client;
  final String _host = '182.93.94.210';
  final int _port = 1883;
  final String _identifier = DateTime.now().millisecondsSinceEpoch.toString();
  String? _currentUserId;
  String? _token;
  final Map<String, Function(String)> _topicCallbacks = {};
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  final Duration _reconnectInterval = const Duration(seconds: 5);
  final int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;

  Future<void> connect(String token, String userId) async {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      log('MQTTService: Already connected, skipping connect');
      return;
    }

    _currentUserId = userId;
    _token = token;
    _client = MqttServerClient(_host, _identifier);
    _client!.port = _port;
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
    _client!.resubscribeOnAutoReconnect = true;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.onAutoReconnected = _onAutoReconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_identifier)
        .authenticateAs(null, token)
        .withWillQos(MqttQos.atLeastOnce)
        .withWillTopic('user/$userId/presence')
        .withWillMessage(jsonEncode({
          'userId': userId,
          'status': 'offline',
          'timestamp': DateTime.now().toIso8601String(),
        }));

    _client!.connectionMessage = connMessage;

    await _attemptConnect();
  }

  Future<void> _attemptConnect() async {
    if (_isConnecting || _reconnectAttempts >= _maxReconnectAttempts) {
      log('MQTTService: Connection attempt skipped: ' +
          (_isConnecting ? 'Already connecting' : 'Max reconnect attempts reached'));
      return;
    }

    _isConnecting = true;
    try {
      log('MQTTService: Attempting to connect to MQTT broker at $_host:$_port');
      await _client!.connect();
      _reconnectAttempts = 0;
      _subscribeToPersonalTopics();
      _reconnectTimer?.cancel();
    } catch (e) {
      log('MQTTService: Connection Exception: $e');
      _reconnectAttempts++;
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      log('MQTTService: Maximum reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () async {
      if (_client?.connectionStatus?.state != MqttConnectionState.connected &&
          !_isConnecting) {
        await _attemptConnect();
      }
    });
    log('MQTTService: Scheduled reconnect attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts');
  }

  void _subscribeToPersonalTopics() {
    if (_currentUserId == null) {
      log('MQTTService: Cannot subscribe: currentUserId is null');
      return;
    }

    final topics = [
      'user/$_currentUserId/status',
      'user/$_currentUserId/messages',
      'user/$_currentUserId/notifications',
      'user/$_currentUserId/presence',
    ];

    for (var topic in topics) {
      log('MQTTService: Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      final topic = c[0].topic;
      log('MQTTService: Received message on topic: $topic, payload: $payload');
      _topicCallbacks[topic]?.call(payload);
    });

    publish('user/$_currentUserId/presence', {
      'userId': _currentUserId,
      'status': 'online',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  String getChatTopic(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort();
    final topic = 'chat/${ids[0]}/${ids[1]}';
    log('MQTTService: Generated chat topic: $topic');
    return topic;
  }

  void initiateChat(String receiverId, Map<String, dynamic> message, Function(String) onMessage) {
    if (_currentUserId == null) {
      log('MQTTService: Cannot initiate chat: currentUserId is null');
      return;
    }
    final chatTopic = getChatTopic(_currentUserId!, receiverId);
    final initTopic = 'chat/init/$receiverId';
    final payload = {
      'sender': {
        '_id': _currentUserId,
        'name': message['senderName'] ?? 'Unknown',
        'picture': message['senderPicture'] ?? '',
        'email': message['senderEmail'] ?? '',
      },
      'receiver': {
        '_id': receiverId,
        'name': message['receiverName'] ?? 'Unknown',
        'picture': message['receiverPicture'] ?? '',
        'email': message['receiverEmail'] ?? '',
      },
    };

    subscribe(chatTopic, onMessage);
    log('MQTTService: Initiating chat on topic: $initTopic');
    publish(initTopic, payload);
  }

  void subscribe(String topic, Function(String) onMessage) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      log('MQTTService: Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      _topicCallbacks[topic] = onMessage;
    } else {
      log('MQTTService: Client not connected, queuing subscription for topic: $topic');
      Future.delayed(const Duration(seconds: 1), () {
        if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
          subscribe(topic, onMessage);
        }
      });
    }
  }

  Future<void> publish(String topic, dynamic message) async {
  if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
    await _attemptConnect();
    log('MQTTService: Client not connected, attempting to reconnect...');
    if (_currentUserId != null && _token != null) {
      await connect(_token!, _currentUserId!);
    } else {
      log('MQTTService: Cannot reconnect, missing userId or token');
      throw Exception('Cannot publish: Not connected and missing credentials');
    }
  }

  // Convert ChatMessage to server-expected format if needed
  final payload = json.encode(message);

  log('MQTTService: Publishing to topic: $topic with message: $payload');
  final builder = MqttClientPayloadBuilder();
  builder.addString(payload);
  try {
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    log('MQTTService: Publish initiated for topic: $topic');
  } catch (e) {
    log('MQTTService: Error publishing message: $e');
    _scheduleReconnect();
    throw Exception('Failed to publish message');
  }
}

Map<String, dynamic> _formatChatMessage(ChatMessage message) {
  return {
    'sender': {
      '_id': message.senderId,
      'name': message.senderName,
      'picture': message.senderPicture,
      'email': message.senderEmail,
    },
    'receiver': {
      '_id': message.receiverId,
      'name': message.receiverName,
      'picture': message.receiverPicture,
      'email': message.receiverEmail,
    },
    'message': message.content,
    'timestamp': message.timestamp.toIso8601String(),
  };
}

  void _onConnected() {
    log('MQTTService: Connected to MQTT broker');
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _subscribeToPersonalTopics();
  }

  void _onAutoReconnected() {
    log('MQTTService: Auto-reconnected to MQTT broker');
    _reconnectAttempts = 0;
    _subscribeToPersonalTopics();
  }

  void _onDisconnected() {
    log('MQTTService: Disconnected from MQTT broker');
    if (_currentUserId != null) {
      publish('user/$_currentUserId/presence', {
        'userId': _currentUserId,
        'status': 'offline',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    _scheduleReconnect();
  }

  void _onSubscribed(String topic) {
    log('MQTTService: Subscribed to topic: $topic');
  }

  void disconnect() {
    if (_currentUserId != null) {
      publish('user/$_currentUserId/presence', {
        'userId': _currentUserId,
        'status': 'offline',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    _reconnectTimer?.cancel();
    _client?.disconnect();
    _client = null;
    _currentUserId = null;
    _token = null;
    _topicCallbacks.clear();
    _reconnectAttempts = 0;
    log('MQTTService: Disconnected from MQTT broker and cleared state');
  }
}