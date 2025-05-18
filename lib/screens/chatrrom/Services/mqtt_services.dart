import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  MqttServerClient? _client;
  final String _host = '182.93.94.210';
  final String _identifier = DateTime.now().millisecondsSinceEpoch.toString();
  String? _currentUserId;
  final Map<String, Function(String)> _topicCallbacks = {};

  Future<void> connect(String token, String userId) async {
    _currentUserId = userId;
    _client = MqttServerClient(_host, _identifier);
    _client!.port = 1883;
    _client!.logging(on: true); // Enable logging for debugging
    _client!.keepAlivePeriod = 60;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_identifier)
        .authenticateAs(null, token) // JWT as password
        .withWillQos(MqttQos.atLeastOnce)
        .withWillTopic('user/$userId/presence')
        .withWillMessage(json.encode({
          'userId': userId,
          'status': 'offline',
          'timestamp': DateTime.now().toIso8601String(),
        }));

    _client!.connectionMessage = connMessage;

    try {
      print('Attempting to connect to MQTT broker at $_host:1883');
      await _client!.connect();
      _subscribeToPersonalTopics();
    } catch (e) {
      print('MQTT Connection Exception: $e');
      _client!.disconnect();
      rethrow;
    }
  }

  void _subscribeToPersonalTopics() {
    if (_currentUserId == null) {
      print('Cannot subscribe: currentUserId is null');
      return;
    }
    final topics = [
      'user/$_currentUserId/status',
      'user/$_currentUserId/messages',
      'user/$_currentUserId/notifications',
      'user/$_currentUserId/presence',
    ];

    for (var topic in topics) {
      print('Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      final topic = c[0].topic;
      print('Received message on topic: $topic, payload: $payload');
      _topicCallbacks[topic]?.call(payload);
    });

    // Publish online status
    publish('user/$_currentUserId/presence', {
      'userId': _currentUserId,
      'status': 'online',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  String getChatTopic(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort();
    final topic = 'chat/${ids[0]}/${ids[1]}';
    print('Generated chat topic: $topic');
    return topic;
  }

  void initiateChat(String receiverId, Map<String, dynamic> message, Function(String) onMessage) {
  if (_currentUserId == null) {
    print('Cannot initiate chat: currentUserId is null');
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

  // Subscribe to chat topic
  subscribe(chatTopic, onMessage);

  // Publish chat initiation
  print('Initiating chat on topic: $initTopic');
  publish(initTopic, payload);
}

  void subscribe(String topic, Function(String) onMessage) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      print('Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      _topicCallbacks[topic] = onMessage;
    } else {
      print('Cannot subscribe to $topic: Client not connected');
    }
  }

  Future<void> publish(String topic, Map<String, dynamic> message) async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      print('Client not connected, attempting to reconnect...');
      try {
        await _client!.connect();
        print('Reconnected successfully');
      } catch (e) {
        print('Reconnection failed: $e');
        throw Exception('Failed to reconnect to MQTT broker');
      }
    }
    final payload = json.encode(message);
    print('Publishing to topic: $topic with message: $payload');
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    try {
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('Publish initiated for topic: $topic');
    } catch (e) {
      print('Error publishing message: $e');
      throw Exception('Failed to publish message');
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker');
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    if (_currentUserId != null) {
      publish('user/$_currentUserId/presence', {
        'userId': _currentUserId,
        'status': 'offline',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void disconnect() {
    if (_currentUserId != null) {
      publish('user/$_currentUserId/presence', {
        'userId': _currentUserId,
        'status': 'offline',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    _client?.disconnect();
    _currentUserId = null;
    _topicCallbacks.clear();
    print('Disconnected from MQTT broker and cleared state');
  }
}