// class Courses {
//   int? status;
//   List<Data>? data;
//   Null? error;
//   String? message;

//   Courses({this.status, this.data, this.error, this.message});

//   Courses.fromJson(Map<String, dynamic> json) {
//     status = json['status'];
//     if (json['data'] != null) {
//       data = <Data>[];
//       json['data'].forEach((v) {
//         data!.add(new Data.fromJson(v));
//       });
//     }
//     error = json['error'];
//     message = json['message'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['status'] = this.status;
//     if (this.data != null) {
//       data['data'] = this.data!.map((v) => v.toJson()).toList();
//     }
//     data['error'] = this.error;
//     data['message'] = this.message;
//     return data;
//   }
// }

// class Data {
//   String? sId;
//   String? title;
//   String? description;
//   Price? price;
//   String? thumbnail;
//   String? syllabus;
//   List<Notes>? notes;
//   Author? author;
//   int? iV;
//   int? likes;
//   int? comments;
//   bool? liked;
//   bool? purchased;

//   Data(
//       {this.sId,
//       this.title,
//       this.description,
//       this.price,
//       this.thumbnail,
//       this.syllabus,
//       this.notes,
//       this.author,
//       this.iV,
//       this.likes,
//       this.comments,
//       this.liked,
//       this.purchased});

//   Data.fromJson(Map<String, dynamic> json) {
//     sId = json['_id'];
//     title = json['title'];
//     description = json['description'];
//     price = json['price'] != null ? new Price.fromJson(json['price']) : null;
//     thumbnail = json['thumbnail'];
//     syllabus = json['syllabus'];
//     if (json['notes'] != null) {
//       notes = <Notes>[];
//       json['notes'].forEach((v) {
//         notes!.add(new Notes.fromJson(v));
//       });
//     }
//     author =
//         json['author'] != null ? new Author.fromJson(json['author']) : null;
//     iV = json['__v'];
//     likes = json['likes'];
//     comments = json['comments'];
//     liked = json['liked'];
//     purchased = json['purchased'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['_id'] = this.sId;
//     data['title'] = this.title;
//     data['description'] = this.description;
//     if (this.price != null) {
//       data['price'] = this.price!.toJson();
//     }
//     data['thumbnail'] = this.thumbnail;
//     data['syllabus'] = this.syllabus;
//     if (this.notes != null) {
//       data['notes'] = this.notes!.map((v) => v.toJson()).toList();
//     }
//     if (this.author != null) {
//       data['author'] = this.author!.toJson();
//     }
//     data['__v'] = this.iV;
//     data['likes'] = this.likes;
//     data['comments'] = this.comments;
//     data['liked'] = this.liked;
//     data['purchased'] = this.purchased;
//     return data;
//   }
// }

// class Price {
//   int? usd;
//   int? npr;
//   String? sId;

//   Price({this.usd, this.npr, this.sId});

//   Price.fromJson(Map<String, dynamic> json) {
//     usd = json['usd'];
//     npr = json['npr'];
//     sId = json['_id'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['usd'] = this.usd;
//     data['npr'] = this.npr;
//     data['_id'] = this.sId;
//     return data;
//   }
// }

// class Notes {
//   String? name;
//   String? pdf;
//   String? sId;

//   Notes({this.name, this.pdf, this.sId});

//   Notes.fromJson(Map<String, dynamic> json) {
//     name = json['name'];
//     pdf = json['pdf'];
//     sId = json['_id'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['name'] = this.name;
//     data['pdf'] = this.pdf;
//     data['_id'] = this.sId;
//     return data;
//   }
// }

// class Author {
//   String? email;
//   String? sId;
//   String? phone;

//   Author({this.email, this.sId, this.phone});

//   Author.fromJson(Map<String, dynamic> json) {
//     email = json['email'];
//     sId = json['_id'];
//     phone = json['phone'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['email'] = email;
//     data['_id'] = sId;
//     data['phone'] = phone;
//     return data;
//   }
// }

class IndividualCourses {}
