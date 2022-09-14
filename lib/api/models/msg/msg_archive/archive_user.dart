import 'package:json_annotation/json_annotation.dart';

part 'archive_user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ArchiveUser {
  final String name;
  final int? avatar;

  ArchiveUser({required this.name, required this.avatar});

  factory ArchiveUser.fromJson(Map<String, dynamic> json) =>
      _$ArchiveUserFromJson(json);

  Map<String, dynamic> toJson() => _$ArchiveUserToJson(this);
}
