import 'package:json_annotation/json_annotation.dart';

part 'mute_user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MuteUser {
  final int gid;
  final int? expiredAt;

  MuteUser({
    required this.gid,
    this.expiredAt,
  });

  factory MuteUser.fromJson(Map<String, dynamic> json) =>
      _$MuteUserFromJson(json);

  Map<String, dynamic> toJson() => _$MuteUserToJson(this);
}
