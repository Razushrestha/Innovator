import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:innovator/sample/screens/course/projects.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class CoursePage extends StatelessWidget {
  final List<Map<String, dynamic>> books = [
    {'title': 'Basic Electronics', 'icon': Icons.book},
    {'title': 'Electronics Books', 'icon': Icons.book_online},
    {'title': 'Robotics Books', 'icon': Icons.android},
    {'title': 'Notes', 'icon': Icons.note},
    {'title': 'Projects', 'icon': Icons.build},
  ];

  CoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Courses'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () {
              if (book['title'] == 'Basic Electronics') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BasicElectronicsPage(),
                  ),
                );
              } else if (book['title'] == 'Notes') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotesPage(),
                  ),
                );
              } else if (book['title'] == 'Projects') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectsPage(),
                  ),
                );
                // Handle other book navigations
              }
            },
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      book['icon'] as IconData,
                      size: 50,
                      color: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Text(
                      book['title']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BasicElectronicsPage extends StatelessWidget {
  final List<Map<String, String>> subtopics = [
    {
      'title': 'Resistor',
      'description': 'Learn about resistors and their uses.'
    },
    {
      'title': 'Capacitor',
      'description': 'Understand capacitors and their applications.'
    },
    {'title': 'Diode', 'description': 'Explore diodes and their functions.'},
    {
      'title': 'Transistor',
      'description': 'Discover transistors and their importance.'
    },
  ];

  BasicElectronicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Basic Electronics'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: subtopics.length,
        itemBuilder: (context, index) {
          final subtopic = subtopics[index];
          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Text(
                subtopic['title']!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(subtopic['description']!),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SubtopicPage(title: subtopic['title']!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SubtopicPage extends StatelessWidget {
  final String title;

  const SubtopicPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: title == 'Resistor'
          ? ResistorPage()
          : Center(
              child: Text(
                'Content for $title',
                style: TextStyle(fontSize: 24),
              ),
            ),
    );
  }
}

class ResistorPage extends StatefulWidget {
  const ResistorPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ResistorPageState createState() => _ResistorPageState();
}

class _ResistorPageState extends State<ResistorPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isMuted = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/images/resistor.mp4');
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.setVolume(1.0);
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          colors: VideoProgressColors(
            playedColor: Colors.blueAccent,
            bufferedColor: Colors.lightBlueAccent,
            backgroundColor: Colors.grey,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Resistors are passive electrical components that provide resistance to the flow of current. They are used to control the voltage and current in a circuit. Resistors come in various types and values, and they are essential components in electronic circuits.',
            style: TextStyle(fontSize: 16),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.replay_10),
              onPressed: () {
                final currentPosition = _controller.value.position;
                final newPosition = currentPosition - Duration(seconds: 10);
                _controller.seekTo(newPosition);
              },
            ),
            IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.forward_10),
              onPressed: () {
                final currentPosition = _controller.value.position;
                final newPosition = currentPosition + Duration(seconds: 10);
                _controller.seekTo(newPosition);
              },
            ),
            IconButton(
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: _toggleMute,
            ),
            IconButton(
              icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
              onPressed: _toggleFullScreen,
            ),
          ],
        ),
      ],
    );
  }
}

class NotesPage extends StatelessWidget {
  final List<Map<String, String>> notes = [
    {'title': 'Resistor', 'file': 'assets/pdfs/resistor.pdf'},
    {'title': 'Capacitor', 'file': 'assets/pdfs/capacitor.pdf'},
    {'title': 'Diode', 'file': 'assets/pdfs/diode.pdf'},
  ];

  NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Text(
                note['title']!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PdfViewerPage(filePath: note['file']!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final String filePath;

  const PdfViewerPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}
