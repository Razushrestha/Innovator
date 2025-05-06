class Courses {
  final String? error;
  final String message;
  final List<Data> data;
  final int status;
  Courses(
      {required this.error,
      required this.message,
      required this.data,
      required this.status});
  factory Courses.fromJson(Map<String, dynamic> json) {
    return Courses(
        error: json['error'],
        message: json['message'],
        data: List<Data>.from(json['data'].map((e) => Data.fromJson(e))),
        status: json['status']);
  }
  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
      'status': status
    };
  }
}

class Data {
  final String id;
  final String title;
  final String description;
  final Price price;
  final String thumbnail;

  final List<Notes> notes;
  final Author author;
  final int v;
  final int likes;
  final int comments;
  final bool liked;
  final bool purchased;
  Data({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.thumbnail,
    required this.notes,
    required this.author,
    required this.v,
    required this.likes,
    required this.liked,
    required this.comments,
    required this.purchased,
  });
  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
        id: json['_id'],
        title: json['title'].toString(),
        description: json['description'],
        price: Price.fromJson(json['price']),
        thumbnail: json['thumbnail'],
        notes: List<Notes>.from(json['notes'].map((e) => Notes.fromJson(e))),
        author: Author.fromJson(json['author']),
        v: json['__v'],
        likes: json['likes'],
        liked: json['liked'],
        comments: json['comments'],
        purchased: json['purchased']);
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'price': price.toJson(),
      'thumbnail': thumbnail,
      'notes': notes.map((e) => e.toJson()).toList(),
      'author': author.toJson(),
      '__v': v,
      'likes': likes,
      'liked': liked,
      'comments': comments,
      'purchased': purchased
    };
  }
}

class Price {
  final int usd;
  final int npr;
  final String id;
  Price({required this.usd, required this.npr, required this.id});
  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(usd: json['usd'], npr: json['npr'], id: json['_id']);
  }
  Map<String, dynamic> toJson() {
    return {'usd': usd, 'npr': npr, '_id': id};
  }
}

class Notes {
  final String name;
  final String pdf;
  final bool premium;
  final String id;
  Notes(
      {required this.name,
      required this.pdf,
      required this.id,
      required this.premium});
  factory Notes.fromJson(Map<String, dynamic> json) {
    return Notes(
        name: json['name'],
        pdf: json['pdf'],
        id: json['_id'],
        premium: json['premium']);
  }
  Map<String, dynamic> toJson() {
    return {'name': name, 'pdf': pdf, '_id': id};
  }
}

class Author {
  final String email;
  final String id;
  final String phone;
  Author({required this.email, required this.id, required this.phone});
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(email: json['email'], id: json['_id'], phone: json['phone']);
  }
  Map<String, dynamic> toJson() {
    return {'email': email, '_id': id, 'phone': phone};
  }
}
