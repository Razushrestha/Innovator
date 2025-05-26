import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:innovator/main.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:path/path.dart' as path;

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
  bool _isUploading = false;
  bool _isCreatingPost = false;
  List<dynamic> _uploadedFiles = [];
  final TextEditingController _descriptionController = TextEditingController();
  final AppData _appData = AppData();
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Post type selection - FIXED: Ensure value matches dropdown item value
  String _selectedPostType = 'innovation'; // Changed to match the id in _postTypes
  final List<Map<String, dynamic>> _postTypes = [
    {'id': 'innovation', 'name': 'Innovation', 'icon': Icons.lightbulb_outline},
    {'id': 'idea', 'name': 'Idea', 'icon': Icons.tips_and_updates},
    {'id': 'project', 'name': 'Project', 'icon': Icons.rocket_launch},
    {'id': 'question', 'name': 'Question', 'icon': Icons.help_outline},
    {'id': 'announcement', 'name': 'Announcement', 'icon': Icons.campaign}, // Fixed typo in 'announcement' and changed icon
    {'id': 'other', 'name': 'Other', 'icon': Icons.more_horiz},
  ];

  // UI Colors
  final Color _primaryColor = const Color.fromRGBO(244, 135, 6, 1);
  final Color _accentColor = const Color.fromARGB(255, 219, 231, 230);
  final Color _facebookBlue = const Color(0xFF1877F2);
  final Color _backgroundColor = const Color(
    0xFFF0F2F5,
  ); // Facebook background color
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _fetchUserProfile();

    // Animation setup for the post button
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start animation when description changes or files are uploaded
    _descriptionController.addListener(_updateButtonState);
  }

  // Listen to changes in the description field and update button state
  // Update button state whenever description or uploaded files change
  void _updateButtonState() {
    if (_isPostButtonEnabled) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    // Force UI update when text changes to update button state
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

  // Check if post button should be enabled - now checks for either description or files
  bool get _isPostButtonEnabled {
    return (_descriptionController.text.isNotEmpty ||
            _uploadedFiles.isNotEmpty) &&
        !_isCreatingPost;
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

        // Automatically start uploading files right after selection
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
          // Update button state after files are uploaded
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
      // Use AuthToken from AppData singleton
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

            // Optionally update the current user data in AppData if needed
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

  Future<void> _createPost() async {
    // Allow posting if either description or files are present
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

      // Create post body with selected type
      final body = {
        'type': _selectedPostType, // Using the correct value directly
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
      _uploadedFiles = [];
      _selectedPostType = 'innovation'; // Reset to default value that matches the id
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    final String baseUrl = 'http://182.93.94.210:3064'; // Base URL for the API
    return Scaffold(
      key: _scaffoldKey, // Add the scaffold key here

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
                                : null, // Removed AssetImage to fix potential error
                            child: picturePath == null
                                ? Icon(Icons.person, size: 40, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display current user name from AppData
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _textColor,
                                  ),
                                ),

                                // Post type dropdown
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
                                          value: type['id'], // Using id as value
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
                              icon: Icons.photo_library,
                              color: Colors.green,
                              label: 'Photos',
                              onTap: _pickFiles,
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
                            // _mediaButton(
                            //   icon: Icons.location_on,
                            //   color: Colors.red.shade700,
                            //   label: 'Location',
                            //   onTap: () {},
                            // ),
                          ],
                        ),
                      ),

                      if (_selectedFiles.isNotEmpty && _isUploading) ...[
                        const SizedBox(height: 20),

                        // Upload status indicator
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

                        // Horizontal file previews
                        Container(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedFiles.length,
                            itemBuilder: (context, index) {
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
                                    Center(
                                      child: Icon(
                                        _getFileIcon(
                                          _selectedFiles[index].extension,
                                        ),
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
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
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
                                    // Update button state after removing file
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

                // Bottom area
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
              color: Colors.black.withOpacity(0.1),
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
                color: color.withOpacity(0.1),
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