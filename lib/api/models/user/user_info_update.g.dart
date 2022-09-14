// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfoUpdate _$UserInfoUpdateFromJson(Map<String, dynamic> json) =>
    UserInfoUpdate(
      json['uid'] as int,
      json['email'] as String?,
      json['name'] as String?,
      json['gender'] as int?,
      json['language'] as String?,
      json['is_admin'] as bool?,
      json['avatar_updated_at'] as int?,
    );

Map<String, dynamic> _$UserInfoUpdateToJson(UserInfoUpdate instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'name': instance.name,
      'gender': instance.gender,
      'language': instance.language,
      'is_admin': instance.isAdmin,
      'avatar_updated_at': instance.avatarUpdatedAt,
    };
