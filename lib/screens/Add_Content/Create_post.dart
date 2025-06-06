import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/main.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

// Add these imports for Gemini API integration
import 'package:flutter/services.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _errorMessage;
  List<PlatformFile> _selectedFiles = [];
  List<XFile> _selectedImages = [];
  bool _isUploading = false;
  bool _isCreatingPost = false;
  bool _isProcessingAI = false; // New: For AI processing state
  List<dynamic> _uploadedFiles = [];
  final TextEditingController _descriptionController = TextEditingController();
  final AppData _appData = AppData();
  late AnimationController _animationController;
  late Animation<double> _animation;
  final ImagePicker _picker = ImagePicker();

  // Post type selection
  String _selectedPostType = 'innovation';
  final List<Map<String, dynamic>> _postTypes = [
    {'id': 'innovation', 'name': 'Innovation', 'icon': Icons.lightbulb_outline},
    {'id': 'idea', 'name': 'Idea', 'icon': Icons.tips_and_updates},
    {'id': 'project', 'name': 'Project', 'icon': Icons.rocket_launch},
    {'id': 'question', 'name': 'Question', 'icon': Icons.help_outline},
    {'id': 'announcement', 'name': 'Announcement', 'icon': Icons.campaign},
    {'id': 'other', 'name': 'Other', 'icon': Icons.more_horiz},
  ];

  // UI Colors
  final Color _primaryColor = const Color.fromRGBO(244, 135, 6, 1);
  final Color _accentColor = const Color.fromARGB(255, 219, 231, 230);
  final Color _facebookBlue = const Color(0xFF1877F2);
  final Color _backgroundColor = const Color(0xFFF0F2F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);

  // Gemini API key (same as in ElizaChatScreen)
  final String _apiKey = 'AIzaSyB12HQAYykp6ZbrpUw50lK-Xa-V4wVPZos';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _fetchUserProfile();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _descriptionController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    if (_isPostButtonEnabled) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {});
  }

  void _checkAuthStatus() {
    debugPrint(
      'CreatePostScreen: Auth status - isAuthenticated: ${_appData.isAuthenticated}',
    );
    if (_appData.authToken != null) {
      debugPrint('CreatePostScreen: Auth token available');
    } else {
      debugPrint('CreatePostScreen: No auth token available');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isPostButtonEnabled {
    return (_descriptionController.text.isNotEmpty ||
            _uploadedFiles.isNotEmpty) &&
        !_isCreatingPost &&
        !_isProcessingAI; // Disable button during AI processing
  }

  // Method to capture image using camera
  Future<void> _captureImage() async {
    try {
      final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (capturedImage != null) {
        setState(() {
          _selectedImages.add(capturedImage);
          _selectedFiles.add(PlatformFile(
            name: capturedImage.name,
            path: capturedImage.path,
            size: File(capturedImage.path).lengthSync(),
          ));
        });

        if (_selectedFiles.isNotEmpty) {
          _uploadFiles();
        }
      }
    } catch (e) {
      _showError('Error capturing image: $e');
    }
  }

  // Method to pick images from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles);
          _selectedFiles.addAll(pickedFiles.map((xfile) => PlatformFile(
                name: xfile.name,
                path: xfile.path,
                size: File(xfile.path).lengthSync(),
              )));
        });

        if (_selectedFiles.isNotEmpty) {
          _uploadFiles();
        }
      }
    } catch (e) {
      _showError('Error picking images: $e');
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        debugPrint('Files picked: ${result.files.length}');
        setState(() {
          _selectedFiles = result.files;
        });

        if (_selectedFiles.isNotEmpty) {
          _uploadFiles();
        }
      }
    } catch (e) {
      _showError('Error picking files: $e');
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) {
      _showError('Please select at least one file');
      return;
    }

    if (!await _appData.isAuthenticated) {
      _showError('Please log in first');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadUrl =
          'http://182.93.94.210:3064/api/v1/add-files?subfolder=posts';

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.headers['authorization'] = 'Bearer ${_appData.authToken}';

      for (var file in _selectedFiles) {
        final mimeType =
            lookupMimeType(file.path!) ?? 'application/octet-stream';

        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            file.path!,
            contentType: MediaType.parse(mimeType),
            filename: file.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('data')) {
          setState(() {
            _uploadedFiles = jsonResponse['data'];
          });
          _showSuccess('Files uploaded successfully!');
          _updateButtonState();
        } else {
          _showError('Upload succeeded but no file data received');
        }
      } else if (response.statusCode == 401) {
        _showError('Authentication failed. Please log in again.');
        await _appData.clearAuthToken();
      } else {
        _showError('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error uploading files: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final String? authToken = AppData().authToken;

      if (authToken == null || authToken.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://182.93.94.210:3064/api/v1/user-profile'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200 && responseData['data'] != null) {
          setState(() {
            _userData = responseData['data'];
            _isLoading = false;
            AppData().setCurrentUser(_userData!);
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Unknown error';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to load profile. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  // New: Method to call Gemini API (adapted from ElizaChatScreen)
  Future<String> _callGeminiAPI(String message) async {
    const String baseUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

    String systemPrompt =
        "You are ELIZA, an AI assistant created by Innovator. Always respond as ELIZA and never mention Gemini, Google, or any other AI system. You are helpful, friendly, and professional. Enhance the user's input to create a polished, engaging, and contextually appropriate post for a social platform focused on innovation. Maintain the original intent and tone of the user's input.";
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

  // New: Method to process ELIZA response (adapted from ElizaChatScreen)
  String _processElizaResponse(String response) {
    String processedResponse = response
        .replaceAllMapped(
            RegExp(r'\bGemini\b', caseSensitive: false), (match) => 'ELIZA')
        .replaceAllMapped(RegExp(r'\bGoogle\b', caseSensitive: false),
            (match) => 'Innovator Developed By Ronit Shrivastav')
        .replaceAllMapped(
            RegExp(r'\bBard\b', caseSensitive: false), (match) => 'ELIZA');

    String lowerResponse = response.toLowerCase();
    if (lowerResponse.contains('who made you') ||
        lowerResponse.contains('who created you') ||
        lowerResponse.contains('who are you') ||
        lowerResponse.contains('what is your name') ||
        lowerResponse.contains('who developed you')) {
      return "I'm ELIZA, your personal AI assistant created by Innovator. I've enhanced your post to make it more engaging for the Innovator community. Ready to share it?";
    }

    if (lowerResponse.contains('what are you') ||
        lowerResponse.contains('tell me about yourself')) {
      return "I'm ELIZA, an AI assistant developed by Innovator. I've polished your post to make it stand out on the platform. Check it out and let me know if you want to post it!";
    }

    return processedResponse;
  }

  // New: Method to enhance post with ELIZA AI
  Future<void> _enhancePostWithAI() async {
    if (_descriptionController.text.trim().isEmpty || _isProcessingAI) {
      _showError('Please enter some text to enhance');
      return;
    }

    setState(() {
      _isProcessingAI = true;
    });

    try {
      final userInput = _descriptionController.text.trim();
      final aiResponse = await _callGeminiAPI(userInput);
      final processedResponse = _processElizaResponse(aiResponse);

      setState(() {
        _descriptionController.text = processedResponse;
        _isProcessingAI = false;
      });

      _showSuccess('Post enhanced by ELIZA!');
      _updateButtonState();
    } catch (e) {
      _showError('Error enhancing post: $e');
      setState(() {
        _isProcessingAI = false;
      });
    }
  }

  Future<void> _createPost() async {
    if (_descriptionController.text.trim().isEmpty && _uploadedFiles.isEmpty) {
      _showError('Please enter a description or upload files');
      return;
    }

    if (!await _appData.isAuthenticated) {
      _showError('Please log in first');
      return;
    }

    setState(() {
      _isCreatingPost = true;
    });

    try {
      final createUrl = 'http://182.93.94.210:3064/api/v1/new-content';

      final body = {
        'type': _selectedPostType,
        'status': _descriptionController.text,
        'description': _descriptionController.text,
        'files': _uploadedFiles.isEmpty ? [] : _uploadedFiles,
      };

      var response = await http.post(
        Uri.parse(createUrl),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Post published successfully!');
        _clearForm();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => Homepage()),
          (route) => false,
        );
      } else if (response.statusCode == 401) {
        _showError('Authentication failed. Please log in again.');
        await _appData.clearAuthToken();
      } else {
        _showError('Failed to create post: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error creating post: $e');
    } finally {
      setState(() {
        _isCreatingPost = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _descriptionController.clear();
      _selectedFiles = [];
      _selectedImages = [];
      _uploadedFiles = [];
      _selectedPostType = 'innovation';
    });
  }

  void _showError(String message) {
    Get.snackbar('Error', message,
        backgroundColor: Colors.red.shade800, colorText: Colors.white);
  }

  void _showSuccess(String message) {
    Get.snackbar('Success', message,
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  String _safeGetString(dynamic item, String key, String defaultValue) {
    if (item == null) return defaultValue;

    if (item is Map) {
      final value = item[key];
      if (value != null) return value.toString();
    }

    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final userData = AppData().currentUser ?? _userData;

    final String name = userData?['name'] ?? 'User';
    final String level =
        (userData?['level'] ?? 'user').toString().toUpperCase();
    final String email = userData?['email'] ?? '';
    final String? picturePath = userData?['picture'];
    final String baseUrl = 'http://182.93.94.210:3064';
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 15),
                // User info and post type selection
                Container(
                  height: 400,
                  color: _cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // User info row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: picturePath != null
                                ? NetworkImage('$baseUrl$picturePath')
                                : null,
                            child: picturePath == null
                                ? Icon(Icons.person, size: 40, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _textColor,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedPostType,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      elevation: 16,
                                      style: TextStyle(color: _textColor),
                                      isDense: true,
                                      isExpanded: false,
                                      borderRadius: BorderRadius.circular(12),
                                      onChanged: (String? value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedPostType = value;
                                          });
                                        }
                                      },
                                      items: _postTypes
                                          .map<DropdownMenuItem<String>>(
                                              (Map<String, dynamic> type) {
                                        return DropdownMenuItem<String>(
                                          value: type['id'],
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                type['icon'],
                                                size: 18,
                                                color: _primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(type['name']),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Modified: IconButton to trigger AI enhancement
                          IconButton(
                            onPressed: _isProcessingAI ? null : _enhancePostWithAI,
                            icon: _isProcessingAI
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.blue,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Image.asset('animation/AI.gif', width: 50,),
                            tooltip: 'Enhance with ELIZA AI',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Text input area
                      TextField(
                        controller: _descriptionController,
                        style: TextStyle(color: _textColor, fontSize: 18),
                        maxLines: 8,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: 'What\'s on your mind?',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Attachment section
                Container(
                  color: _cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to your post',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Media buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _mediaButton(
                              icon: Icons.camera_alt,
                              color: Colors.purple,
                              label: 'Camera',
                              onTap: _captureImage,
                            ),
                            _mediaButton(
                              icon: Icons.photo_library,
                              color: Colors.green,
                              label: 'Photos',
                              onTap: _pickImages,
                            ),
                            _mediaButton(
                              icon: Icons.videocam,
                              color: Colors.red,
                              label: 'Video',
                              onTap: _pickFiles,
                            ),
                            _mediaButton(
                              icon: Icons.attach_file,
                              color: Colors.blue,
                              label: 'Files',
                              onTap: _pickFiles,
                            ),
                          ],
                        ),
                      ),
                      if (_selectedFiles.isNotEmpty && _isUploading) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: _facebookBlue,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Uploading files...',
                              style: TextStyle(
                                color: _facebookBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_selectedFiles.isNotEmpty && !_isUploading) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Selected Files (${_selectedFiles.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _selectedFiles[index];
                              final isImage = file.path != null &&
                                  ['jpg', 'jpeg', 'png', 'gif', 'webp']
                                      .contains(file.extension?.toLowerCase());

                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    if (isImage && file.path != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(file.path!),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Center(
                                        child: Icon(
                                          _getFileIcon(file.extension),
                                          size: 36,
                                          color: _facebookBlue,
                                        ),
                                      ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedFiles.removeAt(index);
                                            if (index < _selectedImages.length) {
                                              _selectedImages.removeAt(index);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withAlpha(5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Uploaded files section
                if (_uploadedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    color: _cardColor,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Uploaded Files',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _uploadedFiles.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final item = _uploadedFiles[index];
                            final originalname = _safeGetString(
                              item,
                              'originalname',
                              'Unknown',
                            );
                            final filename = _safeGetString(
                              item,
                              'filename',
                              'File $index',
                            );
                            final fileExt = path
                                .extension(originalname)
                                .replaceAll('.', '')
                                .toLowerCase();

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getFileIcon(fileExt),
                                  color: _facebookBlue,
                                ),
                              ),
                              title: Text(
                                originalname,
                                style: TextStyle(color: _textColor),
                              ),
                              subtitle: Text(
                                'Ready to post',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _uploadedFiles.removeAt(index);
                                    _updateButtonState();
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          FloatingMenuWidget(scaffoldKey: _scaffoldKey),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isPostButtonEnabled ? _createPost : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _facebookBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCreatingPost
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Publishing...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Publish',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file;

    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.music_note;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}