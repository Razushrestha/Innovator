import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as htmlParser;

class EventsHomePage extends StatefulWidget {
  @override
  _EventsHomePageState createState() => _EventsHomePageState();
}

class _EventsHomePageState extends State<EventsHomePage>
    with TickerProviderStateMixin {
  List<TechEvent> events = [];
  List<TechEvent> filteredEvents = [];
  bool isLoading = true;
  String selectedCountry = 'All';
  String searchQuery = '';
  late TabController _tabController;
  Timer? _refreshTimer;
  
  final List<String> countries = [
    'All', 'Nepal', 'India', 'USA', 'UK', 'Germany', 'Singapore', 'Japan', 'Australia', 'Canada', 'France'
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadEvents();
    loadFavorites();
    // Auto-refresh every 2 hours
    _refreshTimer = Timer.periodic(Duration(hours: 2), (timer) {
      loadEvents();
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

 Future<void> loadEvents() async {
  setState(() {
    isLoading = true;
  });

  String? cachedEventsJson; // Define cachedEventsJson at the method scope
  try {
    final List<TechEvent> fetchedEvents = [];
    final prefs = await SharedPreferences.getInstance();

    // Load cached events if available
    cachedEventsJson = prefs.getString('cached_events');
    if (cachedEventsJson != null) {
      final List<dynamic> cachedEventsData = json.decode(cachedEventsJson);
      setState(() {
        events = cachedEventsData
            .map((eventJson) => TechEvent.fromJson(eventJson))
            .toList();
        filteredEvents = events;
        isLoading = false;
      });
      filterEvents();
      await loadFavorites();
    } else {
      // No cache exists, show loading state
      setState(() {
        events = [];
        filteredEvents = [];
        isLoading = true;
      });
    }

    // Fetch new events from multiple sources concurrently
    final results = await Future.wait([
      fetchDevEventsData(),
      fetchGDGEvents(),
      fetchMeetupEvents(),
      fetchTechConferences(),
      fetchGitHubEvents(),
    ]);

    for (var eventList in results) {
      fetchedEvents.addAll(eventList);
    }

    // Remove duplicates based on title and date
    final uniqueEvents = <String, TechEvent>{};
    for (var event in fetchedEvents) {
      final key = '${event.title.toLowerCase()}_${event.date.toString().substring(0, 10)}';
      if (!uniqueEvents.containsKey(key)) {
        uniqueEvents[key] = event;
      }
    }

    final newEvents = uniqueEvents.values.toList();

    // Check if new or updated events exist
    bool hasNewEvents = true;
    if (cachedEventsJson != null) {
      final List<TechEvent> cachedEvents = (json.decode(cachedEventsJson) as List)
          .map((eventJson) => TechEvent.fromJson(eventJson))
          .toList();
      hasNewEvents = _hasNewEvents(newEvents, cachedEvents);
    }

    if (hasNewEvents) {
      // Merge favorite status from cached events to new events
      if (cachedEventsJson != null) {
        final List<TechEvent> cachedEvents = (json.decode(cachedEventsJson) as List)
            .map((eventJson) => TechEvent.fromJson(eventJson))
            .toList();
        for (var newEvent in newEvents) {
          final cachedEvent = cachedEvents.firstWhere(
            (e) => e.id == newEvent.id,
            orElse: () => TechEvent(
              id: '',
              title: '',
              description: '',
              location: '',
              country: '',
              date: DateTime.now(),
              url: '',
              category: '',
              price: '',
              organizer: '',
            ),
          );
          if (cachedEvent.id.isNotEmpty) {
            newEvent.isFavorite = cachedEvent.isFavorite;
          }
        }
      }

      // Save new events to cache
      final eventsJson = json.encode(newEvents.map((e) => {
            'id': e.id,
            'title': e.title,
            'description': e.description,
            'location': e.location,
            'country': e.country,
            'date': e.date.toIso8601String(),
            'url': e.url,
            'category': e.category,
            'price': e.price,
            'organizer': e.organizer,
            'isFavorite': e.isFavorite,
          }).toList());
      await prefs.setString('cached_events', eventsJson);

      // Update state with new events
      setState(() {
        events = newEvents;
        filteredEvents = events;
        isLoading = false;
      });
      filterEvents();
      await loadFavorites();

      // Notify user of new events
      if (cachedEventsJson != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New events loaded and Saved')),
        );
      }
    } else if (cachedEventsJson == null) {
      // No cache existed, save and update with fetched events
      final eventsJson = json.encode(newEvents.map((e) => {
            'id': e.id,
            'title': e.title,
            'description': e.description,
            'location': e.location,
            'country': e.country,
            'date': e.date.toIso8601String(),
            'url': e.url,
            'category': e.category,
            'price': e.price,
            'organizer': e.organizer,
            'isFavorite': e.isFavorite,
          }).toList());
      await prefs.setString('cached_events', eventsJson);

      setState(() {
        events = newEvents;
        filteredEvents = events;
        isLoading = false;
      });
      filterEvents();
      await loadFavorites();
    } else {
      // No new events, ensure UI is updated if not already
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cachedEventsJson == null
            ? 'Error loading events: $e. No cached events available.'
            : 'Error fetching new events: $e. Showing cached events.'),
      ),
    );
  }
}

// Helper method to check if new events exist
bool _hasNewEvents(List<TechEvent> newEvents, List<TechEvent> cachedEvents) {
  if (newEvents.length != cachedEvents.length) return true;

  final newEventKeys = newEvents
      .map((e) => '${e.id}_${e.title.toLowerCase()}_${e.date.toString().substring(0, 10)}')
      .toSet();
  final cachedEventKeys = cachedEvents
      .map((e) => '${e.id}_${e.title.toLowerCase()}_${e.date.toString().substring(0, 10)}')
      .toSet();

  return !newEventKeys.containsAll(cachedEventKeys) ||
      !cachedEventKeys.containsAll(newEventKeys);
}

  // Fetch from dev.events using web scraping
  Future<List<TechEvent>> fetchDevEventsData() async {
    try {
      final List<TechEvent> devEvents = [];
      
      // Scrape dev.events for tech conferences
      final response = await http.get(
        Uri.parse('https://dev.events/tech'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = htmlParser.parse(response.body);
        final eventElements = document.querySelectorAll('.event-item, .conference-item, .event-card');

        for (var element in eventElements) {
          try {
            final title = element.querySelector('.event-title, .title, h3, h2')?.text?.trim() ?? '';
            final description = element.querySelector('.event-description, .description, p')?.text?.trim() ?? '';
            final location = element.querySelector('.event-location, .location')?.text?.trim() ?? '';
            final dateText = element.querySelector('.event-date, .date')?.text?.trim() ?? '';
            final url = element.querySelector('a')?.attributes['href'] ?? '';
            
            if (title.isNotEmpty) {
              devEvents.add(TechEvent(
                id: 'dev_${title.replaceAll(' ', '_').toLowerCase()}',
                title: title,
                description: description.isNotEmpty ? description : 'Tech conference focusing on latest technologies',
                location: location.isNotEmpty ? location : 'Various Locations',
                country: _extractCountryFromLocation(location),
                date: _parseDate(dateText),
                url: url.startsWith('http') ? url : 'https://dev.events$url',
                category: _categorizeEvent(title + ' ' + description),
                price: 'TBD',
                organizer: 'dev.events',
              ));
            }
          } catch (e) {
            print('Error parsing dev.events item: $e');
          }
        }
      }

      return devEvents;
    } catch (e) {
      print('Error fetching dev.events: $e');
      return [];
    }
  }

  // Fetch Google Developer Group events
  Future<List<TechEvent>> fetchGDGEvents() async {
    try {
      final List<TechEvent> gdgEvents = [];
      
      // Use GDG Community API endpoints
      final response = await http.get(
        Uri.parse('https://gdg.community.dev/api/events/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; TechEventsApp/1.0)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final eventsList = data['results'] ?? data['events'] ?? [];

        for (var eventData in eventsList) {
          try {
            gdgEvents.add(TechEvent(
              id: 'gdg_${eventData['id'] ?? eventData['slug'] ?? ''}',
              title: eventData['title'] ?? eventData['name'] ?? '',
              description: eventData['description'] ?? eventData['summary'] ?? '',
              location: eventData['location'] ?? '${eventData['city'] ?? ''}, ${eventData['country'] ?? ''}',
              country: eventData['country'] ?? _extractCountryFromLocation(eventData['location'] ?? ''),
              date: DateTime.tryParse(eventData['start_date'] ?? eventData['date'] ?? '') ?? 
                    DateTime.now().add(Duration(days: 30)),
              url: eventData['url'] ?? eventData['link'] ?? 'https://gdg.community.dev',
              category: 'Google Developer Group',
              price: 'Free',
              organizer: eventData['organizer'] ?? 'GDG Community',
            ));
          } catch (e) {
            print('Error parsing GDG event: $e');
          }
        }
      }

      return gdgEvents;
    } catch (e) {
      print('Error fetching GDG events: $e');
      return _getFallbackGDGEvents();
    }
  }

  // Fetch Meetup events using their API
  Future<List<TechEvent>> fetchMeetupEvents() async {
    try {
      final List<TechEvent> meetupEvents = [];
      
      // Use Meetup's GraphQL API (public endpoints)
      final queries = ['tech', 'programming', 'developer', 'AI', 'blockchain'];
      
      for (String query in queries) {
        try {
          final response = await http.get(
            Uri.parse('https://www.meetup.com/gql'),
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; TechEventsApp/1.0)',
              'Accept': 'application/json',
            },
          );

          // Fallback to scraping Meetup pages
          final scrapingResponse = await http.get(
            Uri.parse('https://www.meetup.com/find/?keywords=$query'),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          );

          if (scrapingResponse.statusCode == 200) {
            final document = htmlParser.parse(scrapingResponse.body);
            final eventElements = document.querySelectorAll('[data-testid="event-card"]');

            for (var element in eventElements.take(5)) {
              try {
                final title = element.querySelector('h3')?.text?.trim() ?? '';
                final description = element.querySelector('p')?.text?.trim() ?? '';
                final location = element.querySelector('[data-testid="event-location"]')?.text?.trim() ?? '';
                final dateText = element.querySelector('[data-testid="event-datetime"]')?.text?.trim() ?? '';
                
                if (title.isNotEmpty) {
                  meetupEvents.add(TechEvent(
                    id: 'meetup_${title.replaceAll(' ', '_').toLowerCase()}',
                    title: title,
                    description: description,
                    location: location,
                    country: _extractCountryFromLocation(location),
                    date: _parseDate(dateText),
                    url: 'https://www.meetup.com/find/?keywords=$query',
                    category: _categorizeEvent(title + ' ' + description),
                    price: 'Free',
                    organizer: 'Meetup Community',
                  ));
                }
              } catch (e) {
                print('Error parsing Meetup event: $e');
              }
            }
          }
        } catch (e) {
          print('Error with Meetup query $query: $e');
        }
      }

      return meetupEvents.isNotEmpty ? meetupEvents : _getFallbackMeetupEvents();
    } catch (e) {
      print('Error fetching Meetup events: $e');
      return _getFallbackMeetupEvents();
    }
  }

  // Fetch tech conferences from various sources
  Future<List<TechEvent>> fetchTechConferences() async {
    try {
      final List<TechEvent> conferences = [];
      
      // Scrape conference websites
      final conferenceSites = [
        'https://confs.tech/json',
        'https://techconferences.org/api/events',
      ];

      for (String url in conferenceSites) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; TechEventsApp/1.0)',
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final eventsList = data is List ? data : (data['events'] ?? []);

            for (var eventData in eventsList.take(20)) {
              try {
                conferences.add(TechEvent(
                  id: 'conf_${eventData['name']?.toString().replaceAll(' ', '_').toLowerCase() ?? ''}',
                  title: eventData['name'] ?? eventData['title'] ?? '',
                  description: eventData['description'] ?? eventData['summary'] ?? 'Technology conference',
                  location: '${eventData['city'] ?? ''}, ${eventData['country'] ?? ''}',
                  country: eventData['country'] ?? _extractCountryFromLocation(eventData['location'] ?? ''),
                  date: DateTime.tryParse(eventData['startDate'] ?? eventData['date'] ?? '') ?? 
                        DateTime.now().add(Duration(days: 45)),
                  url: eventData['url'] ?? eventData['website'] ?? '',
                  category: _categorizeEvent(eventData['topics']?.join(', ') ?? eventData['category'] ?? 'Tech Conference'),
                  price: eventData['price'] ?? 'TBD',
                  organizer: eventData['organizer'] ?? 'Conference Organizer',
                ));
              } catch (e) {
                print('Error parsing conference event: $e');
              }
            }
          }
        } catch (e) {
          print('Error fetching from $url: $e');
        }
      }

      return conferences.isNotEmpty ? conferences : _getFallbackConferences();
    } catch (e) {
      print('Error fetching tech conferences: $e');
      return _getFallbackConferences();
    }
  }

  // Fetch GitHub events and developer meetups
  Future<List<TechEvent>> fetchGitHubEvents() async {
    try {
      final List<TechEvent> githubEvents = [];
      
      // Use GitHub's public API for events
      final response = await http.get(
        Uri.parse('https://api.github.com/events'),
        headers: {
          'User-Agent': 'TechEventsApp/1.0',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final events = json.decode(response.body);
        
        for (var event in events.take(10)) {
          if (event['type'] == 'PublicEvent' || event['type'] == 'CreateEvent') {
            try {
              final repo = event['repo']['name'] ?? '';
              final actor = event['actor']['display_login'] ?? '';
              
              githubEvents.add(TechEvent(
                id: 'github_${event['id']}',
                title: 'Open Source: ${repo.split('/').last}',
                description: 'Latest development in ${repo} repository',
                location: 'Online',
                country: 'Global',
                date: DateTime.tryParse(event['created_at'] ?? '') ?? DateTime.now(),
                url: 'https://github.com/$repo',
                category: 'Open Source',
                price: 'Free',
                organizer: actor,
              ));
            } catch (e) {
              print('Error parsing GitHub event: $e');
            }
          }
        }
      }

      return githubEvents;
    } catch (e) {
      print('Error fetching GitHub events: $e');
      return [];
    }
  }

  // Fallback events when APIs fail
  List<TechEvent> _getFallbackGDGEvents() {
    return [
      TechEvent(
        id: 'gdg_devfest_2025',
        title: 'DevFest 2025 - Global',
        description: 'Community-run developer events hosted by Google Developer Groups around the world',
        location: 'Multiple Cities',
        country: 'Global',
        date: DateTime.now().add(Duration(days: 30)),
        url: 'https://gdg.community.dev/events/',
        category: 'Google Developer Group',
        price: 'Free',
        organizer: 'GDG Community',
      ),
    ];
  }

  List<TechEvent> _getFallbackMeetupEvents() {
    return [
      TechEvent(
        id: 'meetup_tech_global',
        title: 'Global Tech Meetups',
        description: 'Join local tech communities and developer meetups worldwide',
        location: 'Various Cities',
        country: 'Global',
        date: DateTime.now().add(Duration(days: 7)),
        url: 'https://www.meetup.com/topics/tech/',
        category: 'Networking',
        price: 'Free',
        organizer: 'Meetup Communities',
      ),
    ];
  }

  List<TechEvent> _getFallbackConferences() {
    return [
      TechEvent(
        id: 'conf_tech_2025',
        title: 'Global Tech Conference 2025',
        description: 'Annual technology conference featuring latest innovations and trends',
        location: 'San Francisco, USA',
        country: 'USA',
        date: DateTime.now().add(Duration(days: 60)),
        url: 'https://dev.events/tech',
        category: 'Technology',
        price: '\$299',
        organizer: 'Tech Conference Org',
      ),
    ];
  }

  String _extractCountryFromLocation(String location) {
    final countryMappings = {
      'usa': 'USA', 'united states': 'USA', 'us': 'USA',
      'india': 'India', 'in': 'India',
      'nepal': 'Nepal', 'np': 'Nepal',
      'uk': 'UK', 'united kingdom': 'UK', 'britain': 'UK',
      'germany': 'Germany', 'de': 'Germany',
      'singapore': 'Singapore', 'sg': 'Singapore',
      'japan': 'Japan', 'jp': 'Japan',
      'australia': 'Australia', 'au': 'Australia',
      'canada': 'Canada', 'ca': 'Canada',
      'france': 'France', 'fr': 'France',
    };

    final locationLower = location.toLowerCase();
    for (var entry in countryMappings.entries) {
      if (locationLower.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Global';
  }

  DateTime _parseDate(String dateText) {
    try {
      // Try various date formats
      final cleanDate = dateText.replaceAll(RegExp(r'[^\d\-/\s:]'), '').trim();
      
      // Try parsing different formats
      final formats = [
        RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
        RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
        RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
      ];

      for (var format in formats) {
        final match = format.firstMatch(cleanDate);
        if (match != null) {
          try {
            return DateTime.parse('${match.group(1)}-${match.group(2)}-${match.group(3)}');
          } catch (e) {
            // Try different order
            try {
              return DateTime.parse('${match.group(3)}-${match.group(1)}-${match.group(2)}');
            } catch (e) {
              continue;
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing date: $dateText');
    }
    
    // Return a future date if parsing fails
    return DateTime.now().add(Duration(days: 30 + (dateText.hashCode % 60).abs()));
  }

  String _categorizeEvent(String text) {
    final textLower = text.toLowerCase();
    
    if (textLower.contains('ai') || textLower.contains('artificial intelligence') || textLower.contains('machine learning')) {
      return 'Artificial Intelligence';
    } else if (textLower.contains('mobile') || textLower.contains('android') || textLower.contains('ios') || textLower.contains('flutter')) {
      return 'Mobile Development';
    } else if (textLower.contains('web') || textLower.contains('javascript') || textLower.contains('react') || textLower.contains('vue')) {
      return 'Web Development';
    } else if (textLower.contains('blockchain') || textLower.contains('crypto') || textLower.contains('bitcoin')) {
      return 'Blockchain';
    } else if (textLower.contains('security') || textLower.contains('cyber')) {
      return 'Security';
    } else if (textLower.contains('devops') || textLower.contains('cloud') || textLower.contains('aws') || textLower.contains('docker')) {
      return 'DevOps & Cloud';
    } else if (textLower.contains('python') || textLower.contains('java') || textLower.contains('golang')) {
      return 'Programming Languages';
    } else if (textLower.contains('data') || textLower.contains('analytics') || textLower.contains('big data')) {
      return 'Data Science';
    } else if (textLower.contains('open source') || textLower.contains('github')) {
      return 'Open Source';
    } else {
      return 'General Tech';
    }
  }

  void filterEvents() {
    setState(() {
      filteredEvents = events.where((event) {
        bool matchesCountry = selectedCountry == 'All' || event.country == selectedCountry;
        bool matchesSearch = searchQuery.isEmpty ||
            event.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            event.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
            event.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
            event.location.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesCountry && matchesSearch;
      }).toList();
      
      // Sort by date (upcoming first)
      filteredEvents.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_events') ?? [];
    
    setState(() {
      for (var event in events) {
        event.isFavorite = favoriteIds.contains(event.id);
      }
    });
  }

  Future<void> toggleFavorite(TechEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_events') ?? [];
    
    setState(() {
      event.isFavorite = !event.isFavorite;
    });
    
    if (event.isFavorite) {
      favoriteIds.add(event.id);
    } else {
      favoriteIds.remove(event.id);
    }
    
    await prefs.setStringList('favorite_events', favoriteIds);
  }

  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Global Tech Events',style: TextStyle(color: Colors.white),
         ),
         backgroundColor: Color.fromRGBO(244, 135, 6, 1),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadEvents,
            color: Colors.white,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedCountry = value;
              });
              filterEvents();
            },
            itemBuilder: (context) => countries.map((country) =>
              PopupMenuItem(value: country, child: Text(country))
            ).toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_list, color: Colors.white),
                Text(' $selectedCountry', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Events', icon: Icon(Icons.event, color: Colors.white,)),
            Tab(text: 'Favorites', icon: Icon(Icons.favorite, color: Colors.white,)),
            Tab(text: 'Categories', icon: Icon(Icons.category, color: Colors.white,)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search events, locations, categories...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                filterEvents();
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsList(filteredEvents),
                _buildEventsList(filteredEvents.where((e) => e.isFavorite).toList()),
                _buildCategoriesView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadEvents,
        child: Icon(Icons.refresh, color: Colors.white,),
        backgroundColor: Color.fromRGBO(244, 135, 6, 1),
      ),
    );
  }

  Widget _buildEventsList(List<TechEvent> eventsList) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Tech events from around the world...'),
            SizedBox(height: 8),
            // Text('Fetching from dev.events, GDG, Meetup, and more', 
            //      style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (eventsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No events found'),
            SizedBox(height: 8),
            Text('Try adjusting your filters or refresh'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadEvents,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: eventsList.length,
        itemBuilder: (context, index) {
          final event = eventsList[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventCard(TechEvent event) {
    final bool isUpcoming = event.date.isAfter(DateTime.now());
    final int daysUntil = event.date.difference(DateTime.now()).inDays;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => launchURL(event.url),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          event.organizer,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      event.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: event.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => toggleFavorite(event),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                event.description,
                style: TextStyle(fontSize: 14, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(event.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.category,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        '${event.date.day}/${event.date.month}/${event.date.year}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (isUpcoming) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: daysUntil <= 7 ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            daysUntil == 0 ? 'Today' : 
                            daysUntil == 1 ? 'Tomorrow' : 
                            '$daysUntil days',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.monetization_on, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        event.price,
                        style: TextStyle(
                          color: event.price.toLowerCase() == 'free' 
                            ? Colors.green 
                            : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: event.price.toLowerCase() == 'free' 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesView() {
    final categories = events.map((e) => e.category).toSet().toList();
    categories.sort();

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryEvents = events.where((e) => e.category == category).length;
        
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(category),
              child: Icon(
                _getCategoryIcon(category),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(category),
            subtitle: Text('$categoryEvents events'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              setState(() {
                searchQuery = category;
                _tabController.animateTo(0);
              });
              filterEvents();
            },
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'artificial intelligence':
      case 'ai':
        return Colors.purple;
      case 'mobile development':
        return Colors.blue;
      case 'web development':
        return Colors.orange;
      case 'blockchain':
        return Colors.green;
      case 'security':
        return Colors.red;
      case 'devops':
        return Colors.teal;
      case 'fintech':
        return Colors.indigo;
      case 'cloud computing':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'artificial intelligence':
      case 'ai':
        return Icons.psychology;
      case 'mobile development':
        return Icons.phone_android;
      case 'web development':
        return Icons.web;
      case 'blockchain':
        return Icons.link;
      case 'security':
        return Icons.security;
      case 'devops':
        return Icons.settings;
      case 'fintech':
        return Icons.attach_money;
      case 'cloud computing':
        return Icons.cloud;
      default:
        return Icons.event;
    }
  }
}

class TechEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final String country;
  final DateTime date;
  final String url;
  final String category;
  final String price;
  final String organizer;
  bool isFavorite;

  TechEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.country,
    required this.date,
    required this.url,
    required this.category,
    required this.price,
    required this.organizer,
    this.isFavorite = false,
  });

  factory TechEvent.fromJson(Map<String, dynamic> json) {
    return TechEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      country: json['country'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      url: json['url'] ?? '',
      category: json['category'] ?? 'General',
      price: json['price'] ?? 'N/A',
      organizer: json['organizer'] ?? '',
    );
  }
}
