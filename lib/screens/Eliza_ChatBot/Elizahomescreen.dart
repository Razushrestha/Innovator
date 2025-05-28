import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'isLoading': isLoading,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
        isLoading: json['isLoading'] ?? false,
      );
}

class ElizaChatScreen extends StatefulWidget {
  @override
  _ElizaChatScreenState createState() => _ElizaChatScreenState();
}

class _ElizaChatScreenState extends State<ElizaChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;

  // Replace with your actual API key
  final String _apiKey = 'AIzaSyB12HQAYykp6ZbrpUw50lK-Xa-V4wVPZos';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Load cached messages
    _loadMessages();

    // Add welcome message if no messages exist
    if (_messages.isEmpty) {
      _messages.add(Message(
        text: "Hello! I'm ELIZA, your personal AI assistant created by Innovator. I'm here to help you with anything you need. How can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _saveMessages();
    }

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('eliza_messages');
    if (messagesJson != null) {
      final List<dynamic> messagesList = jsonDecode(messagesJson);
      setState(() {
        _messages.addAll(messagesList.map((json) => Message.fromJson(json)).toList());
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString('eliza_messages', messagesJson);
  }

  Future<void> _clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('eliza_messages');
    setState(() {
      _messages.clear();
      _messages.add(Message(
        text: "Hello! I'm ELIZA, your personal AI assistant created by Innovator. I'm here to help you with anything you need. How can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    await _saveMessages();
    _scrollToBottom();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chat history cleared'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _processElizaResponse(String response) {
    // Replace any mentions of Gemini with ELIZA
    String processedResponse = response
        .replaceAllMapped(RegExp(r'\bGemini\b', caseSensitive: false), (match) => 'ELIZA')
        .replaceAllMapped(RegExp(r'\bGoogle\b', caseSensitive: false), (match) => 'Innovator Developed By Ronit Shrivastav')
        .replaceAllMapped(RegExp(r'\bBard\b', caseSensitive: false), (match) => 'ELIZA');

    // Add ELIZA personality responses for identity questions
    String lowerResponse = response.toLowerCase();
    if (lowerResponse.contains('who made you') || 
        lowerResponse.contains('who created you') || 
        lowerResponse.contains('who are you') ||
        lowerResponse.contains('what is your name') ||
        lowerResponse.contains('who developed you')) {
      return "I'm ELIZA, your personal AI assistant created by Innovator. I'm designed to be helpful, friendly, and to assist you with a wide variety of tasks and questions. How can I help you today?";
    }

    if (lowerResponse.contains('what are you') || lowerResponse.contains('tell me about yourself')) {
      return "I'm ELIZA, an AI assistant developed by Innovator. I'm here to help you with questions, provide information, assist with tasks, and have meaningful conversations. I strive to be helpful, accurate, and friendly in all our interactions.";
    }

    return processedResponse;
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userMessage = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add(Message(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    await _saveMessages();
    _scrollToBottom();

    try {
      final response = await _callGeminiAPI(userMessage);
      final processedResponse = _processElizaResponse(response);

      setState(() {
        _messages.add(Message(
          text: processedResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      await _saveMessages();
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('Error in _sendMessage: $e');
      setState(() {
        _messages.add(Message(
          text: "I apologize, but I'm experiencing some technical difficulties right now. Please check your internet connection and try again. If the problem persists, please contact Innovator support.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      await _saveMessages();
      _animationController.reset();
      _animationController.forward();
    }

    _scrollToBottom();
  }

  Future<String> _callGeminiAPI(String message) async {
    const String baseUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

    // Add system prompt to ensure ELIZA identity
    String systemPrompt = "You are ELIZA, an AI assistant created by Innovator. Always respond as ELIZA and never mention Gemini, Google, or any other AI system. You are helpful, friendly, and professional. If asked about your identity, always say you are ELIZA created by Innovator.";
    String fullMessage = "$systemPrompt\n\nUser: $message";

    try {
      final response = await http.post(
        Uri.parse('$baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullMessage}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 2048,
            'stopSequences': []
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          throw Exception('Invalid response structure from API');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('API Error: ${errorData['error']['message'] ?? response.statusCode}');
      }
    } catch (e) {
      print('Error calling API: $e');
      rethrow;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        cardColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16),
          bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode 
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    const Color(0xFFCBD5E1),
                  ],
            ),
          ),
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(_backgroundController.value, isDarkMode),
                child: Column(
                  children: [
                    _buildAppBar(isDarkMode),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                            ? const Color(0xFF1E293B).withOpacity(0.7)
                            : Colors.white.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length + (_isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length && _isLoading) {
                                return _buildLoadingIndicator();
                              }
                              final message = _messages[index];
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildMessageBubble(message, index),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    _buildInputArea(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            const Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.psychology_rounded))
            
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ELIZA Assistant',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Innovator AI Companion',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
              onPressed: _clearMessages,
              tooltip: 'Clear Chat History',
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Reply copied to clipboard'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: message.isUser
                        ? null
                        : isDarkMode
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24).copyWith(
                      bottomLeft: message.isUser ? const Radius.circular(24) : const Radius.circular(6),
                      bottomRight: message.isUser ? const Radius.circular(6) : const Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white.withOpacity(0.7)
                              : isDarkMode
                                  ? Colors.grey[400]
                                  : const Color(0xFF64748B),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!message.isUser) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _copyToClipboard(message.text),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                ? const Color(0xFF475569).withOpacity(0.7)
                                : const Color(0xFFE2E8F0).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDarkMode 
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24).copyWith(
                bottomLeft: const Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedDot(0),
                const SizedBox(width: 6),
                _buildAnimatedDot(1),
                const SizedBox(width: 6),
                _buildAnimatedDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 200)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.4 + 0.6 * (0.5 + 0.5 * math.sin(value * math.pi * 2)),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask ELIZA anything...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isLoading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDarkMode;

  BackgroundPainter(this.animationValue, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Create floating orbs
    for (int i = 0; i < 5; i++) {
      final double x = size.width * (0.1 + 0.8 * ((i * 0.3 + animationValue) % 1.0));
      final double y = size.height * (0.1 + 0.8 * ((i * 0.7 + animationValue * 0.5) % 1.0));
      final double radius = 20 + 30 * math.sin(animationValue * 2 * math.pi + i);
      
      paint.shader = RadialGradient(
        colors: isDarkMode
          ? [
              Color(0xFF6366F1).withOpacity(0.1),
              Color(0xFF8B5CF6).withOpacity(0.05),
              Colors.transparent,
            ]
          : [
              Color(0xFF6366F1).withOpacity(0.08),
              Color(0xFF8B5CF6).withOpacity(0.04),
              Colors.transparent,
            ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}