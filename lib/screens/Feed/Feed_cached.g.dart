import 'package:hive/hive.dart';
import 'package:innovator/screens/Feed/Inner_Homepage.dart';

@HiveType(typeId: 0)
class FeedContentAdapter extends TypeAdapter<FeedContent> {
  @override
  final int typeId = 0;

  @override
  FeedContent read(BinaryReader reader) {
    return FeedContent(
      id: reader.read(),
      status: reader.read(),
      type: reader.read(),
      files: List<String>.from(reader.read()),
      author: reader.read(),
      createdAt: reader.read(),
      updatedAt: reader.read(),
      likes: reader.read(),
      comments: reader.read(),
      isLiked: reader.read(),
      isFollowed: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, FeedContent obj) {
    writer.write(obj.id);
    writer.write(obj.status);
    writer.write(obj.type);
    writer.write(obj.files);
    writer.write(obj.author);
    writer.write(obj.createdAt);
    writer.write(obj.updatedAt);
    writer.write(obj.likes);
    writer.write(obj.comments);
    writer.write(obj.isLiked);
    writer.write(obj.isFollowed);
  }
}

@HiveType(typeId: 1)
class AuthorAdapter extends TypeAdapter<Author> {
  @override
  final int typeId = 1;

  @override
  Author read(BinaryReader reader) {
    return Author(
      id: reader.read(),
      name: reader.read(),
      email: reader.read(),
      picture: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Author obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.email);
    writer.write(obj.picture);
  }
}