import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

class _CreatePostScreenState extends State<CreatePostScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  bool _isCreatingPost = false;
  List<dynamic> _uploadedFiles = [];
  final TextEditingController _descriptionController = TextEditingController();
  final AppData _appData = AppData();
  
  final Color _primaryColor = const Color.fromRGBO(244, 135, 6, 1);
  final Color _accentColor = const Color.fromARGB(255, 219, 231, 230);
  final Color _backgroundColor = const Color(0xFFF5F5F7);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);
  
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    debugPrint('CreatePostScreen: Auth status - isAuthenticated: ${_appData.isAuthenticated}');
    if (_appData.authToken != null) {
      debugPrint('CreatePostScreen: Auth token available');
    } else {
      debugPrint('CreatePostScreen: No auth token available');
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

    if (!_appData.isAuthenticated) {
      _showError('Please log in first');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadUrl = 'http://182.93.94.210:3064/api/v1/add-files?subfolder=posts';
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(uploadUrl),
      );

      request.headers['authorization'] = 'Bearer ${_appData.authToken}';

      for (var file in _selectedFiles) {
        final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
        
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

  Future<void> _createPost() async {
    if (_uploadedFiles.isEmpty) {
      _showError('Please upload files first');
      return;
    }

    if (!_appData.isAuthenticated) {
      _showError('Please log in first');
      return;
    }

    setState(() {
      _isCreatingPost = true;
    });

    try {
      final createUrl = 'http://182.93.94.210:3064/api/v1/new-content';
      final body = {
        'type': 'innovation',
        'status': _descriptionController.text,
        'description': _descriptionController.text,
        'files': _uploadedFiles
      };
      
      var response = await http.post(
        Uri.parse(createUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_appData.authToken}'
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Post created successfully!');
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10,),
              // Content creation card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: _cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Your Post',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Description field
                      TextField(
                        controller: _descriptionController,
                        style: TextStyle(color: _textColor),
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: _primaryColor),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryColor, width: 2),
                          ),
                          prefixIcon: Icon(Icons.description, color: _primaryColor),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
              // File selection card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: _cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_file, color: _primaryColor, size: 26),
                          const SizedBox(width: 12),
                          Text(
                            'Attach Files',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      GestureDetector(
                        onTap: _isUploading ? null : _pickFiles,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload, size: 40, color: _primaryColor),
                                const SizedBox(height: 8),
                                Text(
                                  'Click to select files',
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Selected Files (${_selectedFiles.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedFiles.length,
                            separatorBuilder: (context, index) => Divider(color: Colors.grey.shade300),
                            itemBuilder: (context, index) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: Icon(
                                  _getFileIcon(_selectedFiles[index].extension),
                                  color: _primaryColor,
                                ),
                                title: Text(
                                  _selectedFiles[index].name,
                                  style: TextStyle(color: _textColor),
                                ),
                                subtitle: Text(
                                  '${(_selectedFiles[index].size / 1024).toStringAsFixed(2)} KB',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.close, color: Colors.red.shade400),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFiles.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Upload button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_selectedFiles.isNotEmpty && !_isUploading) ? _uploadFiles : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: _isUploading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Uploading...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Upload Files',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Uploaded files section (only shown after files are uploaded)
              if (_uploadedFiles.isNotEmpty) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: _cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Uploaded Files',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _uploadedFiles.length,
                          separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final item = _uploadedFiles[index];
                            final originalname = _safeGetString(item, 'originalname', 'Unknown');
                            final filename = _safeGetString(item, 'filename', 'File $index');
                            final fileExt = path.extension(originalname).replaceAll('.', '').toLowerCase();
                            
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(_getFileIcon(fileExt), color: _accentColor),
                              title: Text(originalname, style: TextStyle(color: _textColor)),
                              subtitle: Text(
                                'Uploaded successfully',
                                style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Create post button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isCreatingPost ? null : _createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: _isCreatingPost
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Creating Post...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.create, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Create Post',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
              
              const SizedBox(height: 30),
            ],
          ),
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