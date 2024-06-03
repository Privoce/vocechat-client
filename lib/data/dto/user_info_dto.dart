import 'package:json_annotation/json_annotation.dart';

part 'user_info_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserInfoDto {
  int? uid;
  String? email;
  String? name;
  int? gender;
  String? language;
  bool? isAdmin;
  bool? isBot;
  int? birthday;
  int? avatarUpdatedAt;
  String? createdBy;

  UserInfoDto({
    this.uid,
    this.email,
    this.name,
    this.gender,
    this.language,
    this.isAdmin,
    this.isBot,
    this.birthday,
    this.avatarUpdatedAt,
    this.createdBy,
  });

  factory UserInfoDto.fromJson(Map<String, dynamic> json) =>
      _$UserInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoDtoToJson(this);
}
