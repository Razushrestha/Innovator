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
  final int _port = 1885;
  final String _identifier = DateTime.now().millisecondsSinceEpoch.toString();
  final Queue<Map<String, dynamic>> _messageQueue = Queue();
  String? _currentUserId;
  String? _token;
  final Map<String, Function(String)> _topicCallbacks = {};
  Timer? _reconnectTimer;
  Timer? _presenceHeartbeatTimer;
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
      _startPresenceHeartbeat();
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
      'user/$_currentUserId/presence',
      'user/$_currentUserId/notifications',
      'presence/+', // Subscribe to all presence updates
      'presence/broadcast', // Subscribe to presence broadcasts
      'presence/request', // Subscribe to presence requests
    ];

    // Clear existing subscriptions
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
      
      // Handle presence-related topics
      if (topic.startsWith('presence/') || topic.contains('/presence')) {
        _handlePresenceMessage(topic, payload);
      }
      
      _topicCallbacks[topic]?.call(payload);

      try {
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic>) {
          if (data['type'] == 'new_message' && data['message'] != null) {
            if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
              _messageStreamController.add(data);
              developer.log('MQTTService: Added new_message to stream: $data');
            } else {
              _messageQueue.add(data);
              developer.log('MQTTService: Queued new_message for topic: $topic');
            }
          } else if (data['type'] == 'presence_update') {
            _messageStreamController.add(data);
            developer.log('MQTTService: Added presence_update to stream: $data');
          } else {
            developer.log('MQTTService: Processed other message type: ${data['type']}');
          }
          _topicCallbacks[topic]?.call(payload);
        }
      } catch (e) {
        developer.log('MQTTService: Error processing message: $e');
      }
    });

    // Publish initial online status
    _publishPresenceStatus('online');
  }

  void _handlePresenceMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      
      if (topic == 'presence/request') {
        // Handle presence requests
        final targetUserId = data['targetUserId']?.toString();
        final requesterId = data['requesterId']?.toString();
        
        if (targetUserId == _currentUserId && requesterId != null) {
          // Someone is requesting our presence status
          _respondToPresenceRequest(requesterId);
        }
      } else if (topic.startsWith('presence/') || topic.contains('/presence')) {
        // Handle presence updates
        final userId = data['userId']?.toString();
        final status = data['status']?.toString();
        
        if (userId != null && userId != _currentUserId) {
          // Forward presence update to message stream
          _messageStreamController.add({
            'type': 'presence_update',
            'userId': userId,
            'status': status,
            'timestamp': data['timestamp'],
          });
        }
      }
    } catch (e) {
      developer.log('MQTTService: Error handling presence message: $e');
    }
  }

  void _respondToPresenceRequest(String requesterId) {
    try {
      final response = {
        'userId': _currentUserId,
        'status': 'online',
        'timestamp': DateTime.now().toIso8601String(),
        'requestedBy': requesterId,
      };
      
      publish('user/$requesterId/presence', response);
      developer.log('MQTTService: Responded to presence request from $requesterId');
    } catch (e) {
      developer.log('MQTTService: Error responding to presence request: $e');
    }
  }

  void _publishPresenceStatus(String status) {
    if (_currentUserId == null) return;
    
    try {
      final presenceData = {
        'userId': _currentUserId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Publish to user's presence topic
      publish('user/$_currentUserId/presence', presenceData);
      
      // Publish to global presence broadcast
      publish('presence/broadcast', presenceData);
      
      developer.log('MQTTService: Published presence status: $status for user: $_currentUserId');
    } catch (e) {
      developer.log('MQTTService: Error publishing presence status: $e');
    }
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (isConnected()) {
        _publishPresenceStatus('online');
      } else {
        timer.cancel();
      }
    });
    developer.log('MQTTService: Started presence heartbeat');
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

  // Request online status of a specific user
  void requestUserOnlineStatus(String userId) {
    try {
      publish('presence/request', {
        'requesterId': _currentUserId,
        'targetUserId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      developer.log('MQTTService: Requested online status for user: $userId');
    } catch (e) {
      developer.log('MQTTService: Error requesting online status: $e');
    }
  }

  // Batch request online status for multiple users
  void requestMultipleUsersOnlineStatus(List<String> userIds) {
    for (final userId in userIds) {
      if (userId != _currentUserId) {
        requestUserOnlineStatus(userId);
      }
    }
  }

  void _onConnected() {
    developer.log('MQTTService: Connected to MQTT broker');
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _subscribeToPersonalTopics();
    _processMessageQueue();
    _startPresenceHeartbeat();
  }

  void _onAutoReconnected() {
    developer.log('MQTTService: Auto-reconnected to MQTT broker');
    _reconnectAttempts = 0;
    _subscribeToPersonalTopics();
    _processMessageQueue();
    _startPresenceHeartbeat();
  }

  void _onDisconnected() {
    developer.log('MQTTService: Disconnected from MQTT broker');
    _presenceHeartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  void _onSubscribed(String topic) {
    developer.log('MQTTService: Subscribed to topic: $topic');
  }

  void disconnect() {
    if (_currentUserId != null) {
      _publishPresenceStatus('offline');
    }
    
    _presenceHeartbeatTimer?.cancel();
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