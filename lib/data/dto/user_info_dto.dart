import 'package:json_annotation/json_annotation.dart';

part 'user_info_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserInfoDto {
  final int? uid;
  final String? email;
  final String? name;
  final int? gender;
  final String? language;
  final bool? isAdmin;
  final bool? isBot;
  final int? birthday;
  final int? avatarUpdatedAt;
  final String? createdBy;

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
