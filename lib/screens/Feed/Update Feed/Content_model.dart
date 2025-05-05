class ContentModel {
  final String id;
  String status;
  
  ContentModel({
    required this.id,
    required this.status,
  });
  
  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'status': status,
    };
  }
}
