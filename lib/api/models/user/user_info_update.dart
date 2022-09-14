import 'package:json_annotation/json_annotation.dart';

part 'user_info_update.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserInfoUpdate {
  final int uid;
  final String? email;
  final String? name;
  final int? gender;
  final String? language;
  final bool? isAdmin;
  final int? avatarUpdatedAt;

  UserInfoUpdate(this.uid, this.email, this.name, this.gender, this.language,
      this.isAdmin, this.avatarUpdatedAt);

  factory UserInfoUpdate.fromJson(Map<String, dynamic> json) =>
      _$UserInfoUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoUpdateToJson(this);
}
