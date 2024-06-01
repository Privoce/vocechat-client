// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfoDto _$UserInfoDtoFromJson(Map<String, dynamic> json) => UserInfoDto(
      uid: json['uid'] as int?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      gender: json['gender'] as int?,
      language: json['language'] as String?,
      isAdmin: json['is_admin'] as bool?,
      isBot: json['is_bot'] as bool?,
      birthday: json['birthday'] as int?,
      avatarUpdatedAt: json['avatar_updated_at'] as int?,
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$UserInfoDtoToJson(UserInfoDto instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'name': instance.name,
      'gender': instance.gender,
      'language': instance.language,
      'is_admin': instance.isAdmin,
      'is_bot': instance.isBot,
      'birthday': instance.birthday,
      'avatar_updated_at': instance.avatarUpdatedAt,
      'created_by': instance.createdBy,
    };
