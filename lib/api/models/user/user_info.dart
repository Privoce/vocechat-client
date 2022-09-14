import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/api/models/user/user_info_update.dart';

part 'user_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserInfo {
  final int uid;
  final String? email;
  late final String name;
  final int? gender;
  final bool? isAdmin;
  final String? createBy;
  late final String language;
  late final int avatarUpdatedAt;

  UserInfo(this.uid, this.email, String? name, this.gender, String? language,
      this.isAdmin, int? avatarUpdatedAt, this.createBy) {
    if (name != null && name.isNotEmpty) {
      this.name = name;
    } else {
      this.name = "Deleted User";
    }

    this.language = language ?? "en-US";
    this.avatarUpdatedAt = avatarUpdatedAt ?? 0;
  }

  UserInfo.deleted(
      {this.uid = -1,
      this.email,
      this.name = "Deleted User",
      this.gender = 0,
      this.isAdmin,
      this.language = "en-US",
      this.avatarUpdatedAt = 0,
      this.createBy});

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);

  static UserInfo getUpdated(UserInfo oldInfo, UserInfoUpdate update) {
    return UserInfo(
        update.uid,
        update.email ?? oldInfo.email,
        update.name ?? oldInfo.name,
        update.gender ?? oldInfo.gender,
        update.language ?? oldInfo.language,
        update.isAdmin ?? oldInfo.isAdmin,
        update.avatarUpdatedAt ?? oldInfo.avatarUpdatedAt,
        null);
  }
}
