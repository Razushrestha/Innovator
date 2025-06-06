import 'package:hive/hive.dart';
import 'package:innovator/screens/Profile/profile_page.dart';

@HiveType(typeId: 0)
class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    return UserProfile(
      id: reader.readString(),
      name: reader.readString(),
      email: reader.readString(),
      phone: reader.readString(),
      dob: DateTime.parse(reader.readString()),
      role: reader.readString(), 
      level: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
      picture: reader.readString(),
      gender: reader.readString(),
      location: reader.readString(),
      bio: reader.readString(),
      education: reader.readString(),
      profession: reader.readString(),
      achievements: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.email);
    writer.writeString(obj.phone);
    writer.writeString(obj.dob.toIso8601String());
    writer.writeString(obj.role);
    writer.writeString(obj.level);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeString(obj.picture ?? '');
    writer.writeString(obj.gender ?? '');
    writer.writeString(obj.location ?? '');
    writer.writeString(obj.bio ?? '');
    writer.writeString(obj.education ?? '');
    writer.writeString(obj.profession ?? '');
    writer.writeString(obj.achievements ?? '');
  }
}