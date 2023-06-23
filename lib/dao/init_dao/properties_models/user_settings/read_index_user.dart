import 'package:json_annotation/json_annotation.dart';

part 'read_index_user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ReadIndexUser {
  final int uid;
  final int mid;

  ReadIndexUser({
    required this.uid,
    required this.mid,
  });

  factory ReadIndexUser.fromJson(Map<String, dynamic> json) =>
      _$ReadIndexUserFromJson(json);

  Map<String, dynamic> toJson() => _$ReadIndexUserToJson(this);
}
