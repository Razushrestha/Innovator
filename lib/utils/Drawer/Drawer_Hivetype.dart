import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class DrawerProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String? picturePath;

  DrawerProfile({
    required this.name,
    required this.email,
    this.picturePath,
  });
}


// Manual adapter class
class DrawerProfileAdapter extends TypeAdapter<DrawerProfile> {
  @override
  final int typeId = 2;

  @override
  DrawerProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrawerProfile(
      name: fields[0] as String,
      email: fields[1] as String,
      picturePath: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DrawerProfile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.picturePath);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawerProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}