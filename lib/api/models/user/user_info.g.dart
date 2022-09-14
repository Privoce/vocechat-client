// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
      json['uid'] as int,
      json['email'] as String?,
      json['name'] as String?,
      json['gender'] as int?,
      json['language'] as String?,
      json['is_admin'] as bool?,
      json['avatar_updated_at'] as int?,
      json['create_by'] as String?,
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'name': instance.name,
      'gender': instance.gender,
      'is_admin': instance.isAdmin,
      'create_by': instance.createBy,
      'language': instance.language,
      'avatar_updated_at': instance.avatarUpdatedAt,
    };
