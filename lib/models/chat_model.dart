// user_model.dart

class UserModel {
  final String name;
  final String image;
  final bool isOnline;
  final String message;
  final DateTime lastMessageTime;

  UserModel({
    required this.name,
    required this.image,
    required this.isOnline,
    required this.message,
    required this.lastMessageTime,
  });

  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      image: json['image'],
      isOnline: json['isOnline'],
      message: json['message'],
      lastMessageTime: json['lastMessageTime'],
    );
  }
}

final List<Map<String, dynamic>> users = [
  {
    'name': 'Ronit Srivastava',
    'image': 'assets/user1.jpeg',
    'isOnline': true,
    'message': "Hello Ronit",
    'lastMessageTime': DateTime.now().subtract(Duration(hours: 2)),
  },
  {
    'name': 'Aayush Karki',
    'image': 'assets/user2.png',
    'isOnline': true,
    'message': "Hello Aayush",
    'lastMessageTime': DateTime.now().subtract(Duration(days: 2)),
  },
  {
    'name': 'Razu Shrestha',
    'image': 'assets/user3.jpeg',
    'isOnline': true,
    'message': "Hello Razu",
    'lastMessageTime': DateTime.now().subtract(Duration(minutes: 2)),
  },
  {
    'name': 'Nepa Tronix',
    'image': 'assets/user4.jpg',
    'isOnline': false,
    'message': "Hello Nepa Tronix",
    'lastMessageTime': DateTime.now().subtract(Duration(seconds: 10)),
  },
  {
    'name': 'Prashant Sharma',
    'image': 'assets/user5.jpg',
    'isOnline': false,
    'message': "Hello Prashant",
    'lastMessageTime': DateTime.now().subtract(Duration(hours: 6)),
  },
  {
    'name': 'Innovator All In One',
    'image': 'assets/user6.jpg',
    'isOnline': true,
    'message': "Hello Innovator",
    'lastMessageTime': DateTime.now().subtract(Duration(hours: 23)),
  },
  {
    'name': 'User 7',
    'image': 'assets/user1.jpeg',
    'isOnline': true,
    'message': "Hello User7",
    'lastMessageTime': DateTime.now().subtract(Duration(hours: 1)),
  },
  {
    'name': 'User 8',
    'image': 'assets/user2.png',
    'isOnline': true,
    'message': "Hello User8",
    'lastMessageTime': DateTime.now().subtract(Duration(days: 30)),
  },
  {
    'name': 'User 9',
    'image': 'assets/user3.jpeg',
    'isOnline': true,
    'message': "Hello User9",
    'lastMessageTime': DateTime.now().subtract(Duration(hours: 12)),
  },
  {
    'name': 'User 10',
    'image': 'assets/user4.jpg',
    'isOnline': true,
    'message': "Hello User10",
    'lastMessageTime': DateTime.now().subtract(Duration(hours: 3)),
  },
  {
    'name': 'User 11',
    'image': 'assets/user5.jpg',
    'isOnline': true,
    'message': "Hello User11",
    'lastMessageTime': DateTime.now().subtract(Duration(minutes: 2)),
  },
  {
    'name': 'User 12',
    'image': 'assets/user6.jpg',
    'isOnline': true,
    'message': "Hello User12",
    'lastMessageTime': DateTime.now().subtract(Duration(seconds: 58)),
  },
];

final List<UserModel> sampleUsers =
    users.map((e) => UserModel.fromMap(e)).toList();
