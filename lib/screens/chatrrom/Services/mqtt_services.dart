import 'dart:collection';
import 'dart:developer' as developer;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  MqttServerClient? _client;
  final String _host = '182.93.94.210';
  final int _port = 1883;
  final String _identifier = DateTime.now().millisecondsSinceEpoch.toString();
  final Queue<Map<String, dynamic>> _messageQueue = Queue();
  String? _currentUserId;
  String? _token;
  final Map<String, Function(String)> _topicCallbacks = {};
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _baseReconnectInterval = const Duration(seconds: 5);
  final StreamController<Map<String, dynamic>> _messageStreamController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;


bool isConnected() {
  return _client?.connectionStatus?.state == MqttConnectionState.connected;
}


  Future<void> connect(String token, String userId) async {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      developer.log('MQTTService: Already connected, skipping connect');
      return;
    }

    _currentUserId = userId;
    _token = token;
    _client = MqttServerClient(_host, _identifier);
    _client!.port = _port;
    _client!.logging(on: false);
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
      developer.log('MQTTService: Connection attempt skipped: ' +
          (_isConnecting ? 'Already connecting' : 'Max reconnect attempts reached'));
      return;
    }

    _isConnecting = true;
    try {
      developer.log('MQTTService: Attempting to connect to MQTT broker at $_host:$_port');
      await _client!.connect();
      _reconnectAttempts = 0;
      _subscribeToPersonalTopics();
      _processMessageQueue();
      _reconnectTimer?.cancel();
    } catch (e) {
      developer.log('MQTTService: Connection Exception: $e');
      _reconnectAttempts++;
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _processMessageQueue() {
    while (_messageQueue.isNotEmpty) {
      final message = _messageQueue.removeFirst();
      _messageStreamController.add(message);
      developer.log('MQTTService: Processed queued message: $message');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      developer.log('MQTTService: Maximum reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = _baseReconnectInterval * pow(2, _reconnectAttempts);
    _reconnectTimer = Timer(delay, () async {
      if (_client?.connectionStatus?.state != MqttConnectionState.connected &&
          !_isConnecting) {
        await _attemptConnect();
      }
    });
    developer.log('MQTTService: Scheduled reconnect attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts after ${delay.inSeconds}s');
  }

  void _subscribeToPersonalTopics() {
    if (_currentUserId == null) {
      developer.log('MQTTService: Cannot subscribe: currentUserId is null');
      return;
    }

    final topics = [
      'user/$_currentUserId/messages',
    ];

    for (var topic in _topicCallbacks.keys.toList()) {
    _client!.unsubscribe(topic);
    developer.log('MQTTService: Unsubscribed from topic: $topic');
  }
  _topicCallbacks.clear();

    for (var topic in topics) {
      developer.log('MQTTService: Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      final topic = c[0].topic;
      developer.log('MQTTService: Received message on topic: $topic, payload: $payload');
      _topicCallbacks[topic]?.call(payload);

      try {
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic> && data['type'] == 'new_message' && data['message'] != null) {
          if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
            _messageStreamController.add(data);
            developer.log('MQTTService: Added new_message to stream: $data');
          } else {
            _messageQueue.add(data);
            developer.log('MQTTService: Queued new_message for topic: $topic');
          }
          _topicCallbacks[topic]?.call(payload);
        } else {
          developer.log('MQTTService: Ignored message: not a valid new_message format');
        }
      } catch (e) {
        developer.log('MQTTService: Error processing message: $e');
      }
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
    developer.log('MQTTService: Generated chat topic: $topic');
    return topic;
  }

  void initiateChat(String receiverId, Map<String, dynamic> message, Function(String) onMessage) {
    if (_currentUserId == null) {
      developer.log('MQTTService: Cannot initiate chat: currentUserId is null');
      return;
    }
    final chatTopic = getChatTopic(_currentUserId!, receiverId);
    subscribe(chatTopic, onMessage);
  }

  void subscribe(String topic, Function(String) onMessage) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      developer.log('MQTTService: Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      _topicCallbacks[topic] = onMessage;
    } else {
      developer.log('MQTTService: Client not connected, queuing subscription for topic: $topic');
      Future.delayed(const Duration(seconds: 2), () {
        if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
          subscribe(topic, onMessage);
        }
      });
    }
  }

  Future<void> publish(String topic, Map<String, dynamic> message) async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      developer.log('MQTTService: Client not connected, attempting to reconnect...');
      if (_currentUserId != null && _token != null) {
        await connect(_token!, _currentUserId!);
      } else {
        developer.log('MQTTService: Cannot reconnect, missing userId or token');
        throw Exception('Cannot publish: Not connected and missing credentials');
      }
    }

    final payload = jsonEncode(message);
    developer.log('MQTTService: Publishing to topic: $topic with message: $payload');
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    try {
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      developer.log('MQTTService: Publish initiated for topic: $topic');
    } catch (e) {
      developer.log('MQTTService: Error publishing message: $e');
      _scheduleReconnect();
      throw Exception('Failed to publish message');
    }
  }

  void _onConnected() {
    developer.log('MQTTService: Connected to MQTT broker');
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _subscribeToPersonalTopics();
    _processMessageQueue();
  }

  void _onAutoReconnected() {
    developer.log('MQTTService: Auto-reconnected to MQTT broker');
    _reconnectAttempts = 0;
    _subscribeToPersonalTopics();
    _processMessageQueue();
  }

  void _onDisconnected() {
    developer.log('MQTTService: Disconnected from MQTT broker');
    _scheduleReconnect();
  }

  void _onSubscribed(String topic) {
    developer.log('MQTTService: Subscribed to topic: $topic');
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
    developer.log('MQTTService: Disconnected from MQTT broker and cleared state');
  }
}