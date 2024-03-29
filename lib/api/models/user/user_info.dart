import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/api/models/user/user_info_update.dart';

part 'user_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserInfo {
  int uid;
  String? email;
  String name;
  int gender;
  String language;
  bool isAdmin;
  bool? isBot;
  int? birthday;
  int avatarUpdatedAt;
  String? createBy;

  UserInfo(
      {required this.uid,
      required this.email,
      required this.name,
      required this.gender,
      required this.language,
      required this.isAdmin,
      required this.isBot,
      required this.birthday,
      required this.avatarUpdatedAt,
      required this.createBy});

  UserInfo.deleted(
      {this.uid = -1,
      this.email = "",
      this.name = "Deleted User",
      this.gender = -1,
      this.language = "en-US",
      this.isAdmin = false,
      this.isBot = false,
      this.birthday = 0,
      this.avatarUpdatedAt = 0,
      this.createBy = ""});

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);

  static UserInfo getUpdated(UserInfo oldInfo, UserInfoUpdate update) {
    return UserInfo(
        uid: update.uid,
        email: update.email ?? oldInfo.email,
        name: update.name ?? oldInfo.name,
        gender: update.gender ?? oldInfo.gender,
        language: update.language ?? oldInfo.language,
        isAdmin: update.isAdmin ?? oldInfo.isAdmin,
        isBot: update.isBot ?? oldInfo.isBot,
        birthday: update.birthday ?? oldInfo.birthday,
        avatarUpdatedAt: update.avatarUpdatedAt ?? oldInfo.avatarUpdatedAt,
        createBy: update.createdBy ?? oldInfo.createBy);
  }

  Gender get genderType {
    switch (gender) {
      case 0:
        return Gender.male;
      case 1:
        return Gender.female;
      default:
        return Gender.other;
    }
  }
}

enum Gender { male, female, other }
