import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Course/models/api_models.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// Models for API response
class Course {
  final String id;
  final String title;
  final String description;
  final List<Note> notes;
  final Author author;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.notes,
    required this.author,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      notes: (json['notes'] as List?)?.map((note) => Note.fromJson(note)).toList() ?? [],
      author: Author.fromJson(json['author'] ?? {}),
    );
  }
}

class Note {
  final String id;
  final String name;
  final String pdf;
  final bool premium;

  Note({
    required this.id,
    required this.name,
    required this.pdf,
    required this.premium,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      pdf: json['pdf'] ?? '',
      premium: json['premium'] ?? false,
    );
  }
}

class Author {
  final String id;
  final String email;
  final String phone;

  Author({
    required this.id,
    required this.email,
    required this.phone,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class ApiResponse {
  final int status;
  final List<Course> courses;
  final bool hasMore;
  final String? nextCursor;
  final String? error;
  final String message;

  ApiResponse({
    required this.status,
    required this.courses,
    required this.hasMore,
    this.nextCursor,
    this.error,
    required this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? 0,
      courses: (json['data']['courses'] as List?)
          ?.map((course) => Course.fromJson(course))
          .toList() ?? [],
      hasMore: json['data']['hasMore'] ?? false,
      nextCursor: json['data']['nextCursor'],
      error: json['error'],
      message: json['message'] ?? '',
    );
  }
}

// Notes Tab Widget
class NotesTab extends StatefulWidget {
  final String? courseId; // Pass the specific course ID if needed

  const NotesTab({Key? key, this.courseId, required List<Note> notes}) : super(key: key);

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  List<Note> notes = [];
  bool isLoading = true;
  bool isAppDataInitialized = false;
  String? error;
  final AppData _appData = AppData(); // Get singleton instance

  @override
  void initState() {
    super.initState();
    _initializeAppAndFetchNotes();
  }

  // Initialize AppData first, then fetch notes
  Future<void> _initializeAppAndFetchNotes() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Initialize AppData if not already done
      if (!isAppDataInitialized) {
        developer.log('Initializing AppData...');
        await _appData.initialize();
        
        // Initialize FCM as well
        await _appData.initializeFcm();
        
        setState(() {
          isAppDataInitialized = true;
        });
        developer.log('AppData initialized successfully');
      }

      // Now fetch notes
      await fetchNotes();
    } catch (e) {
      developer.log('Error in initialization: $e');
      setState(() {
        error = 'Failed to initialize app: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchNotes() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Check if user is authenticated
      if (!_appData.isAuthenticated) {
        setState(() {
          error = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      // Prepare headers with authentication
      final headers = {
        'Content-Type': 'application/json',
        if (_appData.authToken != null) 'Authorization': 'Bearer ${_appData.authToken}',
      };

      developer.log('Fetching notes with auth token: ${_appData.authToken != null ? "Token exists" : "No token"}');

      final response = await http.get(
        Uri.parse('http://182.93.94.210:3066/api/v1/list-courses'),
        headers: headers,
      );

      developer.log('API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(json.decode(response.body));
        
        // For now, taking notes from the first course
        // You can modify this logic based on your specific course ID
        if (apiResponse.courses.isNotEmpty) {
          // If courseId is provided, find specific course
          Course? selectedCourse;
          if (widget.courseId != null) {
            selectedCourse = apiResponse.courses.firstWhere(
              (course) => course.id == widget.courseId,
              orElse: () => apiResponse.courses.first,
            );
          } else {
            selectedCourse = apiResponse.courses.first;
          }

          setState(() {
            notes = selectedCourse!.notes;
            isLoading = false;
          });
          
          developer.log('Notes loaded successfully: ${notes.length} notes found');
        } else {
          setState(() {
            error = 'No courses found';
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Handle unauthorized - maybe redirect to login
        setState(() {
          error = 'Session expired. Please login again.';
          isLoading = false;
        });
        // You might want to trigger logout here
        // await _appData.logout();
      } else {
        setState(() {
          error = 'Failed to load notes: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error fetching notes: $e');
      setState(() {
        error = 'Error fetching notes: $e';
        isLoading = false;
      });
    }
  }

  void openPdfViewer(String pdfPath, String title) {
    // Construct full URL for PDF
    final String baseUrl = 'http://182.93.94.210:3066';
    final String fullPdfUrl = '$baseUrl$pdfPath';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          pdfUrl: fullPdfUrl,
          title: title,
          authToken: _appData.authToken, // Pass auth token for PDF access
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.purple,
            ),
            SizedBox(height: 16),
            Text(
              'Loading notes...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeAppAndFetchNotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notes available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // Show user info if available
            if (_appData.currentUser != null) ...[
              Text(
                'Logged in as: ${_appData.currentUserEmail ?? _appData.currentUserName ?? "Unknown"}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchNotes,
      color: Colors.purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildNoteItem(note);
        },
      ),
    );
  }

  Widget _buildNoteItem(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.picture_as_pdf,
            color: Colors.purple,
            size: 24,
          ),
        ),
        title: Text(
          note.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'PDF Document',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (note.premium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Free',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: () => openPdfViewer(note.pdf, note.name),
      ),
    );
  }
}

// PDF Viewer Page - Updated to handle authentication
class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String? authToken;

  const PdfViewerPage({
    Key? key,
    required this.pdfUrl,
    required this.title,
    this.authToken,
  }) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.pdfUrl,
            controller: _pdfViewerController,
            headers: widget.authToken != null 
                ? {'Authorization': 'Bearer ${widget.authToken}'}
                : null,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _isLoading = false;
              });
              developer.log('PDF loaded successfully');
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _isLoading = false;
                _error = 'Failed to load PDF: ${details.error}';
              });
              developer.log('PDF load failed: ${details.error}');
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.purple),
                    SizedBox(height: 16),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}