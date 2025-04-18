import 'package:flutter/material.dart';
import 'package:innovator/screens/Inner_Homepage.dart';
import 'package:innovator/screens/post_card.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(  // Add this wrapper
        child: Column(
          children: [
            // Profile header
            Container(
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=profile'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Senior Developer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Posts', '120'),
                      _buildStatColumn('Followers', '1.5K'),
                      _buildStatColumn('Following', '300'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
            
            // Tabs for different content types
            SizedBox(  // Add fixed height constraint
              height: MediaQuery.of(context).size.height * 0.6,  // Adjust this value as needed
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(icon: Icon(Icons.grid_on)),
                        Tab(icon: Icon(Icons.list)),
                        Tab(icon: Icon(Icons.bookmark)),
                      ],
                    ),
                    Expanded(  // This will now take the remaining space within the SizedBox
                      child: TabBarView(
                        children: [
                          // Grid view of posts
                          GridView.builder(
                            padding: const EdgeInsets.all(2),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                            itemCount: 30,
                            itemBuilder: (context, index) {
                              return Image.network(
                                'https://picsum.photos/500/500?random=$index',
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          
                          // List view of posts
                          ListView.builder(
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              return PostCard(
                                post: Post(
                                  id: 'profile$index',
                                  name: 'John Doe',
                                  position: 'Senior Developer',
                                  description: 'This is one of my posts #$index',
                                  imageUrl: 'https://picsum.photos/500/300?random=profile$index',
                                  likes: 50 + index * 7,
                                  comments: 12 + index * 3,
                                  shares: 5 + index,
                                ),
                              );
                            },
                          ),
                          
                          // Saved posts
                          const Center(
                            child: Text('No saved posts yet'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}