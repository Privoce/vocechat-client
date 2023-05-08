// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
      uid: json['uid'] as int,
      email: json['email'] as String?,
      name: json['name'] as String,
      gender: json['gender'] as int,
      language: json['language'] as String,
      isAdmin: json['is_admin'] as bool,
      isBot: json['is_bot'] as bool?,
      birthday: json['birthday'] as int?,
      avatarUpdatedAt: json['avatar_updated_at'] as int,
      createBy: json['create_by'] as String?,
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'name': instance.name,
      'gender': instance.gender,
      'language': instance.language,
      'is_admin': instance.isAdmin,
      'is_bot': instance.isBot,
      'birthday': instance.birthday,
      'avatar_updated_at': instance.avatarUpdatedAt,
      'create_by': instance.createBy,
    };
